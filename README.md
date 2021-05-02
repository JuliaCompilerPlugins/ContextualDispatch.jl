# ContextualDispatch.jl

A bare-bones implementation of contextual dispatch.

```julia
module Simple

using ContextualDispatch
import ContextualDispatch: Context, overdub

foo(x, y) = x + y

struct SimpleCtx <: Context end
function overdub(ctx::SimpleCtx, ::typeof(+), args...)
    ret = *(args...)
    ret
end

ContextualDispatch.@jarrett()

r, c = call(SimpleCtx(), foo, 5, 10)
display((r, c))

end # module
```

> For historical reasons, using a completely different compilation pipeline (which may as well be inter-planetary for all we care), is called "doing a jarrett".
