module TestInsert
using Test
using StaticArrays
using Accessors
using Accessors: insert

@testset "test insert" begin
    @testset "function" begin
        @test @inferred(insert( (b=2, c=3), @optic(_.a), 1 )) == (b=2, c=3, a=1)
        @test insert( (b=2, c=3), @optic(_[:a]), 1 ) == (b=2, c=3, a=1)
        let A = [1, 2]
            @test insert(A, @optic(_[2]), 3) == [1, 3, 2]
            @test_throws BoundsError insert(A, @optic(_[4]), 3)
            @test_throws Exception insert(A, @optic(_[1, 3]), 3)
            @test insert(A, first, 3) == [3, 1, 2]
            @test insert(A, @optic(first(_, 2)), [3, 4]) == [3, 4, 1, 2]
            @test insert(A, @optic(last(_, 2)), [3, 4]) == [1, 2, 3, 4]
            @test A == [1, 2]  # not changed
        end
        @test insert((1,2), last, 3) == (1, 2, 3)
        Base.thisminor(VERSION) >= v"1.6" && @inferred(insert((1,2), last, 3))
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
        @test @inferred(insert((1, 2), @optic(_[1]), 3)) == (3, 1, 2)
    end

    @testset "macro" begin
        x = (b=2, c=3)
        @test @insert(x.a = 1) === (b=2, c=3, a=1)
        @test @insert(x[(:a, :x)] = (1, :xyz)) === (b=2, c=3, a=1, x=:xyz)
        @test @insert(x[(:a, :x)] = (x=:xyz, a=1)) === (b=2, c=3, a=1, x=:xyz)
        x = [1, 2]
        @test @insert(x[3] = 3) == [1, 2, 3]
        x = (a=(b=(1, 2),), c=1)
        @test @insert(x.a.b[1] = 0) == (a=(b=(0, 1, 2),), c=1)

        # inferred & constant-propagated:
        function doit(nt)
            nt = @delete nt[1]
            nt = @insert nt[:a] =1
            nt = @delete nt[(:a, :c)]
            nt = @insert nt[(:x, :y)] = ("def", :abc)
            return nt
        end
        @test @inferred(doit((a='3', b=2, c="1"))) === (b=2, x="def", y=:abc)

        x = (1, 2)
        @test [@insert(x[3] = 3)] == [(1, 2, 3)]

        A = [(x=1, y=2), (x=3, y=4)]
        @test @insert(Elements()(A).z = 5) == [(x=1, y=2, z=5), (x=3, y=4, z=5)]
    end
end

@testset "friendly error" begin
    res = @test_throws ArgumentError Accessors.insertmacro(identity, :(obj.prop == val))
    @test occursin("obj.prop == val", res.value.msg)
end

end
