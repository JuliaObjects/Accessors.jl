module UnitfulExt

import Accessors: set
using Unitful

# ustrip(unit, _) works automatically because Unitful defines inverse() for it
# inverse(ustrip) is impossible, so special set() handling is required
set(obj, ::typeof(ustrip), val) = val * unit(obj)

end
