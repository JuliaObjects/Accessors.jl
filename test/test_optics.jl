module TestOptics

using Accessors
using Accessors: mapproperties
using Test
import ConstructionBase

@testset "mapproperties" begin
    res = @inferred mapproperties(x->2x, (a=1, b=2))
    @test res === (a=2, b=4)
    @test NamedTuple() === @inferred mapproperties(cos, NamedTuple())
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

@testset "Decomposition" begin 
    @test Accessors.decompose(@optic _.a.b.c) == ((@optic _.c), (@optic _.b), (@optic _.a))
end

@testset "Propname" begin 
    @test Accessors.propname(@optic _.a) == :a
end

@testset "Normalisation" begin 
    @test Accessors.normalise((@optic _.c) ∘ (@optic _.a.b)).inner == @optic _.a
    @test Accessors.normalise((@optic _.c) ∘ (@optic _.a.b)).outer.inner == @optic _.b
    @test Accessors.normalise((@optic _.c) ∘ (@optic _.a.b)).outer.outer == @optic _.c
end

end#module
