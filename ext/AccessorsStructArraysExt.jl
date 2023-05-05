module AccessorsStructArraysExt
using Accessors
using StructArrays

# set: all eltypes
Accessors.set(x::StructArray, o::Accessors.PropertyLens, v) = set(x, o ∘ StructArrays.components, v)

# insert, delete: only (named)tuples
Accessors.insert(x::StructArray{<:Union{Tuple, NamedTuple}}, o::Accessors.PropertyLens, v) = insert(x, o ∘ StructArrays.components, v)
Accessors.delete(x::StructArray{<:Union{Tuple, NamedTuple}}, o::Accessors.PropertyLens) = delete(x, o ∘ StructArrays.components)

# (named)tuple eltypes: only component arrays themselves are needed in the constructor
# can change component number/names
Accessors.set(x::StructArray{<:Union{Tuple, NamedTuple}}, ::typeof(StructArrays.components), v) = StructArray(v)

# other eltypes: need to pass eltype to the constructor in addition to component arrays
# component number/names stay the same
function Accessors.set(x::StructArray{T}, ::typeof(StructArrays.components), v::VT) where {T, VT}
    # resulting eltype is basically T, but potentially with different type parameters
    # probe its constructorof to get the right concrete type
    ET = Base.promote_op(constructorof(T), map(eltype, _eltypes(VT))...)
    StructArray{ET}(v)
end

_eltypes(::Type{T}) where {T <: Tuple} = Tuple(T.parameters)
_eltypes(::Type{NamedTuple{K, T}}) where {K, T <: Tuple} = Tuple(T.parameters)
end
