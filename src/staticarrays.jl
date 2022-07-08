import StaticArraysCore

@inline setindex(a::StaticArraysCore.StaticArray, args...) = Base.setindex(a, args...)
@inline delete(obj::StaticArraysCore.SVector, l::IndexLens) = StaticArrays.deleteat(obj, only(l.indices))
@inline insert(obj::StaticArraysCore.SVector, l::IndexLens, val) = StaticArrays.insert(obj, only(l.indices), val)
