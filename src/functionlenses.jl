using LinearAlgebra: norm, normalize
using Dates

set(obj, ::typeof(last), val) = @set obj[lastindex(obj)] = val
set(obj, ::typeof(first), val) = @set obj[firstindex(obj)] = val
delete(obj, ::typeof(last)) = delete(obj, IndexLens((lastindex(obj),)))
delete(obj, ::typeof(first)) = delete(obj, IndexLens((firstindex(obj),)))
insert(obj, ::typeof(last), val) = insert(obj, IndexLens((lastindex(obj) + 1,)), val)
insert(obj, ::typeof(first), val) = insert(obj, IndexLens((firstindex(obj),)), val)

set(obj, o::Base.Fix2{typeof(first)}, val) = @set obj[firstindex(obj):(firstindex(obj) + o.x - 1)] = val
set(obj, o::Base.Fix2{typeof(last)}, val) = @set obj[(lastindex(obj) - o.x + 1):lastindex(obj)] = val
delete(obj, o::Base.Fix2{typeof(first)}) = obj[(firstindex(obj) + o.x):lastindex(obj)]
delete(obj, o::Base.Fix2{typeof(last)}) = obj[firstindex(obj):(lastindex(obj) - o.x)]
insert(obj, o::Base.Fix2{typeof(first)}, val) = @insert obj[firstindex(obj):(firstindex(obj) + o.x - 1)] = val
insert(obj, o::Base.Fix2{typeof(last)}, val) = @insert obj[(lastindex(obj) + 1):(lastindex(obj) + o.x)] = val

set(obj::Tuple, ::typeof(Base.front), val::Tuple) = (val..., last(obj))
set(obj::Tuple, ::typeof(Base.tail), val::Tuple) = (first(obj), val...)

set(obj, ::typeof(identity), val) = val
set(obj, ::typeof(inv), new_inv) = inv(new_inv)

function set(obj, ::typeof(only), val)
    only(obj) # error check
    set(obj, first, val)
end

function set(x::TX, f::Base.Fix1{typeof(convert)}, v) where {TX}
    v isa f.x || throw(ArgumentError("convert($(f.x), _) cannot have type $(typeof(v))"))
    convert(TX, v)
end

set(obj::Tuple, ::Type{Tuple}, val::Tuple) = val
set(obj::NamedTuple{KS}, ::Type{Tuple}, val::Tuple) where {KS} = NamedTuple{KS}(val)
set(obj::CartesianIndex, ::Type{Tuple}, val::Tuple) = CartesianIndex(val)
set(obj::AbstractVector, ::Type{Tuple}, val::Tuple) = similar(obj, eltype(val)) .= val

set(obj, ::Type{NamedTuple{KS}}, val::NamedTuple) where {KS} = set(obj, Tuple, values(NamedTuple{KS}(val)))
function set(obj::NamedTuple, ::Type{NamedTuple{KS}}, val::NamedTuple) where {KS}
    length(KS) == length(val) || throw(ArgumentError("Cannot assign NamedTuple with keys $KSV to NamedTuple with keys $KS"))
    setproperties(obj, NamedTuple{KS}(val))
end

################################################################################
##### eltype
################################################################################
set(obj::Array, ::typeof(eltype), T::Type) = collect(T, obj)
set(obj::Number, ::typeof(eltype), T::Type) = T(obj)
set(obj::Type{<:Number}, ::typeof(eltype), ::Type{T}) where {T} = T
set(obj::Type{<:Array{<:Any,N}}, ::typeof(eltype), ::Type{T}) where {N,T} = Array{T,N}
set(obj::Type{<:Dict}, ::typeof(eltype), ::Type{Pair{K,V}}) where {K,V} = Dict{K,V}
set(obj::Dict, ::typeof(eltype), ::Type{T}) where {T} = set(typeof(obj), eltype, T)(obj)

set(obj::Dict, lens::Union{typeof(keytype),typeof(valtype)}, T::Type) =
    set(typeof(obj), lens, T)(obj)
set(obj::Type{<:Dict{<:Any,V}}, lens::typeof(keytype), ::Type{K}) where {K,V} = Dict{K,V}
set(obj::Type{<:Dict{K}}, lens::typeof(valtype), ::Type{V}) where {K,V} = Dict{K,V}

################################################################################
##### array shapes
################################################################################
set(obj, ::typeof(size), v::Tuple) = reshape(obj, v)

# set vec(): keep array shape and type, change its values
function set(x::AbstractArray, ::typeof(vec), v::AbstractVector)
    res = similar(x, eltype(v))
    vec(res) .= v
    res
end

# set reverse(): keep vector type, change its values
function set(x::AbstractVector, ::typeof(reverse), v::AbstractVector)
    res = similar(x, eltype(v))
    res .= v
    reverse!(res)
    res
end

################################################################################
##### os
################################################################################
set(path, ::typeof(splitext), (stem, ext))     = string(stem, ext)
set(path, ::typeof(splitdir), (dir, last))     = joinpath(dir, last)
set(path, ::typeof(splitdrive), (drive, rest)) = joinpath(drive, rest)
set(path, ::typeof(splitpath), pieces)         = joinpath(pieces...)
set(path, ::typeof(dirname), new_name)         = @set splitdir(path)[1] = new_name
set(path, ::typeof(basename), new_name)        = @set splitdir(path)[2] = new_name
delete(path, ::typeof(basename)) = dirname(path)
delete(path, ::typeof(dirname)) = basename(path)

################################################################################
##### math
################################################################################
set(x::T,  ::typeof(real), y) where {T} = T === real(T) ? y : y + im*imag(x)
set(x,     ::typeof(imag), y) = real(x) + im*y
set(x,    ::typeof(angle), y) = abs(x) * cis(y)
function set(x, ::typeof(abs), y)
    y >= zero(y) || throw(DomainError(y, "cannot set abs($x) to $y"))
    s = sign(x)
    iszero(s) ? y * one(x) : y * s
end

set(x, ::typeof(mod2pi), y) = set(x, @optic(mod(_, 2π)), y)
set(x, f::Base.Fix2{typeof(fld)}, y) = set(x, @optic(first(fldmod(_, f.x))), y)
set(x, f::Base.Fix2{typeof(mod)}, y) = set(x, @optic(last(fldmod(_, f.x))), y)
set(x, f::Base.Fix2{typeof(div)}, y) = set(x, @optic(first(divrem(_, f.x))), y)
set(x, f::Base.Fix2{typeof(rem)}, y) = set(x, @optic(last(divrem(_, f.x))), y)

set(x::AbstractString, f::Base.Fix1{typeof(parse), Type{T}}, y::T) where {T} = string(y)

set(arr, ::typeof(normalize), val) = norm(arr) * val
set(arr, ::typeof(norm), val)      = val/norm(arr) * arr # should we check val is positive?

set(f, ::typeof(inverse), invf) = setinverse(f, invf)

################################################################################
##### dates
################################################################################
set(x::DateTime, ::Type{Date}, y) = DateTime(y, Time(x))
set(x::DateTime, ::Type{Time}, y) = DateTime(Date(x), y)
set(x::T, ::Type{T}, y) where {T <: Union{Date, Time}} = y

set(x::Date, ::typeof(year),                    y) = Date(y,       month(x), day(x))
set(x::Date, ::typeof(month),                   y) = Date(year(x),        y, day(x))
set(x::Date, ::typeof(day),                     y) = Date(year(x), month(x),      y)
set(x::Date, ::typeof(yearmonth),    y::NTuple{2}) = Date(y...,              day(x))
set(x::Date, ::typeof(monthday),     y::NTuple{2}) = Date(year(x),             y...)
set(x::Date, ::typeof(yearmonthday), y::NTuple{3}) = Date(y...)
set(x::Date, ::typeof(dayofweek),               y) = firstdayofweek(x) + Day(y - 1)

set(x::Time, ::typeof(hour),        y) = Time(y,       minute(x), second(x), millisecond(x), microsecond(x), nanosecond(x))
set(x::Time, ::typeof(minute),      y) = Time(hour(x),         y, second(x), millisecond(x), microsecond(x), nanosecond(x))
set(x::Time, ::typeof(second),      y) = Time(hour(x), minute(x),         y, millisecond(x), microsecond(x), nanosecond(x))
set(x::Time, ::typeof(millisecond), y) = Time(hour(x), minute(x), second(x),              y, microsecond(x), nanosecond(x))
set(x::Time, ::typeof(microsecond), y) = Time(hour(x), minute(x), second(x), millisecond(x),              y, nanosecond(x))
set(x::Time, ::typeof(nanosecond),  y) = Time(hour(x), minute(x), second(x), millisecond(x), microsecond(x),             y)

set(x::DateTime, optic::Union{typeof.((year, month, day, yearmonth, monthday, yearmonthday, dayofweek))...}, y) = modify(d -> set(d, optic, y), x, Date)
set(x::DateTime, optic::Union{typeof.((hour, minute, second, millisecond))...}, y) = modify(d -> set(d, optic, y), x, Time)


set(x::AbstractString, optic::Base.Fix2{Type{T}}, dt::T) where {T <: Union{Date, Time, DateTime}} = Dates.format(dt, optic.x)

################################################################################
##### strings
################################################################################

function set(s::AbstractString, o::Base.Fix2{typeof(first)}, v::AbstractString)
    length(v) == o.x || throw(DimensionMismatch("tried to assign $(length(v)) elements to $(o.x) destinations"))
    v * chop(s; head=o.x, tail=0)
end

function set(s::AbstractString, o::Base.Fix2{typeof(last)}, v::AbstractString)
    length(v) == o.x || throw(DimensionMismatch("tried to assign $(length(v)) elements to $(o.x) destinations"))
    chop(s; head=0, tail=o.x) * v
end

if VERSION >= v"1.8"
    set(s::AbstractString, o::Base.Fix2{typeof(chopsuffix), <:AbstractString}, v) =
        endswith(s, o.x) ? v * o.x : v
    set(s::AbstractString, o::Base.Fix2{typeof(chopprefix), <:AbstractString}, v) =
        startswith(s, o.x) ? o.x * v : v
end

set(s::AbstractString, ::typeof(strip), v) = @set lstrip(rstrip(s)) = v
set(s::AbstractString, ::typeof(lstrip), v) = @set s |> lstrip(isspace, _) = v
set(s::AbstractString, ::typeof(rstrip), v) = @set s |> rstrip(isspace, _) = v

set(s::AbstractString, o::Base.Fix1{typeof(strip)}, v) = @set s |> lstrip(o.x, rstrip(o.x, _)) = v
function set(s::AbstractString, o::Base.Fix1{typeof(lstrip)}, v)
    ix = findfirst(!o.x, s)
    isnothing(ix) && (ix = nextind(s, lastindex(s)))
    s[1:prevind(s, ix)] * v
end
function set(s::AbstractString, o::Base.Fix1{typeof(rstrip)}, v)
    ix = findlast(!o.x, s)
    isnothing(ix) && (ix = prevind(s, firstindex(s)))
    v * s[nextind(s, ix):end]
end

function set(s::AbstractString, o::Base.Fix2{typeof(split), <:Union{AbstractChar,AbstractString}}, v)
    any(c -> occursin(o.x, c), v) && throw(ArgumentError("split components cannot contain the delimiter $(repr(o.x))"))
    join(v, o.x)
end
