module TestSetfield

import PerformanceTestTools

include("test_setindex.jl")
include("test_examples.jl")
include("test_setmacro.jl")
include("test_core.jl")
include("test_functionlenses.jl")
include("test_settable.jl")
include("test_staticarrays.jl")
include("test_kwonly.jl")
include("test_quicktypes.jl")
PerformanceTestTools.@include("perf.jl")
end  # module
