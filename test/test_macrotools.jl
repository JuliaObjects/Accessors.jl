using MacroTools
using Setfield: splittypedef, combinetypedef

@testset "combinetypedef, splittypedef" begin
    ex = :(struct S end)
    @test ex |> splittypedef |> combinetypedef |> Base.remove_linenums! == 
        :(struct S <: Any end)
    
    @test splittypedef(ex) == Dict(
        :constructors => Any[],
        :mutable => false,
        :params => Any[],
        :name => :S,
        :fields => Any[],
        :supertype => :Any)

    ex = :(mutable struct T end)
    @test splittypedef(ex)[:mutable] === true
    @test ex |> splittypedef |> combinetypedef |> Base.remove_linenums! == 
        :(mutable struct T <: Any end)

    ex = :(struct S{A,B} <: AbstractS{B}
                               a::A
                           end)
    @test splittypedef(ex) == Dict(
        :constructors => Any[],
        :mutable => false,
        :params => Any[:A, :B],
        :name => :S,
        :fields => Any[(:a, :A)],
        :supertype => :(AbstractS{B}),)

    @test ex |> splittypedef |> combinetypedef |> Base.remove_linenums! == 
        ex |> Base.remove_linenums!

    ex = :(struct S{A} <: Foo; S(a::A) where {A} = new{A}() end)
    @test ex |> splittypedef |> combinetypedef |> Base.remove_linenums! == 
        ex |> Base.remove_linenums!

    constructors = splittypedef(ex)[:constructors]
    @test length(constructors) == 1
    @test first(constructors) == :((S(a::A) where A) = new{A}())

end
