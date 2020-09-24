module TestOptics

using Accessors
using Test

@testset "Properties" begin
    pt = (x=1, y=2, z=3)
    @test (x=0, y=1, z=2) === @set pt |> Properties() -= 1
end

@testset "Elements" begin
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

end#module
