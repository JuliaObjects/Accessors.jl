import .StaticArrays

@inline setindex(a::StaticArrays.StaticArray, args...) = Base.setindex(a, args...)
@inline delete(obj::StaticArrays.SVector, l::IndexLens) = StaticArrays.deleteat(obj, only(l.indices))
@inline insert(obj::StaticArrays.SVector, l::IndexLens, val) = StaticArrays.insert(obj, only(l.indices), val)
