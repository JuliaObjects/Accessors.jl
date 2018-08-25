module TestSetfield

using Test
using Setfield

@testset "core" begin
    include("test_core.jl")
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

@testset "QuickTypes.jl" begin
    include("test_quicktypes.jl")
end

@testset "Performance" begin
    include("perf.jl")
end
end  # module
