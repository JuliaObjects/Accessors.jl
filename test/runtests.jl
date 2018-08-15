module TestSetfield

@static if VERSION < v"0.7-"
    using Base.Test
else
    using Test
end

macro test_deprecated07(ex)
    if VERSION < v"0.7-"
        return esc(ex)
    else
        return esc(:(Test.@test_deprecated $ex))
    end
end

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

end  # module
