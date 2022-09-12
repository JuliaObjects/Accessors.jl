import StaticArraysCore

@inline setindex(a::StaticArraysCore.StaticArray, args...) = Base.setindex(a, args...)
@inline delete(obj::StaticArraysCore.SVector, l::IndexLens) = StaticArraysCore.deleteat(obj, only(l.indices))
@inline insert(obj::StaticArraysCore.SVector, l::IndexLens, val) = StaticArraysCore.insert(obj, only(l.indices), val)
