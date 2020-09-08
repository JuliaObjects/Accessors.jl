module TestSetMacro

module Clone
    import Accessors: setmacro, lensmacro
    macro lens(ex)
        lensmacro(identity, ex)
    end
    macro set(ex)
        setmacro(identity, ex)
    end
end#module Clone

using Accessors: Accessors
using Test
using .Clone: Clone

using StaticArrays: @SMatrix
using StaticNumbers

@testset "setmacro, lensmacro isolation" begin

    # test that no symbols like `IndexLens` are needed:
    Clone.@lens(_                                         )
    Clone.@lens(_.a                                       )
    Clone.@lens(_[1]                                      )
    Clone.@lens(first(_)                                  )
    Clone.@lens(_[end]                                    )
    Clone.@lens(_[static(1)]                              )
    Clone.@lens(_.a[1][end, end-2].b[static(1), static(1)])

    @test Accessors.@lens(_.a) === Clone.@lens(_.a)
    @test Accessors.@lens(_.a.b) === Clone.@lens(_.a.b)
    @test Accessors.@lens(_.a.b[1,2]) === Clone.@lens(_.a.b[1,2])

    o = (a=1, b=2)
    @test Clone.@set(o.a = 2) === Accessors.@set(o.a = 2)
    @test Clone.@set(o.a += 2) === Accessors.@set(o.a += 2)

    m = @SMatrix [0 0; 0 0]
    m2 = Clone.@set m[end-1, end] = 1
    @test m2 === @SMatrix [0 1; 0 0]
    m3 = Clone.@set(first(m) = 1)
    @test m3 === @SMatrix[1 0; 0 0]
end

end#module
