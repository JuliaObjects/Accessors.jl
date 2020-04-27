set(obj, ::typeof(@lens last(_)), val) = @set obj[lastindex(obj)] = val
set(obj, ::typeof(@lens first(_)), val) = @set obj[firstindex(obj)] = val

################################################################################
##### eltype
################################################################################
function set(obj, ::typeof(@lens eltype(_)), ::Type{T}) where {T}
    return set_eltype(obj, T)
end

set_eltype(obj::Array,  T::Type) = collect(T, obj)
set_eltype(obj::Number, T::Type) = T(obj)
set_eltype(::Type{<:Number}, ::Type{T}) where {T} = T
set_eltype(::Type{<:Array{<:Any, N}}, ::Type{T}) where {N, T} = Array{T, N}
set_eltype(::Type{<:Dict}, ::Type{Pair{K, V}}) where {K, V} = Dict{K, V}
set_eltype(obj::Dict, ::Type{T}) where {T} = set_eltype(typeof(obj), T)(obj)

set(obj::Dict, l::Union{typeof(@lens keytype(_)), typeof(@lens valtype(_))},
    T::Type) = set(typeof(obj), l, T)(obj)
set(::Type{<:Dict{<:Any,V}}, ::typeof(@lens keytype(_)), ::Type{K}) where {K, V} =
    Dict{K, V}
set(::Type{<:Dict{K}}, ::typeof(@lens valtype(_)), ::Type{V}) where {K, V} =
    Dict{K, V}
