module TestSetMacro

module Clone
    import Accessors: setmacro, opticmacro, modifymacro
    macro optic(ex)
        opticmacro(identity, ex)
    end
    macro set(ex)
        setmacro(identity, ex)
    end
    macro modify(f, ex)
        modifymacro(identity, f, ex)
    end
end#module Clone

using Accessors: Accessors
using Test
using .Clone: Clone

using StaticArrays: @SMatrix
using StaticNumbers

@testset "setmacro, opticmacro isolation" begin

    # test that no symbols like `IndexLens` are needed:
    Clone.@optic(_                                         )
    Clone.@optic(_.a                                       )
    Clone.@optic(_[1]                                      )
    Clone.@optic(first(_)                                  )
    Clone.@optic(_[end]                                    )
    Clone.@optic(_[static(1)]                              )
    Clone.@optic(_.a[1][end, end-2].b[static(1), static(1)])

    @test Accessors.@optic(_.a) === Clone.@optic(_.a)
    @test Accessors.@optic(_.a.b) === Clone.@optic(_.a.b)
    @test Accessors.@optic(_.a.b[1,2]) === Clone.@optic(_.a.b[1,2])

    o = (a=1, b=2)
    @test Clone.@set(o.a = 2) === Accessors.@set(o.a = 2)
    @test Clone.@set(o.a += 2) === Accessors.@set(o.a += 2)

    @test Clone.@modify(x -> x+1, o.a) === Accessors.@modify(x -> x+1, o.a)

    m = @SMatrix [0 0; 0 0]
    m2 = Clone.@set m[end-1, end] = 1
    @test m2 === @SMatrix [0 1; 0 0]
    m3 = Clone.@set(first(m) = 1)
    @test m3 === @SMatrix[1 0; 0 0]
end

end#module
