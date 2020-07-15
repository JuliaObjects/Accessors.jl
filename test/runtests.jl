module TestSetfield

import PerformanceTestTools
import Setfield
using Documenter: doctest

PerformanceTestTools.@include("perf.jl")
include("test_examples.jl")
include("test_staticarrays.jl")
include("test_quicktypes.jl")
include("test_setmacro.jl")
include("test_setindex.jl")
include("test_core.jl")
include("test_functionlenses.jl")


# TODO doctest(Setfield)

end  # module
