module TestGetSetAll
using Test
using Accessors

@testset "getall" begin
    obj = (a=1, b=2.0, c='3')
    @test @inferred(getall(obj, @optic(_.a))) === (1,)
    @test @inferred(getall(obj, @optic(_ |> Properties()))) === (1, 2.0, '3')
    @test @inferred(getall(obj, @optic(_ |> Elements()))) === (1, 2.0, '3')
    @test @inferred(getall(obj, @optic(_ |> Elements() |> _ + 1))) === (2, 3.0, '4')

    obj = (a=1, b=((c=3, d=4), (c=5, d=6)))
    @test @inferred(getall(obj, @optic(_.b |> Elements() |> _.c))) === (3, 5)
    @test @inferred(getall(obj, @optic(_.b |> Elements() |> Properties()))) === (3, 4, 5, 6)
    @test getall(obj, @optic(_.b |> Elements() |> Properties() |> _ * 3)) === (9, 12, 15, 18)
    @test_broken (@inferred(getall(obj, @optic(_.b |> Elements() |> Properties() |> _ * 3))); true)

    obj = (a=((c=1, d=2),), b=((c=3, d=4), (c=5, d=6)))
    @test @inferred(getall(obj, @optic(_ |> Properties() |> Elements() |> _.c))) === (1, 3, 5)
    f(obj) = getall(obj, @optic(_ |> Properties() |> Elements() |> _[:c]))
    @test f(obj) === (1, 3, 5)
    @test_broken (@inferred(f(obj)); true)
    @test @inferred(getall(obj, @optic(_ |> Properties() |> Elements() |> Properties()))) === (1, 2, 3, 4, 5, 6)

    obj = ((a=((c=1, d=2),), b=((c=3, d=4), (c=5, d=6))),)
    @test getall(obj, @optic(_ |> Properties() |> Properties() |> Properties() |> Properties())) === (1, 2, 3, 4, 5, 6)
    @test_broken (@inferred(getall(obj, @optic(_ |> Properties() |> Properties() |> Properties() |> Properties()))); true)
    @test getall(obj, @optic(_ |> Elements() |> Elements() |> Elements() |> Elements())) === (1, 2, 3, 4, 5, 6)
    @test_broken (@inferred(getall(obj, @optic(_ |> Elements() |> Elements() |> Elements() |> Elements()))); true)
end

end
