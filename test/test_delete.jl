module TestDelete
using Test
using Accessors
using StaticArrays

@testset "test delete" begin
    @testset "function" begin
        @test @inferred(delete( (a=1, b=2, c=3), @optic(_.a) )) == (b=2, c=3)
        @test @inferred(delete( (a=1, b=2, c=3), @optic(_.xxxx) )) === (a=1, b=2, c=3)
        @test @inferred(delete( (a=1, b=(c=2, d=3)), @optic(_.b.c) )) == (a=1, b=(d=3,))
        @test @inferred(delete((1, 2), @optic(_[1]))) == (2,)
        @test delete( (a=1, b=2, c=3), @optic(_[:a]) ) == (b=2, c=3)
        @test delete( (1,2,3), last ) == (1, 2)
        VERSION >= v"1.6" && @inferred(delete( (1,2,3), last ))
        f(t) = delete(t, @optic(_[1:2]))
        @test @inferred(f((1,2,3))) == (3,)
        @test @inferred(delete( (a=1, b=2, c=3), first ))== (b=2, c=3)
        @test @inferred(delete( SVector(1,2,3), last )) === SVector(1, 2)
        @test @inferred(delete( [1, 2, 3], @optic(first(_, 2)))) == [3]
        @test @inferred(delete( [1, 2, 3], @optic(last(_, 2)))) == [1]

        l = @optic first(_, 2)
        VERSION >= v"1.6" && @test l((1,2,3)) == [1,2]
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

end
