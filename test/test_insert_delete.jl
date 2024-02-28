module TestInsertDelete
using Test
using StaticArrays
using Accessors
using Accessors: insert
using Accessors: test_insertdelete_laws


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
        @test @inferred(insert(CartesianIndex(1, 2, 3), @optic(_[2]), 4)) == CartesianIndex(1, 4, 2, 3)
        @test insert((1,2), last, 3) == (1, 2, 3)
        @inferred(insert((1,2), last, 3))
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

    @testset "friendly error" begin
        res = @test_throws ArgumentError Accessors.insertmacro(identity, :(obj.prop == val))
        @test occursin("obj.prop == val", res.value.msg)
    end
end

@testset "test delete" begin
    @testset "function" begin
        @test @inferred(delete((a=1,b=2), @optic _[()])) === (a=1, b=2)
        @test @inferred(delete( (a=1, b=2, c=3), @optic(_.a) )) == (b=2, c=3)
        @test @inferred(delete( (a=1, b=2, c=3), @optic(_.xxxx) )) === (a=1, b=2, c=3)
        @test @inferred(delete( (a=1, b=(c=2, d=3)), @optic(_.b.c) )) == (a=1, b=(d=3,))
        @test @inferred(delete((1, 2), @optic(_[1]))) == (2,)
        @test delete( (a=1, b=2, c=3), @optic(_[:a]) ) == (b=2, c=3)
        @test delete( (1,2,3), last ) == (1, 2)
        @inferred(delete( (1,2,3), last ))
        f(t) = delete(t, @optic(_[1:2]))
        @test @inferred(f((1,2,3))) == (3,)
        @test @inferred(delete( (a=1, b=2, c=3), first ))== (b=2, c=3)
        @test @inferred(delete( SVector(1,2,3), last )) === SVector(1, 2)
        @test @inferred(delete( [1, 2, 3], @optic(first(_, 2)))) == [3]
        @test @inferred(delete( [1, 2, 3], @optic(last(_, 2)))) == [1]

        @test @inferred(delete(CartesianIndex(1, 2, 3), @optic(_[1]))) == CartesianIndex(2, 3)

        @test @inferred(delete(1:4, last)) === 1:3
        @test @inferred(delete(1:4, (@optic first(_, 2)))) === 3:4

        l = @optic first(_, 2)
        @test l((1,2,3)) == [1,2]
        @test delete((1,2,3), l) === (3,)

        @test delete("абв", first) == "бв"
        @test delete("абв", last) == "аб"
        @test delete("абв", @optic(first(_, 2))) == "в"
        @test delete("абв", @optic(last(_, 1))) == "аб"

        let A = [1,2,3]
            @test delete(A, @optic(_[2])) == [1, 3]
            @test delete(A, @optic(_[1:2])) == [3]
            @test_throws Exception delete(A, @optic(_[2, 2]))
            @test_throws BoundsError delete(A, @optic(_[10]))
            @test delete(A, @optic(_[end])) == [1, 2]
            @test delete(A, @optic(_[[end-2, end]])) == [2]
            @test A == [1, 2, 3]  # not changed

            @test_throws ErrorException delete(A, @optic _ |> Elements() |> If(isodd))
            @test delete(A, @optic filter(isodd, _)) == [2]
        end
        let A = Dict("a" => 1, "b" => 2, "c" => 3)
            @test delete(A, @optic(_["a"])) == Dict("b" => 2, "c" => 3)
            @test delete(A, @optic(_["xxxx"])) == A  # follows Base.delete! behavior
            @test A == Dict("a" => 1, "b" => 2, "c" => 3)  # not changed
        end
        @test delete( (a=1, b=(2, 3, 4)), @optic(first(_.b)) ) == (a=1, b=(3, 4))
        @test delete( "path/to/file", @optic(basename(_)) ) == "path/to"
        @test delete( "path/to/file", @optic(dirname(_)) ) == "file"
    end

    @testset "macro" begin
        x = (a=1, b=2, c=3)
        @test @delete(x.c) === (a=1, b=2)
        @test @delete(x[(:a, :c)]) === (b=2,)
        @test @delete(x[(2, 3)]) === (a=1,)
        x = (a=1, b=(c=2, d=3))
        @test @delete(x.b.c) === (a=1, b=(d=3,))
        @test @delete(x.b[(:c,)]) === (a=1, b=(d=3,))
        x = [1, 2, 3]
        @test @delete(x[2]) == [1, 3]
        @test_throws BoundsError @delete(x[10])

        A = [(x=1, y=2), (x=3, y=4)]
        @test @delete(Elements()(A).x) == [(y=2,), (y=4,)]
    end
end

@testset "insert-delete laws" begin
    test_insertdelete_laws((@o _.c), (a=1, b=2), "3")
    @testset for o in ((@o _[2]), (@o _[3]), first, last), obj in ((1, 2), [1, 2])
        test_insertdelete_laws(o, obj, 3)
    end
    @testset for o in ((@o _.a[2]), (@o _.a[3]), (@o first(_.a)), (@o last(_.a)))
        test_insertdelete_laws(o, (a=(1, 2),), "3")
    end
    test_insertdelete_laws((@o first(_, 2)), [1, 2, 3], [4, 5])
end

end
