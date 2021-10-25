import .StaticArrays
Accessors.setindex(a::StaticArrays.StaticArray, args...) = Base.setindex(a, args...)

@inline function delete(obj::StaticArrays.SVector, l::IndexLens)
	i = only(l.indices)
    StaticArrays.deleteat(obj, i)
end
