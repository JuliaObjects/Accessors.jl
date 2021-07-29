import .StaticArrays
Accessors.setindex(a::StaticArrays.StaticArray, args...) = Base.setindex(a, args...)
