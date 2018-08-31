module TestStaticArrays
using Test
using Setfield
using StaticArrays

@testset "StaticArrays" begin
    obj = StaticArrays.@SMatrix [1 2; 3 4]
    l = @lens _[2,1]
    @test get(obj, l) == 3
    @test set(obj, l, 5) == StaticArrays.@SMatrix [1 2; 5 4]
    @test setindex(obj, 5, 2, 1) == StaticArrays.@SMatrix [1 2; 5 4]
    
    v = @SVector [1,2,3]
    @test (@set v[1] = 10) === @SVector [10,2,3]
    @test_broken (@set v[1] = π) === @SVector [π,2,3]
end
end
