module Simple

using ContextualDispatch
import ContextualDispatch: Context, overdub

foo(x, y) = x + y

struct SimpleCtx <: Context end
function overdub(ctx::SimpleCtx, ::typeof(+), args...)
    ret = *(args...)
    ret
end

# In reference to:
# https://github.com/google/jax/issues/3359#issuecomment-644541370
ContextualDispatch.@jarrett()

r, c = call(SimpleCtx(), foo, 5, 10)
display((r, c))

end # module
