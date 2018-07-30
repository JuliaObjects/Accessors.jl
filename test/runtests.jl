module TestSetfield

using Test
using Setfield
const P = Setfield

@testset "core" begin
    include("test_core.jl")
end

@testset "macrotools" begin
    include("test_macrotools.jl")
end
@testset "settable" begin
    include("test_settable.jl")
end

@testset "StaticArrays.jl" begin
    include("test_staticarrays.jl")
end

@testset "Kwonly.jl" begin
    include("test_kwonly.jl")
end

@static if VERSION < v"0.7-"
@testset "QuickTypes.jl" begin
    include("test_quicktypes.jl")
end
end

end  # module
