module TestOptics

using Accessors
using Test

@testset "Recursive" begin
    obj = (a=1, b=(1,2), c=(A=1, B=(1,2,3), D=4))
    rp = Recursive(x -> !(x isa Tuple), Properties())
    @test modify(collect, obj, rp) == (a = 1, b = [1, 2], c = (A = 1, B = [1, 2, 3], D = 4))
end

@testset "Molecule example" begin
    # inspired by https://hackage.haskell.org/package/lens-tutorial-1.0.3/docs/Control-Lens-Tutorial.html
    molecule = (
        name="water",
        atoms=[
            (name="H", position=(x=1,y=1)),
            (name="H", position=(x=1,y=2)),
            (name="O", position=(x=1,y=3)),
        ]
    )


    se = @lens _.atoms |> Elements() |> _.position.x
    res_modify = modify(x->x+1, molecule, se)

    res_macro = @set molecule.atoms |> Elements() |> _.position.x += 1
    @test res_macro == res_modify

    res_expected = (
        name="water",
        atoms=[
            (name="H", position=(x=2,y=1)),
            (name="H", position=(x=2,y=2)),
            (name="O", position=(x=2,y=3)),
        ]
    )

    @test res_expected == res_macro

    res_set = set(molecule, se, 4.0)
    res_macro = @set molecule.atoms |> Elements() |> _.position.x = 4.0
    @test res_macro == res_set

    res_expected = (
        name="water",
        atoms=[
            (name="H", position=(x=4.0,y=1)),
            (name="H", position=(x=4.0,y=2)),
            (name="O", position=(x=4.0,y=3)),
        ]
    )
    @test res_expected == res_set
end

end#module
