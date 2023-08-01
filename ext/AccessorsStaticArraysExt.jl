module AccessorsStaticArraysExt
isdefined(Base, :get_extension) ? (using StaticArrays) : (using ..StaticArrays)
using Accessors
import Accessors: setindex, delete, insert

@inline setindex(a::StaticArray, args...) = Base.setindex(a, args...)
@inline delete(obj::SVector, l::IndexLens) = StaticArrays.deleteat(obj, only(l.indices))
@inline insert(obj::SVector, l::IndexLens, val) = StaticArrays.insert(obj, only(l.indices), val)

Accessors.set(obj::SVector, ::Type{Tuple}, val::Tuple) = SVector(val)
Accessors.set(obj::Tuple, ::Type{SVector}, val::SVector) = Tuple(val)

Accessors.getall(obj::StaticArray, ::Elements) = Tuple(obj)
Accessors.setall(obj::StaticArray, ::Elements, vs::AbstractArray) = constructorof(typeof(obj))(vs...)  # just for disambiguation
Accessors.setall(obj::StaticArray, ::Elements, vs) = constructorof(typeof(obj))(vs...)

end
