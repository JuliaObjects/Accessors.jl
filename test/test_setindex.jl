module TestSetindex
using Accessors
using Test

"""
    ==ₜ(x, y)

Check that _type_ and value of `x` and `y` are equal.
"""
==ₜ(_, _) = false
==ₜ(x::T, y::T) where T = x == y

@testset "==ₜ" begin
    @test 1 ==ₜ 1
    @test !(1.0 ==ₜ 1)
end

function ref_alloc_test()
    ref = Ref((UInt(10), 100))
    ref2 = @set ref[][1] *= -1

    ref2[]
end

@testset "setindex" begin
    arr = [1,2,3]
    @test_throws MethodError Base.setindex(arr, 10, 1)
    @test Accessors.setindex(arr, 10, 1) == [10, 2, 3]
    @test arr == [1,2,3]
    @test @set(arr[1] = 10) == [10, 2, 3]
    @test arr == [1,2,3]
    @test Accessors.setindex(arr, 10.0, 1) ==ₜ Float64[10.0, 2.0, 3.0]

    @test Accessors.setindex([1. 2; 3 4], zeros(2), 1, :) ==ₜ [0. 0; 3 4]
    @test Accessors.setindex([[i, j] for i in 1:2, j in 1:2], [im, im], 1, :) ==ₜ Any[[im] [im]; [[2, 1]] [[2, 2]]]

    d = Dict(:a => 1, :b => 2)
    @test_throws MethodError Base.setindex(d, 10, :a)
    @test Accessors.setindex(d, 10, :a) == Dict(:a=>10, :b=>2)
    @test d == Dict(:a => 1, :b => 2)
    @test @set(d[:a] = 10) == Dict(:a=>10, :b=>2)
    @test d == Dict(:a => 1, :b => 2)
    @test Accessors.setindex(d, 30, "c") ==ₜ Dict(:a=>1, :b=>2, "c"=>30)
    @test Accessors.setindex(d, 10.0, :a) ==ₜ Dict(:a=>10.0, :b=>2.0)

    nt = (a=1, b='2')
    @test @set(nt[:a] = "abc") == (a="abc", b='2')
    @test @set(nt[1] = "abc") == (a="abc", b='2')
    
    ref = Ref((; a = 1, b = 2, c = (; aa = 3)))
    @test @set(ref[].a = 90)[] == (; a = 90, b = 2, c = (; aa = 3))
    @test @set(ref[].b = "2")[] ==ₜ (; a = 1, b = "2", c = (; aa = 3))
    @test @set(ref[].c.aa += 2)[] == (; a = 1, b = 2, c = (; aa = 5))

    ref = Ref(1::Int)
    @set ref[] = "no mutation"
    @test ref[] === 1
    @test typeof(ref) == Base.RefValue{Int}
end

@testset begin
    _ = ref_alloc_test()
    @test @allocated(ref_alloc_test()) == 0
end

end
