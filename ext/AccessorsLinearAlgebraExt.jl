module AccessorsLinearAlgebraExt

import Accessors: set, @set
using LinearAlgebra: norm, normalize, diag, diagind

set(arr, ::typeof(normalize), val) = norm(arr) * val
set(arr, ::typeof(norm), val)      = map(Base.Fix2(*, val / norm(arr)), arr) # should we check val is positive?

set(A, ::typeof(diag), val) = @set A[diagind(A)] = val

end
