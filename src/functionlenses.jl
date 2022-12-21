using LinearAlgebra: norm, normalize
using Dates

set(obj, ::typeof(last), val) = @set obj[lastindex(obj)] = val
set(obj, ::typeof(first), val) = @set obj[firstindex(obj)] = val
delete(obj, ::typeof(last)) = delete(obj, IndexLens((lastindex(obj),)))
delete(obj, ::typeof(first)) = delete(obj, IndexLens((firstindex(obj),)))
insert(obj, ::typeof(last), val) = insert(obj, IndexLens((lastindex(obj) + 1,)), val)
insert(obj, ::typeof(first), val) = insert(obj, IndexLens((firstindex(obj),)), val)

delete(obj, o::Base.Fix2{typeof(first)}) = obj[(firstindex(obj) + o.x):end]

set(obj, ::typeof(identity), val) = val
set(obj, ::typeof(inv), new_inv) = inv(new_inv)

function set(obj, ::typeof(only), val)
    only(obj) # error check
    set(obj, first, val)
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
##### ranges
################################################################################
set(r::AbstractRange, ::typeof(step), s) = range(first(r), last(r), step=s)
set(r::AbstractRange, ::typeof(length), l) = range(first(r), last(r), length=l)
set(r::AbstractRange, ::typeof(first), x) = range(x,  last(r), step=step(r))
set(r::AbstractRange, ::typeof(last),  x) = range(first(r), x, step=step(r))
set(r::AbstractUnitRange, ::typeof(first), x) = x:last(r)
set(r::AbstractUnitRange, ::typeof(last),  x) = first(r):x
set(r::Base.OneTo, ::typeof(last),  x) = Base.OneTo(x)

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
set(x,      ::typeof(abs), y) = y >= zero(y) ? y * sign(x) : throw(DomainError(y, "cannot set abs($x) to $y"))

set(x, ::typeof(mod2pi), y) = set(x, @optic(mod(_, 2π)), y)
set(x, f::Base.Fix2{typeof(fld)}, y) = set(x, @optic(first(fldmod(_, f.x))), y)
set(x, f::Base.Fix2{typeof(mod)}, y) = set(x, @optic(last(fldmod(_, f.x))), y)
set(x, f::Base.Fix2{typeof(div)}, y) = set(x, @optic(first(divrem(_, f.x))), y)
set(x, f::Base.Fix2{typeof(rem)}, y) = set(x, @optic(last(divrem(_, f.x))), y)

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
