module TestSetindex
using Setfield
using Test

@testset "setindex" begin
    arr = [1,2,3]
    @test_throws MethodError Base.setindex(arr, 10, 1)
    @test Setfield.setindex(arr, 10, 1) == [10, 2, 3]
    @test arr == [1,2,3]
    @test @set(arr[1] = 10) == [10, 2, 3]
    @test arr == [1,2,3]

    d = Dict(:a => 1, :b => 2)
    @test_throws MethodError Base.setindex(d, 10, :a)
    @test Setfield.setindex(d, 10, :a) == Dict(:a=>10, :b=>2)
    @test d == Dict(:a => 1, :b => 2)
    @test @set(d[:a] = 10) == Dict(:a=>10, :b=>2)
    @test d == Dict(:a => 1, :b => 2)
end

end
