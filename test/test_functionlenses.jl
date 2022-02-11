module TestFunctionLenses
using Test
using Accessors: test_getset_laws
using Accessors

@testset "os" begin
    path = "hello.md"
    path_new = @set splitext(path)[2] = ".jl"
    @test path_new == "hello.jl"

    path = joinpath("root", "somedir", "some.file")
    path_new = @set splitdir(path)[1] = "otherdir"
    @test path_new == joinpath("otherdir", "some.file")

    test_getset_laws(splitext, "hello.world", ("hi", ".jl"), ("ho", ".md"))
    test_getset_laws(splitdir, joinpath("hello", "world"), ("a", "b"), ("A", "B"))
    test_getset_laws(splitpath, joinpath("hello", "world"), ["some"], ["some", "long", "path"])
    test_getset_laws(dirname, joinpath("hello", "world"), "hi", "ho")
    test_getset_laws(basename, joinpath("hello", "world"), "planet", "earth")
end

@testset "first" begin
    obj = (1, 2.0, '3')
    l = @optic first(_)
    @test l === first
    @test l(obj) === 1
    @test set(obj, l, "1") === ("1", 2.0, '3')
    @test (@set first(obj) = "1") === ("1", 2.0, '3')

    obj2 = (a=((b=1,), 2), c=3)
    @test (@set first(obj2.a).b = '1') === (a=((b='1',), 2), c=3)
    @test (@set first(obj2) = '1') === (a='1', c=3)
    @test @inferred(set(obj2, first, '1')) === (a='1', c=3)
end

@testset "last" begin
    obj = (1, 2.0, '3')
    l = @optic last(_)
    @test l === last
    @test set(obj, l, '4') === (1, 2.0, '4')
    @test (@set last(obj) = '4') === (1, 2.0, '4')

    obj2 = (a=(1, (b=2,)), c=3)
    @test (@set last(obj2.a).b = '2') === (a=(1, (b='2',)), c=3)
end

@testset "eltype on Number" begin
    @test @set(eltype(Int) = Float32) === Float32
    @test @set(eltype(1.0) = UInt8)   === UInt8(1)

    @inferred set(Int, eltype, Float32)
    @inferred set(1.2, eltype, Float32)

end

@testset "eltype(::Type{<:Array})" begin
    obj = Vector{Int}
    @inferred set(obj, eltype, Float32)
    obj2 = @set eltype(obj) = Float64
    @test obj2 === Vector{Float64}
end

@testset "eltype(::Array)" begin
    obj = [1, 2, 3]
    @inferred set(obj, eltype, Float32)
    obj2 = @set eltype(obj) = Float64
    @test eltype(obj2) == Float64
    @test obj == obj2
end

@testset "(key|val|el)type(::Type{<:Dict})" begin
    obj = Dict{Symbol, Int}
    @test (@set keytype(obj) = String) === Dict{String, Int}
    @test (@set valtype(obj) = String) === Dict{Symbol, String}
    @test (@set eltype(obj) = Pair{String, Any}) === Dict{String, Any}

    obj2 = Dict{Symbol, Dict{Int, Float64}}
    @test (@set keytype(valtype(obj2)) = String) === Dict{Symbol, Dict{String, Float64}}
    @test (@set valtype(valtype(obj2)) = String) === Dict{Symbol, Dict{Int, String}}
end

@testset "(key|val|el)type(::Dict)" begin
    obj = Dict(1 => 2)
    @test typeof(@set keytype(obj) = Float64) === Dict{Float64, Int}
    @test typeof(@set valtype(obj) = Float64) === Dict{Int, Float64}
    @test typeof(@set eltype(obj) = Pair{UInt, Float64}) === Dict{UInt, Float64}
end

@testset "math" begin
    x = 1
    @test 2.0       === @set real(1) = 2.0
    @test 1.0 + 2im === @set imag(1) = 2.0
    @test 1.0 + 2im === @set imag(1+1im) = 2.0

end

@testset "custom binary function" begin
    ↑(x, y) = x - y
    Accessors.set(x, f::Base.Fix1{typeof(↑)}, y) = f.x - y
    Accessors.set(x, f::Base.Fix2{typeof(↑)}, y) = f.x + y

    x = 5
    o1 = @optic 2 ↑ _
    o2 = @optic _ ↑ 2
    @test o1(x) == -3
    @test set(x, o1, 10) == -8
    @test o2(x) == 3
    @test set(x, o2, 10) == 12
    test_getset_laws(o1, x, 2, -3)
    test_getset_laws(o2, x, 2, -3)
end

end # module
