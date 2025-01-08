module StructArraysExt
using Accessors
using StructArrays

# set: all eltypes
Accessors.set(x::StructArray, o::PropertyLens, v) = set(x, o ∘ StructArrays.components, v)

# insert, delete: only (named)tuples
Accessors.insert(x::StructArray{<:Union{Tuple, NamedTuple}}, o::PropertyLens, v) = insert(x, o ∘ StructArrays.components, v)
Accessors.delete(x::StructArray{<:Union{Tuple, NamedTuple}}, o::PropertyLens) = delete(x, o ∘ StructArrays.components)

Accessors.set(x::StructArray{<:Union{Tuple, NamedTuple}}, ::typeof(propertynames), names) = set(x, propertynames ∘ StructArrays.components, names)

Accessors.set(x::StructArray, ::typeof(StructArrays.components), v) = constructorof(typeof(x))(v)

end
