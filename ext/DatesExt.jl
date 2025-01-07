module DatesExt

using Accessors
import Accessors: set
using Dates

set(x::DateTime, ::Type{Date}, y) = DateTime(y, Time(x))
set(x::DateTime, ::Type{Time}, y) = DateTime(Date(x), y)
set(x::T, ::Type{T}, y) where {T <: Union{Date, Time}} = y

# directly mirrors Dates.value implementation in stdlib
set(x::Date, ::typeof(Dates.value), y) = @set x.instant.periods.value = y
set(x::DateTime, ::typeof(Dates.value), y) = @set x.instant.periods.value = y
set(x::Time, ::typeof(Dates.value), y) = @set x.instant.value = y

set(x::Date, ::typeof(year),                    y) = Date(y,       month(x), day(x))
set(x::Date, ::typeof(month),                   y) = Date(year(x),        y, day(x))
set(x::Date, ::typeof(day),                     y) = Date(year(x), month(x),      y)
set(x::Date, ::typeof(yearmonth),    y::NTuple{2, Any}) = Date(y...,              day(x))
set(x::Date, ::typeof(monthday),     y::NTuple{2, Any}) = Date(year(x),             y...)
set(x::Date, ::typeof(yearmonthday), y::NTuple{3, Any}) = Date(y...)
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

end
