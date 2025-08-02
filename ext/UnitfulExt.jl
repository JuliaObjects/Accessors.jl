module UnitfulExt

import Accessors: set, _shortstring
using Unitful

# ustrip(unit, _) works automatically because Unitful defines inverse() for it
# inverse(ustrip) is impossible, so special set() handling is required
set(obj, ::typeof(ustrip), val) = val * unit(obj)

_shortstring(prev, o::Base.Fix1{typeof(ustrip)}; is_compact) = is_compact ? "$prev [$(o.x)]" : @invoke _shortstring(prev, o::Base.Fix1; is_compact)

end
