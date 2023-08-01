module AccessorsStaticArraysExt
isdefined(Base, :get_extension) ? (using StaticArrays) : (using ..StaticArrays)
using Accessors
import Accessors: setindex, delete, insert

@inline setindex(a::StaticArray, args...) = Base.setindex(a, args...)
@inline delete(obj::StaticVector, l::IndexLens) = StaticArrays.deleteat(obj, only(l.indices))
@inline insert(obj::StaticVector, l::IndexLens, val) = StaticArrays.insert(obj, only(l.indices), val)

Accessors.set(obj::StaticVector, ::Type{Tuple}, val::Tuple) = constructorof(typeof(obj))(val...)
Accessors.set(obj::Tuple, ::Type{<:StaticVector}, val::StaticVector) = Tuple(val)

Accessors.getall(obj::StaticArray, ::Elements) = Tuple(obj)
Accessors.setall(obj::StaticArray, ::Elements, vs::AbstractArray) = constructorof(typeof(obj))(vs...)  # just for disambiguation
Accessors.setall(obj::StaticArray, ::Elements, vs) = constructorof(typeof(obj))(vs...)

end
