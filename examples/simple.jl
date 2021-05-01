module Simple

using ContextualDispatch
import ContextualDispatch: Context, overdub

foo(x, y) = x + y

struct SimpleCtx <: Context end
function overdub(ctx::SimpleCtx, ::typeof(+), args...)
    ret = *(args...)
    ret
end

ContextualDispatch.@load()

r, c = call(SimpleCtx(), foo, 5, 10)
display((r, c))

end # module
