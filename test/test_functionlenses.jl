module TestFunctionLenses
using Test
using Dates
using Unitful
using LinearAlgebra: norm, diag
using AxisKeys
using InverseFunctions: inverse
using Accessors: test_getset_laws, test_modify_law, test_insertdelete_laws
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

    @test set([1, 2, 3], @optic(first(_, 2)), [4, 5]) == [4, 5, 3]
    @test_throws DimensionMismatch set([1, 2, 3], @optic(first(_, 2)), [4])

    @test set("абв", first, 'x') == "xбв"
    @test set("абв", @optic(first(_, 2)), "xж") == "xжв"
    @test_throws DimensionMismatch set("абв", @optic(first(_, 2)), "x")

    test_getset_laws(first, obj, 123, "456")
    test_getset_laws(first, "abc", 'x', ' ')
end

@testset "last" begin
    obj = (1, 2.0, '3')
    l = @optic last(_)
    @test l === last
    @test set(obj, l, '4') === (1, 2.0, '4')
    @test (@set last(obj) = '4') === (1, 2.0, '4')

    obj2 = (a=(1, (b=2,)), c=3)
    @test (@set last(obj2.a).b = '2') === (a=(1, (b='2',)), c=3)

    @test set([1, 2, 3], @optic(last(_, 2)), [4, 5]) == [1, 4, 5]
    @test_throws DimensionMismatch set([1, 2, 3], @optic(last(_, 2)), [4])

    @test set("абв", last, 'x') == "абx"
    @test set("абв", @optic(last(_, 2)), "xж") == "аxж"
    @test_throws DimensionMismatch set("абв", @optic(last(_, 2)), "x")

    test_getset_laws(last, obj, 123, "456")
    test_getset_laws(last, "abc", 'x', ' ')
end

@testset "front, tail" begin
    obj = (1, 2.0, '3')
    @test (@set Base.front(obj) = ("5", 6)) === ("5", 6, '3')
    @test set(obj, Base.tail, ("5", 6)) === (1, "5", 6)

    test_getset_laws(Base.front, obj, (), ("456", 7))
    test_getset_laws(Base.tail, obj, (123,), ("456", 7))
end

@testset "change types" begin
    x = Second(180)
    @test @modify(m -> m + 1, x |> convert(Minute, _).value) === Second(240)
    @test_throws ArgumentError @set x |> convert(Minute, _) = 123
    test_getset_laws(@optic(convert(Minute, _)), x, Minute(10), Minute(20))

    cmp(a::NamedTuple, b::NamedTuple) = Set(keys(a)) == Set(keys(b)) && NamedTuple{keys(b)}(a) === b
    cmp(a::T, b::T) where {T} = a == b

    test_getset_laws(Base.splat(=>), (1, 'a'), 'b' => 2, 3 => 'c'; cmp=cmp)
    test_getset_laws(Base.splat(Pair), (1, 'a'), 'b' => 2, 3 => 'c'; cmp=cmp)
    test_getset_laws(Base.splat(=>), [1, 2], 3 => 2, 3 => 4; cmp=cmp)
    
    test_getset_laws(Tuple, (1, 'a'), ('x', 'y'), (1, 2))
    test_getset_laws(Tuple, (a=1, b='a'), ('x', 'y'), (1, 2))
    test_getset_laws(Tuple, [0, 1], ('x', 'y'), (1, 2); cmp=cmp)
    test_getset_laws(Tuple, CartesianIndex(1, 2), (3, 4), (5, 6))

    test_getset_laws(NamedTuple{(:x, :y)}, (1, 'a'), (x='x', y='y'), (x=1, y=2); cmp=cmp)
    test_getset_laws(NamedTuple{(:x, :y)}, (1, 'a'), (y='x', x='y'), (x=1, y=2); cmp=cmp)
    test_getset_laws(NamedTuple{(:x, :y)}, (y=1, x='a'), (x='x', y='y'), (x=1, y=2); cmp=cmp)
    test_getset_laws(NamedTuple{(:x, :y)}, (y=1, x='a'), (y='x', x='y'), (x=1, y=2); cmp=cmp)
    test_getset_laws(NamedTuple{(:x, :y)}, (y=1, z=10, x='a'), (x='x', y='y'), (x=1, y=2); cmp=cmp)
    test_getset_laws(NamedTuple{(:x, :y)}, (y=1, z=10, x='a'), (y='x', x='y'), (x=1, y=2); cmp=cmp)
    test_getset_laws(NamedTuple{(:x, :y)}, [0, 1], (x='x', y='y'), (x=1, y=2); cmp=cmp)
    test_getset_laws(NamedTuple{(:x, :y)}, [0, 1], (y='x', x='y'), (x=1, y=2); cmp=cmp)
    test_getset_laws(NamedTuple{(:x, :y)}, CartesianIndex(1, 2), (x=3, y=4), (x=5, y=6); cmp=cmp)
    test_getset_laws(NamedTuple{(:x, :y)}, CartesianIndex(1, 2), (y=3, x=4), (x=5, y=6); cmp=cmp)

    test_getset_laws(Accessors.getproperties, 1+2im, (im=4., re=3.), (re=5, im=6); cmp=cmp)

    @testset for obj in [(10, 20.), (x=10, y=20.)]
        @test (@set propertynames(obj) = 1:2) === (10, 20.)
        @test (@set propertynames(obj) = (:a, :b)) === (a=10, b=20.)
        @test_throws Exception (@set propertynames(obj) = 1:3)
        @test_throws Exception (@set propertynames(obj) = (2, 3))
        @test_throws Exception (@set propertynames(obj) = (:a, :b, :c))
        @test_throws Exception (@set propertynames(obj) = (1, :b))
        @test_throws Exception (@set propertynames(obj) = ("a", "b"))
    end
    test_getset_laws(propertynames, (10, 20.), (:a, :b), (1, 2); cmp=(===))
    test_getset_laws(propertynames, (10, 20.), (1, 2), (:a, :b); cmp=(===))
    test_getset_laws(propertynames, (a=10, b=20.), (:x, :y), (1, 2); cmp=(===))
    test_getset_laws(propertynames, (a=10, b=20.), (1, 2), (:x, :y); cmp=(===))
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

@testset "arrays" begin
    A = [1 2 3; 4 5 6]

    B = @insert size(A)[2] = 1
    @test reshape(A, (2, 1, 3)) == B
    @test A == @delete size(B)[2]
    test_insertdelete_laws((@optic size(_)[2]), A, 1)
    @test_throws Exception @set size(A)[1] = 1
    @test_throws Exception @insert size(A)[2] = 2

    @inferred insert(A, @optic(size(_)[2]), 1)
    @inferred delete(B, @optic(size(_)[2]))

    B = @set vec(A) = 1:6
    @test B == [1 3 5; 2 4 6]

    B = @set reverse(vec(A)) = 1:6
    @test B == [6 4 2; 5 3 1]
    @test set([1, 2], reverse, (3, 4)) == [4, 3]
    @test set((1, 2), reverse, [3, 4]) === (4, 3)
    @test set((a=1, b=2), reverse, [3, 4]) === (a=4, b=3)

    C = KeyedArray([1,2,3], x=[:a, :b, :c])
    @test (@set vec(C) = [5,6,7])::KeyedArray == KeyedArray([5,6,7], x=[:a, :b, :c])
    @test (@set reverse(C) = [5,6,7])::KeyedArray == KeyedArray([7,6,5], x=[:a, :b, :c])

    test_getset_laws(size, A, (1, 6), (3, 2))
    test_getset_laws(vec, A, 10:15, 21:26)
    test_getset_laws(reverse, collect(1:6), 10:15, 21:26)
    test_getset_laws(reverse, [3, 4], (1, 2), (:a, :b); cmp=(x,y) -> collect(x) == collect(y))

    @test @inferred(modify(x -> x ./ sum(x), [1, -2, 3], @optic filter(>(0), _))) == [0.25, -2, 0.75]
    @test isequal(modify(x -> x ./ sum(x), [1, missing, 3], skipmissing), [0.25, missing, 0.75])
    @test modify(cumsum, [2, 3, 1], sort) == [3, 6, 1]

    test_getset_laws(@optic(map(first, _)), [(1,), (2,)], [(3,), (4,)], [(5,), (6,)])
    test_getset_laws(@optic(filter(>(0), _)), [1, -2, 3, -4, 5, -6], [1, 2, 3], [1, 3, 5])
    test_modify_law(reverse, @optic(filter(>(0), _)), [1, -2, 3, -4, 5, -6])
    test_getset_laws(skipmissing, [1, missing, 3], [0, 1], [5, 6]; cmp=(x,y) -> isequal(collect(x), collect(y)))
    test_modify_law(cumsum, sort, [1, -2, 3, -4, 5, -6])

    test_getset_laws(diag, [1 2; 3 4], [1., 2.5], [0, 1])
    test_getset_laws(diag, [1 2 3; 4 5 6], [1., 2.5], [0, 1])
end

@testset "broadcast" begin
    # in optic definiton
    @test (@optic exp.(_)) === Base.BroadcastFunction(exp)
    @test (@optic .-_) === Base.BroadcastFunction(-)
    @test (@optic 1 .+ _) === Base.Fix1(Base.BroadcastFunction(+), 1)
    A = [[1,2], [1,2,3], [1,2,3,4]]
    @test (@set first.(A) = 10:12) == [[10, 2], [11, 2, 3], [12, 2, 3, 4]]

    test_getset_laws((@optic first.(_)), [[1,2], [1,2,3]], [3., 4.], [5, 6])
    test_getset_laws((@optic _ .- 1), [1, 2], [3., 4.], [5, 6])
    test_getset_laws((@optic 1 .- _), [1, 2], [3., 4.], [5, 6])
    test_getset_laws((@optic [10, 20] .* first.(_)), [[1,2], [1,2,3]], [3., 4.], [5, 6])

    # in @set update operation
    @test (@set A .= 1) == [1, 1, 1]
    @test (@set A[1] .= 1) == [[1,1], [1,2,3], [1,2,3,4]]
    @test (@set A[1] .= [10, 20]) == [[10,20], [1,2,3], [1,2,3,4]]

    # broadcasting in both optic and set, with a user-defined function
    @accessor f(x) = x+1
    @test (@set f.(first.(A)) .= [10, 20, 30]) == [[9,2], [19,2,3], [29,2,3,4]]
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

    test_getset_laws(Base.splat(atan), (3, 4), 1, 2)
    test_getset_laws(Base.splat(atan), (a=3, b=4), 1, 2)

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

    @testset for (rng, x, y) in [
        (0:3, 2, 1),
        (0:3, 32, 1),
        (20:23, 2, 20),
        (20:23, 32, 21),
        (5:8, 20, 6),
    ]
        test_getset_laws((@o mod(_, rng)), x, y, y+1)
    end
    @test_throws Exception mod(3, 1:0)
    @test_throws Exception @set mod($3, 1:0) = 1
    @test_throws Exception @set mod($3, 1:5) = 10
    
    x = 3 + 4im
    @test @set(abs(-2u"m") = 1u"m") === -1u"m"
    @test @set(abs(x) = 10) ≈ 6 + 8im
    @test @set(angle(x) = π/2) ≈ 5im
    @test set(0, abs, 0) == 0
    @test set(0, abs, 10) == 10
    @test set(0+0im, abs, 0) == 0+0im
    @test set(0+0im, abs, 10) == 10
    @test set(0+1e-100im, abs, 10) == 10im
    @test_throws DomainError @set(abs(x) = -10)
    test_getset_laws(abs2, 1+2im, 3, 4, cmp=(≈))

    # composition
    o = @optic 1/(1 + exp(-_))
    @test o(2) ≈ 0.8807970779778823
    @test @inferred(set(2, o, 0.999)) ≈ 6.906754778648465

    @test @inferred(modify(x -> -2x, "3", @optic parse(Int, _))) == "-6"
    @test_throws ErrorException modify(log10, "100", @optic parse(Int, _))
    @test modify(log10, "100", @optic parse(Float64, _)) == "2.0"
    test_getset_laws(@optic(parse(Int, _)), "3", -10, 123)
    test_getset_laws(@optic(parse(Float64, _)), "3.0", -10., 123.)

    # setting inverse
    myasin(x) = asin(x)+2π
    f = @set inverse(sin) = myasin
    @test f(2) == sin(2)
    @test inverse(f)(0.5) == asin(0.5) + 2π

    @test set([3, 4], norm, 10) == [6, 8]
    @test set((3, 4), norm, 10) === (6., 8.)
    @test set((a=3, b=4), norm, 10) === (a=6., b=8.)
    test_getset_laws(norm, (3, 4), 10, 12)
    test_getset_laws(norm, (0, 0), 0, 0)
    test_getset_laws(Base.splat(hypot), (3, 4), 10, 12)
    test_getset_laws(Base.splat(hypot), (0, 0), 0, 0.)

    test_getset_laws(!(@optic _.a), (a=true,), false, true)
    test_getset_laws(!(@optic _[1]), (a=true,), false, true)
    test_getset_laws(!(@optic _[end]), (a=true,), false, true)
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
        test_getset_laws(yearmonth, x, (rand(1:5000), rand(1:12) |> Int8), (rand(1:5000), rand(1:12)))
        test_getset_laws(monthday, x, (rand(1:12), rand(1:28) |> Int8), (rand(1:12), rand(1:28)))
        test_getset_laws(yearmonthday, x, (rand(1:5000), rand(1:12) |> Int8, rand(1:28)), (rand(1:5000), rand(1:12), rand(1:28)))
    end

    @testset for x in [DateTime(2020, 1, 2, 3, 4, 5, 6), Date(2020, 1, 2), Time(1, 2, 3, 4, 5, 6)]
        test_getset_laws(Dates.value, x, 123, 456)
    end

    l = @optic DateTime(_, dateformat"yyyy_mm_dd")
    @test @inferred(set("2020_03_04", month ∘ l, 10)) == "2020_10_04"
    test_getset_laws(month ∘ l, "2020_03_04", 10, 11)

    l = @optic Date(_, dateformat"yyyy/mm/dd")
    @test set("2020/03/04", day ∘ l, 10) == "2020/03/10"
    test_getset_laws(day ∘ l, "2020/03/04", 10, 11)
    @test_throws ArgumentError set("2020_03_04", month ∘ l, 10)

    l = @optic Time(_, dateformat"HH:MM")
    test_getset_laws(hour ∘ l, "12:34", 10, 11)
end

@testset "strings" begin
    @test @inferred(modify(x -> x+1, " abc def", @optic(_ |> chopsuffix(_, "def") |> strip |> Elements()))) == " bcd def"
    @test @inferred(modify(x -> x+1, " abc xyz", @optic(_ |> chopsuffix(_, "def") |> strip |> Elements()))) == " bcd!yz{"

    @test @inferred(modify(x -> x^2, "abc xyz", @optic(split(_, ' ') |> Elements()))) == "abcabc xyzxyz"
    @test @inferred(modify(x -> x^2, " abc  xyz", @optic(split(_, ' ') |> Elements()))) == " abcabc  xyzxyz"

    test_getset_laws(lstrip, " abc  ", "def", "")
    test_getset_laws(rstrip, " abc  ", "def", "")
    test_getset_laws(strip, " abc  ", "def", "")
    test_getset_laws(lstrip, "abc", "def", "")
    test_getset_laws(rstrip, "abc", "def", "")
    test_getset_laws(strip, "abc", "def", "")
    test_getset_laws(@optic(lstrip(==(' '), _)), " abc  ", "def", "")
    test_getset_laws(@optic(rstrip(==(' '), _)), " abc  ", "def", "")
    test_getset_laws(@optic(strip(==(' '), _)), " abc  ", "def", "")
    test_getset_laws(chomp, "abc", "def", "")
    test_getset_laws(chomp, "abc\n", "def", "")
    test_getset_laws(chomp, "abc\n\n", "def\n", "")

    test_getset_laws(@optic(chopprefix(_, "def")), "def abc", "xyz", "")
    test_getset_laws(@optic(chopsuffix(_, "def")), "abc def", "xyz", "")
    test_getset_laws(@optic(chopprefix(_, "abc")), "def abc", "xyz", "")
    test_getset_laws(@optic(chopsuffix(_, "abc")), "abc def", "xyz", "")
    
    test_getset_laws(@optic(split(_, ' ')), " abc def ", ["z"], [])
    test_getset_laws(@optic(split(_, ' ')), " abc def ", ["", "z"], [])
    @test_throws ArgumentError set(" abc def ", @optic(split(_, ' ')), [" ", "y"])
end

VERSION ≥ v"1.11" && @testset "AnnotatedStrings" begin
    using Base: AnnotatedChar, AnnotatedString, annotations

    s = AnnotatedString("good bad", [(region=1:4, label=:sentiment, value=+1), (region=6:8, label=:sentiment, value=-1)])
    
    @test (@delete annotations(s))::String == "good bad"
    
    snew = @delete annotations(s)[2]
    @test String(snew) == "good bad"
    @test annotations(snew) == [(region=1:4, label=:sentiment, value=+1)]

    snew = (@set annotations(s)[1].region = 2:6)
    @test String(snew) == "good bad"
    @test annotations(snew) == [(region=2:6, label=:sentiment, value=+1), (region=6:8, label=:sentiment, value=-1)]

    test_getset_laws((@o annotations(_)[2].region), s, 5:5, 1:3)
    test_getset_laws((@o annotations(_)[2].label), s, :abc, :def)
    test_getset_laws((@o annotations(_)[2].value), s, "sad", +2)
    test_insertdelete_laws((@o annotations(_)[2]), s, (region=2:2, label=:mylabel, value=+1))

    
    c = AnnotatedChar('x', [(label=:level, value="warning"), (label=:alphabet, value=1)])
    
    @test (@delete annotations(c))::Char == 'x'
    
    cnew = @delete annotations(c)[2]
    @test Char(cnew) == 'x'
    @test annotations(cnew) == [(label=:level, value="warning")]

    cnew = (@set annotations(c)[1].label = :severity)
    @test Char(cnew) == 'x'
    @test annotations(cnew) == [(label=:severity, value="warning"), (label=:alphabet, value=1)]

    test_getset_laws((@o annotations(_)[2].label), c, :abc, :def)
    test_getset_laws((@o annotations(_)[1].value), c, 5, "bad")
    test_insertdelete_laws((@o annotations(_)[2]), c, (label=:mylabel, value=+1))
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
