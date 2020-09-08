module TestQuicktypes
using Test

import Base: ==
import MacroTools

using QuickTypes
using Accessors
import ConstructionBase

# this is a limitation in `MacroTools.splitarg`. If it is fixed
# this test can be removed and our custom splitarg removed.
try
    MacroTools.splitarg(:(x=$nothing))
    println("MacroTools.splitarg can now handle literal nothing in AST.
            Revisit splitarg_no_default workaround")
catch e
    @assert e isa AssertionError
end

# Examples are taken from https://github.com/cstjean/QuickTypes.jl
# Strings are replaced with symbols so that `===` and `==` works
# nicely.

@qstruct Wall(width, height)

@testset "Wall" begin
    x0 = Wall(400, 600)
    x1 = @set x0.width = 300
    @test x1 === Wall(300, 600)
end

abstract type Vehicle end

@qstruct Car{T<:Number, U}(size::T, nwheels::Int=4; manufacturer::U=nothing,
                           brand::String="off-brand") <: Vehicle

@testset "Car" begin
    c = Car(10; manufacturer=("Danone", "Hershey"))
    @test c isa Car
    @test Car <: Vehicle
    c2 = @set c.size = 10
    @test c2.size === 10
    c3 = @set c.manufacturer = 100
    @test c3 === Car(10;manufacturer =100)
end

@qstruct Empty()
@qstruct Cat(name, age::Int, nlegs=4; species=:Siamese)

@testset "Cat" begin
    x0 = Cat(:Tama, 1)


    x1 = @set x0.nlegs = 8
    @test x1 === Cat(:Tama, 1, 8)

    x2 = @set x0.species = :Singapura
    @test x2 === Cat(:Tama, 1, species=:Singapura)
end


@qstruct Pack{T, N}(animals::NTuple{N, T})

@testset "Pack" begin
    x = Pack((Cat(:Tama, 1), Cat(:Pochi, 2)))

    x = @set x.animals[2].nlegs = 5
    @test x.animals == (Cat(:Tama, 1), Cat(:Pochi, 2, 5))
end


abstract type Tree end
@qstruct Maple(qty_syrup::Float64) <: Tree

@testset "Maple" begin
    x0 = Maple(1)
    x1 = @set x0.qty_syrup = 2
    @test x1 === Maple(2)
end


@qmutable Window(height::Float64, width::Float64)
==(x::Window, y::Window) = x.height == y.height && x.width == y.width

@testset "Window" begin
    x0 = Window(1, 2)

    x1 = @set x0.width = 3.0
    @test isequal(x1, Window(1, 3))
    @test x1 == Window(1, 3)
    x2 = @set x0.width = 3
    @test x1 == x2
    @test !(x1 === x2)
end


@qstruct Human(; name=:Alice, height::Float64=170) do
    @assert height > 0    # arbitrary code, executed in the constructor
end

@testset "Human" begin
    x0 = Human()

    x1 = @set x0.name = :Bob
    @test x1 === Human(name=:Bob)

    @test_throws AssertionError @set x0.height = -10
end


@qstruct Group{x}(members::x; _concise_show=true)

@testset "Group" begin
    x = Group((0, 1))
    x = @set x.members[2] = 111
    @test x.members == (0, 111)
end

@qstruct_fp Plane1(nwheels, weight::Number; brand=:zoomba)

@testset "Plane1" begin
    x0 = Plane1(3, 100)
    x1 = @set x0.nwheels = 5
    @test x1 == Plane1(5, 100)
    @test (@set x0.brand = 31).brand === 31
end

# Another way to "support" QuickTypes with type parameters is to use
# QuickTypes.construct.
@qstruct_fp Plane2(nwheels, weight::Number; brand=:zoomba)
ConstructionBase.constructorof(::Type{<: Plane2}) =
    (args...) -> QuickTypes.construct(Plane2, args...)

@testset "Plane2" begin
    x0 = Plane2(3, 100)

    x1 = @set x0.brand = 31
    @test typeof(x1) != typeof(x0)
    @test x1 == Plane2(3, 100, brand=31)
end

end  # module
