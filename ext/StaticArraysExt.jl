module StaticArraysExt
using StaticArrays
using Accessors
import Accessors: setindex, delete, insert

@inline setindex(a::StaticArray{<:Any,ET}, v::T, I...) where {ET,T} = Base.setindex(similar_type(typeof(a), promote_type(ET, T))(a), v, I...)
@inline setindex(a::StaticArray{<:Any,T}, v::T, I...) where {T} = Base.setindex(a, v, I...)
@inline delete(obj::StaticVector, l::IndexLens) = StaticArrays.deleteat(obj, only(l.indices))
@inline insert(obj::StaticVector{<:Any,ET}, l::IndexLens, val::T) where {ET,T} = StaticArrays.insert(similar_type(typeof(obj), promote_type(ET, T))(obj), only(l.indices), val)
@inline insert(obj::StaticVector{<:Any,T}, l::IndexLens, val::T) where {T} = StaticArrays.insert(obj, only(l.indices), val)

Accessors.set(obj::StaticVector, ::Type{Tuple}, val::Tuple) = constructorof(typeof(obj))(val...)
Accessors.set(obj::Tuple, ::Type{<:StaticVector}, val::StaticVector) = Tuple(val)

Accessors.getall(obj::StaticArray, ::Elements) = Tuple(obj)
Accessors.setall(obj::StaticArray, ::Elements, vs::AbstractArray) = constructorof(typeof(obj))(vs...)  # just for disambiguation
Accessors.setall(obj::StaticArray, ::Elements, vs) = constructorof(typeof(obj))(vs...)

end
