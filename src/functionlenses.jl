set(obj, ::typeof(last), val) = @set obj[lastindex(obj)] = val
set(obj, ::typeof(first), val) = @set obj[firstindex(obj)] = val
set(obj, ::typeof(identity), val) = val

################################################################################
##### eltype
################################################################################
set(obj::Array, ::typeof(eltype), T::Type) = collect(T, obj)
set(obj::Number, ::typeof(eltype), T::Type) = T(obj)
set(obj::Type{<:Number}, ::typeof(eltype), ::Type{T}) where {T} = T
set(obj::Type{<:Array{<:Any, N}}, ::typeof(eltype), ::Type{T}) where {N, T} = Array{T, N}
set(obj::Type{<:Dict}, ::typeof(eltype), ::Type{Pair{K, V}}) where {K, V} = Dict{K, V}
set(obj::Dict, ::typeof(eltype), ::Type{T}) where {T} = set(typeof(obj), eltype, T)(obj)

set(obj::Dict, lens::Union{typeof(keytype), typeof(valtype)}, T::Type) =
    set(typeof(obj), lens, T)(obj)
set(obj::Type{<:Dict{<:Any,V}}, lens::typeof(keytype), ::Type{K}) where {K, V} =
    Dict{K, V}
set(obj::Type{<:Dict{K}}, lens::typeof(valtype), ::Type{V}) where {K, V} =
    Dict{K, V}
