module TestOptics

using Accessors
using Accessors: mapproperties
using Test
import ConstructionBase

@testset "mapproperties" begin
    res = @inferred mapproperties(x->2x, (a=1, b=2))
    @test res === (a=2, b=4)
    @test NamedTuple() === @inferred mapproperties(cos, NamedTuple())

    res = @inferred mapproperties(x->2x, (1, 2))
    @test res === (2, 4)
    @test () === @inferred mapproperties(cos, ())

    struct S{A,B}
        a::A
        b::B
    end
    res = @inferred mapproperties(x->2x, S(1, 2.0))
    @test res === S(2, 4.0)

    # overloading
    struct AB
        a::Int
        b::Int
        _checksum::UInt
        AB(a,b) = new(a,b,hash(a,hash(b)))
    end

    ConstructionBase.getproperties(o::AB) = (a=o.a, b=o.b)
    ConstructionBase.setproperties(o::AB, patch::NamedTuple) = AB(patch.a, patch.b)
    ab = AB(1,2)
    ab2 = @inferred mapproperties(x -> 2x, ab)
    @test ab2 === AB(2,4)
end

@testset "Properties" begin
    pt = (x=1, y=2, z=3)
    @test (x=0, y=1, z=2) === @set pt |> Properties() -= 1
    @inferred modify(x->x-1, pt, Properties())

    pt = (1, 2, 3)
    @test (0, 1, 2) === @set pt |> Properties() -= 1
    @inferred modify(x->x-1, pt, Properties())

    # custom struct
    struct Point{X,Y,Z}
        x::X; y::Y; z::Z
    end
    pt = Point(1f0, 2e0, 3)
    pt2 = @inferred modify(x->2x, pt, Properties())
    @test pt2 === Point(2f0, 4e0, 6)
end

@testset "Elements" begin
    @test [0,0,0] == @set 1:3 |> Elements() = 0

    arr = 1:3
    @test 2:4 == (@set arr |> Elements() += 1)
    @test map(cos, arr) == modify(cos, arr, Elements())

    @test modify(cos, (), Elements()) === ()

    @inferred modify(cos, arr, Elements())
    @inferred modify(cos, (), Elements())

    @test Set([2,3,4]) == @inferred modify(x->x+1, Set([1,2,3]), Elements())
    # not @inferred because Tuple(::Pair) is type unstable:
    @test Dict(1 => 2, 2 => 3, 3 => 4) == modify(x->x+1, Dict(1 => 1, 2 => 2, 3 => 3), last ∘ Elements())
end

@testset "Recursive" begin
    obj = (a=1, b=(1,2), c=(A=1, B=(1,2,3), D=4))
    rp = Recursive(x -> !(x isa Tuple), Properties())
    @test modify(collect, obj, rp) == (a = 1, b = [1, 2], c = (A = 1, B = [1, 2, 3], D = 4))

    arr = [1,2,[3,4], [5, 6:7,8, 9,]]
    oc = Recursive(x -> x isa AbstractArray, Elements())
    expected = [0,1,[2,3], [4, 5:6,7, 8,]]
    @test modify(x-> x - 1, arr, oc) == expected
end

@testset "If" begin
    @test 10 === @set(1 |> If(>=(0)) = 10)
    @test -1 === @set(-1 |> If(>=(0)) = 10)
    @inferred set(1, If(iseven), 2)
    @inferred modify(x -> 0, 1, If(iseven))

    arr = 1:6
    @test [1, 0, 3, 0, 5, 0] == @set(arr |> Elements() |> If(iseven) = 0)
    @inferred modify(x -> 0, arr, @optic _ |> Elements() |> If(iseven))
end

@testset "constructors" begin
    @test IndexLens(1, 2, 3) === IndexLens((1, 2, 3))
    @test PropertyLens(:a) === PropertyLens{:a}()

    f = PropertyLens(:a)
    @test constructorof(typeof(f))(Accessors.getfields(f)...) === f
    f = IndexLens(1, 2, 3)
    @test constructorof(typeof(f))(Accessors.getfields(f)...) === f
end

@testset "broadcasting" begin
    @test PropertyLens(:a).([(a=1,), (a=2, b=3)]) == [1, 2]
    @test IndexLens(2).([(1,2,3), (4,5)]) == [2, 5]
    @test Accessors.DynamicIndexLens(lastindex).([(1,2,3), (4,5)]) == [3, 5]
end

@testset "shortcuts" begin
    @test (@o _.a[2]) === (@optic _.a[2])
    @test (@optic _[∗]) === Elements()
    @test (@optic _.a[∗][2]) === (@optic _.a |> Elements() |> _[2])
    @test (@optic _.a[∗ₚ][2]) === (@optic _.a |> Properties() |> _[2])
    # user-defined symbols have priority, same as elsewhere in Julia
    let ∗ = 3
        o = @optic _[∗]
        @test o([1,2,42]) == 42
    end
end

end#module
