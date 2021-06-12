module ContextualDispatch

using MacroTools: @capture, postwalk, unblock, rmlines
using Mixtape
import Mixtape: allow, 
                transform,
                optimize!,
                CompilationContext, 
                @load_abi,
                jit
using CodeInfoTools

# Controls when the transform on lowered code applies. 
# I don't want to apply the recursive transform in type inference.
# So when stacklevel > 1, don't apply.
# I'll just dispatch to `Mixtape.call` at runtime.
mutable struct Mix{T} <: CompilationContext
    stacklevel::Int
    ctx::T
end
Mix(ctx::T) where T = Mix(1, ctx)
Mix{T}() where T = Mix(1, T())

# Basically == a Cassette context.
abstract type Context end

# Our version of overdub.
overdub(::Context, f, args...) = f(args...)
allow(::Mix, m::Module, args...) = true

# The transform inserts state, then wraps calls in (overdub).
# Then, anytime there's a return value --
# create a tuple of (ret, state)
# and returns that. 
# Consider monadic lifting f: R -> R => trans => R -> (R, state).
swap(r, e) = e
function swap(r, e::Expr)
    if e.head == :(=)
        return Expr(:(=), e.args[1], swap(r, e.args[2]))
    elseif e.head == :call
        return Expr(:call, overdub, r, e.args[1:end]...)
    end
    return e
end

prehook!(ctx::Context, b, sig) = CodeInfoTools.identity(b)
posthook!(ctx::Context, b, sig) = CodeInfoTools.identity(b)

# Potentially can be sped up. Profile.
function transform(mix::Mix{T}, src, sig) where T
    mix.stacklevel == 1 || return src
    prebuilder = CodeInfoTools.Builder(src)
    prehook!(mix.ctx, prebuilder, sig)
    new = CodeInfoTools.finish(prebuilder)
    b = CodeInfoTools.Builder(new)
    q = push!(b, Expr(:call, T))
    rets = Any[]
    for (v, st) in b
        b[v] = swap(q, st)
        st isa Core.ReturnNode && push!(rets, v => st)
    end
    for (n, ret) in rets
        v = insert!(b, n, Expr(:call, Base.tuple, ret.val, q))
        b[n] = Core.ReturnNode(v)
    end
    new = CodeInfoTools.finish(b)
    postbuilder = CodeInfoTools.Builder(new)
    posthook!(mix.ctx, postbuilder, sig)
    new = CodeInfoTools.finish(postbuilder)
    mix.stacklevel += 1
    return new
end

macro jarrett()
    expr = quote
        using Mixtape
        ContextualDispatch.@load_abi()
        call(ctx::T, fn, args...) where T <: Context = call(fn, args...; ctx = Mix(ctx))
    end
    esc(expr)
end

export overdub, Context, @jarrett, 
       Mix, jit, prehook!, posthook!

end # module
