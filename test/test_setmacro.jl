module TestSetMacro

module Clone
using Setfield: setmacro, lensmacro

macro lens(ex)
    lensmacro(identity, ex)
end

macro set(ex)
    setmacro(identity, ex)
end

end#module Clone

using Setfield: Setfield
using Test
using .Clone: Clone

using StaticArrays: @SMatrix
using StaticNumbers

@testset "setmacro, lensmacro isolation" begin

    # test that no symbols like `IndexLens` are needed:
    @test Clone.@lens(_                                   ) isa Setfield.Lens
    @test Clone.@lens(_.a                                 ) isa Setfield.Lens
    @test Clone.@lens(_[1]                                ) isa Setfield.Lens
    @test Clone.@lens(first(_)                            ) isa Setfield.Lens
    @test Clone.@lens(_[end]                              ) isa Setfield.Lens
    @test Clone.@lens(_[static(1)]                           ) isa Setfield.Lens
    @test Clone.@lens(_.a[1][end, end-2].b[static(1), static(1)]) isa Setfield.Lens

    @test Setfield.@lens(_.a) === Clone.@lens(_.a)
    @test Setfield.@lens(_.a.b) === Clone.@lens(_.a.b)
    @test Setfield.@lens(_.a.b[1,2]) === Clone.@lens(_.a.b[1,2])

    o = (a=1, b=2)
    @test Clone.@set(o.a = 2) === Setfield.@set(o.a = 2)
    @test Clone.@set(o.a += 2) === Setfield.@set(o.a += 2)

    m = @SMatrix [0 0; 0 0]
    m2 = Clone.@set m[end-1, end] = 1
    @test m2 === @SMatrix [0 1; 0 0]
    m3 = Clone.@set(first(m) = 1)
    @test m3 === @SMatrix[1 0; 0 0]
end

end#module

