module LinearAlgebraExt

import Accessors: set, @set, _shortstring
using LinearAlgebra: norm, normalize, diag, diagind

set(arr, ::typeof(normalize), val) = norm(arr) * val
function set(arr, ::typeof(norm), val)
    omul = iszero(val) ? oneunit(norm(arr)) : norm(arr)
    map(Base.Fix2(*, val / omul), arr)
end

set(A, ::typeof(diag), val) = @set A[diagind(A)] = val

_shortstring(prev, o::typeof(norm); is_compact) = is_compact ? "‖$(prev)‖" : "$o($prev)"

end
