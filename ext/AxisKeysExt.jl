module AxisKeysExt
using Accessors
using AxisKeys

Accessors.set(x::KeyedArray, ::typeof(axiskeys), v::Tuple) = KeyedArray(AxisKeys.keyless(x), v)
Accessors.set(x::KeyedArray, ::typeof(named_axiskeys), v::NamedTuple) = KeyedArray(AxisKeys.keyless_unname(x); v...)
Accessors.set(x::KeyedArray, ::typeof(dimnames), v::Tuple{Vararg{Symbol}}) = KeyedArray(AxisKeys.keyless_unname(x); NamedTuple{v}(axiskeys(x))...)

Accessors.set(x::KeyedArray, f::Base.Fix2{typeof(axiskeys), Int}, v) = @set axiskeys(x)[f.x] = v
Accessors.set(x::KeyedArray, f::Base.Fix2{typeof(axiskeys), Symbol}, v) = @set named_axiskeys(x)[f.x] = v

Accessors.set(x::KeyedArray, ::typeof(AxisKeys.keyless_unname), v::AbstractArray) = KeyedArray(v; named_axiskeys(x)...)
end
