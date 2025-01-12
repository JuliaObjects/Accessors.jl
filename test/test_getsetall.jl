module TestGetSetAll
using Test
using Accessors
using Accessors: test_getsetall_laws, test_modify_law
using StaticNumbers
using StaticArrays

@testset "getall" begin
    obj = (a=1, b=2.0, c='3')
    @test (1,) === @inferred getall(obj, @optic _.a)
    @test (1, 2.0, '3') === @inferred getall(obj, @optic _ |> Properties())
    @test (1, 2.0, '3') === @inferred getall(obj, @optic _ |> Elements())
    @test_throws ErrorException getall('a', Elements())
    @test (2, 3.0, '4') === @inferred getall(obj, @optic _ |> Elements() |> _ + 1)
    @test (1, 2.0) === @inferred getall(obj, @optic _ |> Elements() |> If(x -> x isa Number))
    @test (2.0,) === getall(obj, @optic _ |> Elements() |> If(x -> x isa Number && x >= 2))
    @test_broken (@inferred getall(obj, @optic _ |> Elements() |> If(x -> x isa Number && x >= 2)); true)
    @test_broken (@inferred getall(obj, @optic _ |> Elements() |> If(x -> x isa Number && x >= static(2))); true)

    obj = (a=1, b=((c=3, d=4), (c=5, d=6)))
    @test (3, 5) === @inferred getall(obj, @optic _.b |> Elements() |> _.c)
    @test (3, 4, 5, 6) === @inferred getall(obj, @optic _.b |> Elements() |> Properties())
    @test (9, 12, 15, 18) === @inferred getall(obj, @optic _.b |> Elements() |> Properties() |> Elements() |> _ * 3)

    obj = (a=((c=1, d=2),), b=((c=3, d=4), (c=5, d=6)))
    @test (1, 3, 5) === @inferred getall(obj, @optic _ |> Properties() |> Elements() |> _.c)
    f(obj) = getall(obj, @optic _ |> Properties() |> Elements() |> _[:c])
    @test (1, 3, 5) === @inferred f(obj)
    @test (1, 2, 3, 4, 5, 6) === @inferred getall(obj, @optic _ |> Properties() |> Elements() |> Properties())

    obj = ((a=((c=1, d=2),), b=((c=3, d=4), (c=5, d=6))),)
    @test (1, 2, 3, 4, 5, 6) === @inferred getall(obj, @optic _ |> Properties() |> Properties() |> Properties() |> Properties())
    @test (1, 2, 3, 4, 5, 6) === @inferred getall(obj, @optic _ |> Elements() |> Elements() |> Elements() |> Elements())
    @test (2, 5, 10, 17, 26, 37) === @inferred getall(obj, @optic _ |> Elements() |> Elements() |> Elements() |> Elements() |> _[1]^2 + 1)
    # maximal supported composition length of 10 optics:
    @test (2, 5, 10, 17, 26, 37) === @inferred getall(obj, @optic _ |> _[:] |> Elements() |> Elements() |> _[:] |> Elements() |> Elements() |> _[1]^2 + 1 |> only)

    # trickier types for Elements():
    @test issetequal(["x", "y"], @inferred getall(Set(["x", "y"]), Elements()))
    @test issetequal([1 => "x", 2 => "y"], @inferred getall(Dict(1 => "x", 2 => "y"), Elements()))
    obj = (a=("ab", "c"), b=([1 2; 3 4],), c=(SVector(1.), SVector(2, 3)))
    @test ['b', 'c', 'd'] == @inferred getall(obj, @optic _.a |> Elements() |> Elements() |> _ + 1)
    @test [2, 4, 3, 5] == @inferred getall(obj, @optic _.b |> Elements() |> Elements() |> _ + 1)
    @test (1., 2, 3) === @inferred getall(obj, @optic _.c |> Elements() |> Elements())
    @test (2., 3, 4) === @inferred getall(obj, @optic _.c |> Elements() |> Elements() |> _ + 1)

    # composition order should not matter:
    @test (2., 3, 4) === @inferred getall(obj, (@optic(_ + 1) ∘ Elements() ∘ Elements()) ∘ @optic(_.c))
    @test (2., 3, 4) === @inferred getall(obj, (@optic(_ + 1) ∘ Elements()) ∘ (Elements() ∘ @optic(_.c)))
    @test (2., 3, 4) === @inferred getall(obj, @optic(_ + 1) ∘ (Elements() ∘ Elements() ∘ @optic(_.c)))

    obj = ()
    @test () === @inferred getall(obj, @optic _ |> Elements() |> _ + 1)
    obj = (1,)
    @test (2,) === @inferred getall(obj, @optic _ |> Elements() |> _ + 1)
    obj = Int[]
    @test Int[] == @inferred getall(obj, @optic _ |> Elements() |> _ + 1)
    obj = [1]
    @test [2] == @inferred getall(obj, @optic _ |> Elements() |> _ + 1)

    obj = [1, 2, 3]
    @test [3] == getall(obj, @optic _ |> Elements() |> If(>(2)))
    @test_broken (@inferred getall(obj, @optic _ |> Elements() |> If(>(2))); true)
    obj = ([1, 2], 3:5, (6,))
    @test [1, 2, 3, 4, 5, 6] == @inferred getall(obj, @optic _ |> Elements() |> Elements())
    @test [2, 3, 4, 5, 6, 7] == @inferred getall(obj, @optic _ |> Elements() |> Elements() |> _ + 1)
    obj = [[1, 2], [3]]
    @test [1, 2, 3] == @inferred getall(obj, @optic _ |> Elements() |> Elements())

    obj = ([1, 2], [:a, :b])
    @test [1, 2, :a, :b] == @inferred getall(obj, @optic _ |> Elements() |> Elements())
end

@testset "setall" begin
    for o in [Elements(), Properties()]
        @test (a=2, b=3) === @inferred setall((a=1, b="2"), o, (2, 3))
        @test (a=2, b="3") === @inferred setall((a=1, b="2"), o, (2, "3"))
        @test (a=2, b=3) === @inferred setall((a=1, b="2"), o, [2, 3])
    end
    for o in [Elements(), Properties()]
        @test (2, 3) === @inferred setall((1, "2"), o, (2, 3))
        @test (2, "3") === @inferred setall((1, "2"), o, (2, "3"))
    end
    @test (2, 3) === @inferred setall((1, "2"), Elements(), (2, 3))
    @test (2, "3") === @inferred setall((1, "2"), Elements(), (2, "3"))
    @test (2, 3) === @inferred setall((1, "2"), Elements(), [2, 3])
    @test [2, 3] == @inferred setall([1, "2"], Elements(), (2, 3))
    @test [2, "3"] == @inferred setall([1, "2"], Elements(), (2, "3"))
    @test [2, 3] == @inferred setall([1, "2"], Elements(), [2, 3])
    @test Set([2, 3]) == @inferred setall(Set(["1", "2"]), Elements(), (2, 3))
    @test Dict(1 => 2, 3 => 4) == @inferred setall(Dict(:a => :b, :c => :d), Elements(), [1 => 2, 3 => 4])
    @test_throws ErrorException setall("abc", Elements(), [2, 3])

    @test 2 === @inferred setall(1, If(>(0)), (2,))
    @test 1 === @inferred setall(1, If(<(0)), ())
    @test_throws Exception @inferred setall(1, If(>(0)), ())
    @test_throws Exception @inferred setall(1, If(<(0)), (2,))

    obj = (a=1, b=2.0, c='3')
    @test (a="aa", b=2.0, c='3') === @inferred setall(obj, @optic(_.a), ("aa",))
    @test (a=9, b=19.0, c='4') === @inferred setall(obj, @optic(_ |> Elements() |> _ + 1), (10, 20.0, '5'))
    @test_throws DimensionMismatch setall(obj, @optic(_ |> Elements() |> _ + 1), (10, 20.0))
    @test_throws DimensionMismatch setall(obj, @optic(_ |> Elements() |> _ + 1), (10, 20.0, '5', 10))
    @test (a=9, b=19.0, c='3') === @inferred setall(obj, @optic(_ |> Elements() |> If(x -> x isa Number) |> _ + 1), (10, 20.0))
    @test ((),) === @inferred setall(((),), @optic(_ |> Elements() |> Elements() |> first), ())

    obj = (a=1, b=((c=3, d=4), (c=5, d=6)))
    @test (a=1, b=(:x, :y)) === @inferred setall(obj, @optic(_.b |> Elements()), (:x, :y))
    @test (a=1, b=((c=:x, d=4), (c=:y, d=6))) === @inferred setall(obj, @optic(_.b |> Elements() |> _.c), (:x, :y))
    @test (a=1, b=((c=:x, d="y"), (c=:z, d=10))) === @inferred setall(obj, @optic(_.b |> Elements() |> Properties()), (:x, "y", :z, 10))
    @test (a=1, b=((c=-3., d=-4.), (c=-5., d=-6.))) === @inferred setall(obj, @optic(_.b |> Elements() |> Properties() |> _ * 3), (-9, -12, -15, -18))
    @test (a=1, b=((c=-3., d=-4.), (c=-5., d=-6.))) === @inferred setall(obj, @optic(_.b |> Elements() |> Properties() |> _ * 3), [-9, -12, -15, -18])

    # composition order should not matter:
    @test (a=1, b=((c=-3., d=-4.), (c=-5., d=-6.))) === @inferred setall(obj, (@optic(_ * 3) ∘ Properties() ∘ Elements()) ∘ @optic(_.b), [-9, -12, -15, -18])
    @test (a=1, b=((c=-3., d=-4.), (c=-5., d=-6.))) === @inferred setall(obj, (@optic(_ * 3) ∘ Properties()) ∘ (Elements() ∘ @optic(_.b)), [-9, -12, -15, -18])
    @test (a=1, b=((c=-3., d=-4.), (c=-5., d=-6.))) === @inferred setall(obj, @optic(_ * 3) ∘ (Properties() ∘ Elements() ∘ @optic(_.b)), [-9, -12, -15, -18])

    # SVectors and nested Elements:
    obj = (c=(SVector(1.), SVector(2, 3)),)
    @test setall(obj.c[1], Elements(), (5, 6)) === SVector(5, 6)
    @test setall(obj.c[1], Elements(), (5,)) === SVector(5)
    @test setall(obj.c[1], Elements(), [5, 6]) === SVector(5, 6)
    @test setall(obj.c[1], Elements(), [5]) === SVector(5)
    @testset for (i,o) in (
        (@optic _.c |> Elements() |> Elements()),
        (@optic _.c |> Elements() |> Elements() |> _ + 1),
    ) |> enumerate
        @test (@inferred setall(obj, o, getall(obj, o))) === obj
        @test setall(obj, o, collect(getall(obj, o))) === obj
        @test (@inferred setall(obj, o, Vector{Float64}(collect(getall(obj, o))))) == obj
        @test (@inferred setall(obj, o, SVector(getall(obj, o)))) == obj
    end

    obj = ([1, 2], 3:5, (6,))
    @test obj == setall(obj, @optic(_ |> Elements() |> Elements()), 1:6)
    @test ([2, 3], 4:6, (7,)) == setall(obj, @optic(_ |> Elements() |> Elements() |> _ - 1), 1:6)

    @test obj == @inferred setall(obj, @optic(_ |> Elements() |> Elements()), 1:6)
    @test ([2, 3], 4:6, (7,)) == @inferred setall(obj, @optic(_ |> Elements() |> Elements() |> _ - 1), 1:6)
    @test obj == @inferred setall(obj, @optic(_ |> Elements() |> Elements()), ntuple(identity, 6))
    @test obj == @inferred setall(obj, @optic(_ |> identity |> Elements() |> Elements()), ntuple(identity, 6))
    @test obj[1] == @inferred setall(obj[1], @optic(_ |> Elements() |> _ + 1), (2, 3))
    # impossible to infer:
    @test_broken ([1, 2], [3.0, 4.0, 5.0], ("6",)) == @inferred setall(obj, @optic(_ |> Elements() |> Elements()), (1, 2, 3., 4., 5., "6"))
end

@testset "getall-setall laws" begin
    for (optic, obj, vals1, vals2) in [
            (Elements(), (1, false), (2, 3), (4, 5)),
            (Properties(), (a=1, b=false), (2, 3), (4, 5)),
            (If(x -> x isa Number) ∘ Properties(), (a=1, b="2"), (2,), (4,)),
            (@optic(_.b |> Elements() |> Properties() |> _ * 3), (a=1, b=((c=3, d=4), (c=5, d=6))), 1:4, (-9, -12, -15, -18)),
        ]
        test_getsetall_laws(optic, obj, vals1, vals2)
        test_modify_law(x -> x + 1, optic, obj)
    end
end
        
end
