__precompile__(true)
module Setfield

# hack to support static arrays
if Pkg.installed("StaticArrays") != nothing
    import StaticArrays
    Base.setindex(arr::StaticArrays.StaticArray, args...) = StaticArrays.setindex(arr,args...)
    hassetindex!(::StaticArrays.StaticArray) = false
end

if isdefined(Base, :getproperty)
    nothing
else
    const getproperty = getfield
    # the following breaks type stability:
    # @inline getproperty(obj, name) = getfield(obj, name)
end
if isdefined(Base, :setproperty!)
    nothing
else
    const setproperty! = setfield!
    # @inline setproperty!(obj, name, val) = setfield!(obj, name, val)
end

include("lens.jl")
include("sugar.jl")
end
