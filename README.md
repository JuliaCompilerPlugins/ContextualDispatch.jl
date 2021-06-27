# ContextualDispatch.jl

A bare-bones implementation of contextual dispatch.

```julia
module Simple

using ContextualDispatch
import ContextualDispatch: Context, overdub

foo(x, y) = begin
    q = 10 + 15
    x + y + 10 + q
end

mutable struct SimpleCtx <: Context 
    call_num::Int
    SimpleCtx() = new(0)
end
function overdub(ctx::SimpleCtx, ::typeof(+), args...)
    ctx.call_num += 1
    ret = *(args...)
    ret
end

ContextualDispatch.@load_call()

r, c = call(SimpleCtx(), foo, 5, 10)
display((r, c))

end # module
```
