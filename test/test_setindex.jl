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
    ref = Ref((; a = 10, b = 0x0001, c = (; aa = 300)))
    ref2 = Accessors.setindex(ref, (; a = 10, b = ref[].b - 1, c = (; aa = 300)))
    ref3 = Accessors.setindex(ref, ref2[])

    ref3[]
end

@testset "setindex" begin
    arr = [1,2,3]
    @test_throws MethodError Base.setindex(arr, 10, 1)
    @test Accessors.setindex(arr, 10, 1) == [10, 2, 3]
    @test arr == [1,2,3]
    @test @set(arr[1] = 10) == [10, 2, 3]
    @test arr == [1,2,3]
    @test Accessors.setindex(arr, 10.0, 1) ==ₜ Float64[10.0, 2.0, 3.0]

    d = Dict(:a => 1, :b => 2)
    @test_throws MethodError Base.setindex(d, 10, :a)
    @test Accessors.setindex(d, 10, :a) == Dict(:a=>10, :b=>2)
    @test d == Dict(:a => 1, :b => 2)
    @test @set(d[:a] = 10) == Dict(:a=>10, :b=>2)
    @test d == Dict(:a => 1, :b => 2)
    @test Accessors.setindex(d, 30, "c") ==ₜ Dict(:a=>1, :b=>2, "c"=>30)
    @test Accessors.setindex(d, 10.0, :a) ==ₜ Dict(:a=>10.0, :b=>2.0)
    
    ref = Ref((; a = 10, b = 0x0001, c = (; aa = 300)))
    @test @set(ref[].a = 90)[] == Ref((; a = 90, b = 0x0001, c = (; aa = 300)))[]
    @test @set(ref[].b = Bool(ref[].b))[] == Ref((; a = 10, b = true, c = (; aa = 300)))[]
    @test @set(ref[].c.aa = 3)[] == Ref((; a = 10, b = 0x0001, c = (; aa = 3)))[]

    local val
    @test @allocated(val = ref_alloc_test()) == 0
    @test val == (; a = 10, b = 0x0000, c = (; aa = 300))
end

end
