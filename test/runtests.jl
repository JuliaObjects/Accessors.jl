module TestSetfield

using Setfield
using Base.Test

if Pkg.installed("QuickTypes") != nothing
    @testset "QuickTypes" begin include("test_quicktypes.jl") end
end

include("test_core.jl")
include("test_macrotools.jl")
include("test_settable.jl")

if Pkg.installed("StaticArrays") != nothing
    include("test_staticarrays.jl")
    include("spaceship.jl")
end

try
    using Reconstructables
    include("test_kwonly.jl")
catch e
    @assert e isa ArgumentError
    @assert contains(e.msg, "Reconstructables")
end

end  # module
