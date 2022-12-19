module TestFunctionLenses
using Test
using Dates
using Unitful
using InverseFunctions: inverse
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

@testset "convert" begin
    x = Second(180)
    @test @modify(m -> m + 1, x |> convert(Minute, _).value) === Second(240)
    test_getset_laws(@optic(convert(Minute, _)), x, Minute(10), Minute(20))
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

@testset "array shapes" begin
    A = [1 2 3; 4 5 6]

    B = @insert size(A)[2] = 1
    @test reshape(A, (2, 1, 3)) == B
    @test A == @delete size(B)[2]
    @test_throws Exception @set size(A)[1] = 1
    @test_throws Exception @insert size(A)[2] = 2

    @inferred insert(A, @optic(size(_)[2]), 1)
    @inferred delete(B, @optic(size(_)[2]))

    B = @set vec(A) = 1:6
    @test B == [1 3 5; 2 4 6]

    B = @set reverse(vec(A)) = 1:6
    @test B == [6 4 2; 5 3 1]

    test_getset_laws(size, A, (1, 6), (3, 2))
    test_getset_laws(vec, A, 10:15, 21:26)
    test_getset_laws(reverse, collect(1:6), 10:15, 21:26)
end

@testset "ranges" begin
    r = 1:10
    @test 1:3:10 === @set step(r) = 3
    @test 1:0.5:10 === @set length(r) = 19
    @test -5:10 === @set first(r) = -5
    @test 1:15 === @set last(r) = 15

    r = range(1, 10, length=10)
    @test 1:3.0:10 === @set step(r) = 3
    @test 1:0.5:10 === @set length(r) = 19
    @test -5:1.0:10 === @set first(r) = -5
    @test 1:1.0:15 === @set last(r) = 15

    r = Base.OneTo(10)
    @test 1:3:10 === @set step(r) = 3
    @test 1:0.5:10 === @set length(r) = 19
    @test -5:10 === @set first(r) = -5
    @test Base.OneTo(15) === @set last(r) = 15
end

@testset "math" begin
    @test 2.0       === @set real(1) = 2.0
    @test 2.0 + 1im === @set real(1+1im) = 2.0
    @test 1.0 + 2im === @set imag(1) = 2.0
    @test 1.0 + 2im === @set imag(1+1im) = 2.0
    @test 1u"m"         === @set real(2u"m") = 1u"m"
    @test (2 + 1im)u"m" === @set imag(2u"m") = 1u"m"
    
    @test set.(10, @optic(mod(_, 3)), 0:2) == 9:11
    @test_throws DomainError set(10, @optic(mod(_, 3)), 10)

    test_getset_laws(mod2pi, 5.3, 1, 2; cmp=isapprox)
    test_getset_laws(mod2pi, -5.3, 1, 2; cmp=isapprox)

    test_getset_laws(!, true, true, false)
    @testset for o in [
            # invertible lenses below: no need for extensive testing, simply forwarded to InverseFunctions
            inv, +, exp, sqrt, @optic(2 + _), @optic(_ * 3), @optic(log(2, _)),
            # non-invertible lenses, indirectly forwarded to InverseFunctions
            @optic(mod(_, 21)), @optic(fld(_, 3)), @optic(rem(_, 21)), @optic(div(_, 3)),
        ]
        x = 5
        test_getset_laws(o, x, 10, 20; cmp=isapprox)
        @inferred set(x, o, 10)
    end
    
    x = 3 + 4im
    @test @set(abs(-2u"m") = 1u"m") === -1u"m"
    @test @set(abs(x) = 10) ≈ 6 + 8im
    @test @set(angle(x) = π/2) ≈ 5im
    @test_throws DomainError @set(abs(x) = -10)

    # composition
    o = @optic 1/(1 + exp(-_))
    @test o(2) ≈ 0.8807970779778823
    @test @inferred(set(2, o, 0.999)) ≈ 6.906754778648465

    # setting inverse
    f = @set inverse(sin) = sqrt
    @test f(2) == sin(2)
    @test inverse(f)(4) == 2
end

@testset "dates" begin
    @test set(DateTime(2020, 1, 2, 3, 4, 5, 6), Date, Date(1999, 5, 6)) === DateTime(1999, 5, 6, 3, 4, 5, 6)
    @test set(DateTime(2020, 1, 2, 3, 4, 5, 6), Time, Time(1, 2, 3, 4)) === DateTime(2020, 1, 2, 1, 2, 3, 4)
    @test set(Date(2020, 1, 2), Date, Date(1999, 5, 6)) === Date(1999, 5, 6)
    @test set(Time(3, 4, 5, 6), Time, Time(1, 2, 3, 4)) === Time(1, 2, 3, 4)

    @testset for lens in [year, month, day, dayofweek, hour, minute, second, millisecond]
        test_getset_laws(lens, DateTime(2020, 1, 2, 3, 4, 5, 6), rand(1:7), rand(1:7))
    end
    @testset for lens in [year, month, day, dayofweek]
        test_getset_laws(lens, Date(2020, 1, 2), rand(1:7), rand(1:7))
    end
    @testset for lens in [hour, minute, second, millisecond, microsecond, nanosecond]
        test_getset_laws(lens, Time(1, 2, 3, 4, 5, 6), rand(0:23), rand(0:23))
    end
    @testset for x in [DateTime(2020, 1, 2, 3, 4, 5, 6), Date(2020, 1, 2)]
        test_getset_laws(yearmonth, x, (rand(1:5000), rand(1:12)), (rand(1:5000), rand(1:12)))
        test_getset_laws(monthday, x, (rand(1:12), rand(1:28)), (rand(1:12), rand(1:28)))
        test_getset_laws(yearmonthday, x, (rand(1:5000), rand(1:12), rand(1:28)), (rand(1:5000), rand(1:12), rand(1:28)))
    end
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
