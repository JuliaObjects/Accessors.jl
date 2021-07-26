module TestStaticArrays
using Test
using Accessors
using StaticArrays
using StaticNumbers

@testset "StaticArrays" begin
    obj = StaticArrays.@SMatrix [1 2; 3 4]
    @testset for l in [
            (@optic _[2,1]),
        ]
        @test l(obj) === 3
        @test set(obj, l, 5)         === StaticArrays.@SMatrix [1 2; 5 4]
        @test setindex(obj, 5, 2, 1) === StaticArrays.@SMatrix [1 2; 5 4]
    end

    v = @SVector [1,2,3]
    @test (@set v[1] = 10) === @SVector [10,2,3]
    @test_broken (@set v[1] = π) === @SVector [π,2,3]

    @testset "Multi-dynamic indexing" begin
        two = 2
        plusone(x) = x + 1
        l1 = @optic _.a[2, 1].b
        l2 = @optic _.a[plusone(end) - two, end÷2].b
        m_orig = @SMatrix [
            (a=1, b=10) (a=2, b=20)
            (a=3, b=30) (a=4, b=40)
            (a=5, b=50) (a=6, b=60)
        ]
        m_mod = @SMatrix [
            (a=1, b=10) (a=2, b=20)
            (a=3, b=3000) (a=4, b=40)
            (a=5, b=50) (a=6, b=60)
        ]
        obj = (a=m_orig, b=4)
        @test l1(obj) === l2(obj) === 30
        @test set(obj, l1, 3000) === set(obj, l2, 3000) === (a=m_mod, b=4)
    end

    v = @set StaticArrays.normalize(@SVector [10, 0,0]) = @SVector[0,1,0]
    @test v ≈ @SVector[0,10,0]
    @test @set(StaticArrays.norm([1,0]) = 20) ≈ [20, 0]
end
end
