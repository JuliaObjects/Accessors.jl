module TestAccessors
import PerformanceTestTools
import Accessors
import Aqua
Aqua.test_all(Accessors)
PerformanceTestTools.@include("perf.jl")

include("test_examples.jl")
include("test_core.jl")
include("test_optics.jl")
include("test_insert_delete.jl")
include("test_extensions.jl")
include("test_quicktypes.jl")
include("test_setmacro.jl")
include("test_setindex.jl")
include("test_functionlenses.jl")
include("test_getsetall.jl")

end  # module
