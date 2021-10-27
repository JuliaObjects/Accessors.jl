import .StaticArrays
Accessors.setindex(a::StaticArrays.StaticArray, args...) = Base.setindex(a, args...)

@inline function delete(obj::StaticArrays.SVector, l::IndexLens)
	i = only(l.indices)
    StaticArrays.deleteat(obj, i)
end

@inline function insert(obj::StaticArrays.SVector, l::IndexLens, val)
	i = only(l.indices)
    StaticArrays.insert(obj, i, val)
end
