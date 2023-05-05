module AccessorsStaticArraysExt
isdefined(Base, :get_extension) ? (import StaticArrays) : (import ..StaticArrays)
using Accessors
using Accessors: only  # for 1.3-
import Accessors: setindex, delete, insert

@inline setindex(a::StaticArrays.StaticArray, args...) = Base.setindex(a, args...)
@inline delete(obj::StaticArrays.SVector, l::IndexLens) = StaticArrays.deleteat(obj, only(l.indices))
@inline insert(obj::StaticArrays.SVector, l::IndexLens, val) = StaticArrays.insert(obj, only(l.indices), val)

Accessors.set(obj::StaticArrays.SVector, ::Type{Tuple}, val::Tuple) = StaticArrays.SVector(val)

end
