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

# inference

macro setfield156(expr)
    # Example of macro that caused inference issues,
    # see https://github.com/jw3126/Setfield.jl/pull/156
    quote
        function f($(esc(:x)))
            $(Accessors.setmacro(identity, expr, overwrite=true))
            $(Accessors.setmacro(identity, expr, overwrite=true))
            $(Accessors.setmacro(identity, expr, overwrite=true))
            $(Accessors.setmacro(identity, expr, overwrite=true))
            $(Accessors.setmacro(identity, expr, overwrite=true))
            return $(esc(:x))
        end
    end
end

function test_all_inferrable(f, argtypes)
    # hacky, maybe JETTest can help?
    # * JETTest.@test_nodispatch does not detect the problem
    typed = first(code_typed(f, argtypes))
    code = typed.first
    @test all(T -> !(T isa UnionAll || T === Any), code.slottypes)
end

@testset "setmacro multiple usage" begin
    let f = @setfield156(x[end] = 1)
        test_all_inferrable(f, (Vector{Float64}, ))
    end
end

@testset "friendly error" begin
    res = @test_throws ArgumentError Accessors.setmacro(identity, :(obj.prop == val))
    @test occursin("obj.prop == val", res.value.msg)
end

end#module
