module TestInsert
using Test
using StaticArrays
using Accessors
using Accessors: insert

@testset "test insert" begin
    @testset "function" begin
        @test @inferred(insert( (b=2, c=3), @optic(_.a), 1 )) == (b=2, c=3, a=1)
        let A = [1, 2]
            @test insert(A, @optic(_[2]), 3) == [1, 3, 2]
            @test_throws BoundsError insert(A, @optic(_[4]), 3)
            @test_throws Exception insert(A, @optic(_[1, 3]), 3)
            @test insert(A, first, 3) == [3, 1, 2]
            @test A == [1, 2]  # not changed
        end
        @test insert((1,2), last, 3) == (1, 2, 3)
        Base.thisminor(VERSION) == v"1.6" && @inferred(insert((1,2), last, 3))
        @test @inferred(insert(SVector(1,2), @optic(_[1]), 3)) == SVector(3, 1, 2)
        @test @inferred(insert(SVector(1,2), last, 3)) == SVector(1, 2, 3)
        let D = Dict(:a => 1)
            @test insert(D, @optic(_[:b]), 2) == Dict(:a => 1, :b => 2)
            @test D == Dict(:a => 1)  # not changed
        end
        @test insert((a=1, b=(2, 3)), @optic(_.b[2]), "xxx") === (a=1, b=(2, "xxx", 3))
        @test_broken begin
            @inferred insert((a=1, b=(2, 3)), @optic(_.b[2]), "xxx")
            true
        end
    end

    @testset "macro" begin
        x = (b=2, c=3)
        @test @insert(x.a = 1) == (b=2, c=3, a=1)
        x = [1, 2]
        @test @insert(x[3] = 3) == [1, 2, 3]
        x = (a=(b=(1, 2),), c=1)
        @test @insert(x.a.b[1] = 0) == (a=(b=(0, 1, 2),), c=1)
    end
end

end
