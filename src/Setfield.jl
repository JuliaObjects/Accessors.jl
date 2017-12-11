__precompile__(true)
module Setfield

# hack to support static arrays
if Pkg.installed("StaticArrays") != nothing
    import StaticArrays
    Base.setindex(arr::StaticArrays.StaticArray, args...) = StaticArrays.setindex(arr,args...)
    hassetindex!(::StaticArrays.StaticArray) = false
end

include("lens.jl")
include("sugar.jl")
end
