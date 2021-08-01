module TestAccessors
import PerformanceTestTools
import Accessors

include("test_core.jl")
include("test_optics.jl")
include("test_examples.jl")
include("test_staticarrays.jl")
include("test_quicktypes.jl")
include("test_setmacro.jl")
include("test_setindex.jl")
include("test_functionlenses.jl")

using Documenter: doctest
if VERSION == v"1.6"
    # ⨟ needs to be defined
    doctest(Accessors)
else
    @info "Skipping doctests, on VERSION = $VERSION"
end
PerformanceTestTools.@include("perf.jl")


end  # module
