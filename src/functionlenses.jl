set(::typeof(last), obj, val) = @set obj[lastindex(obj)] = val
set(::typeof(first), obj, val) = @set obj[firstindex(obj)] = val
set(::typeof(identity), obj, val) = val

################################################################################
##### eltype
################################################################################
function set(::typeo(eltype), obj, ::Type{T}) where {T}
    return set_eltype(obj, T)
end

set_eltype(obj::Array,  T::Type) = collect(T, obj)
set_eltype(obj::Number, T::Type) = T(obj)
set_eltype(::Type{<:Number}, ::Type{T}) where {T} = T
set_eltype(::Type{<:Array{<:Any, N}}, ::Type{T}) where {N, T} = Array{T, N}
set_eltype(::Type{<:Dict}, ::Type{Pair{K, V}}) where {K, V} = Dict{K, V}
set_eltype(obj::Dict, ::Type{T}) where {T} = set_eltype(typeof(obj), T)(obj)

set(lens::Union{typeof(keytype), typeof(valtype)}, obj::Dict, T::Type) =
    set(lens, typeof(obj), T)(obj)
set(lens::typeof(keytype), obj::Type{<:Dict{<:Any,V}}, ::Type{K}) where {K, V} =
    Dict{K, V}
set(lens::typeof(valtype), ::Type{<:Dict{K}}, ::Type{V}) where {K, V} =
    Dict{K, V}
