import StaticArrays; const SA = StaticArrays
setindex(a::SA.StaticArray, args...) = Base.setindex(a, args...)

set(arr, ::typeof(SA.normalize), val) = SA.norm(arr) * val
set(arr, ::typeof(SA.norm), val)      = val/SA.norm(arr) * arr # shoud we check val is positive?
