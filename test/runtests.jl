module TestAccessors
import PerformanceTestTools
import Accessors
PerformanceTestTools.@include("perf.jl")

include("test_examples.jl")
include("test_core.jl")
include("test_optics.jl")
include("test_delete.jl")
include("test_insert.jl")
include("test_staticarrays.jl")
include("test_quicktypes.jl")
include("test_setmacro.jl")
include("test_setindex.jl")
include("test_functionlenses.jl")
include("test_mapview.jl")

using Documenter: doctest
if Base.thisminor(VERSION) == v"1.6"
    # ⨟ needs to be defined
    doctest(Accessors)
else
    @info "Skipping doctests, on VERSION = $VERSION"
end


end  # module
