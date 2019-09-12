set(obj, ::typeof(@lens last(_)), val) = @set obj[lastindex(obj)] = val
set(obj, ::typeof(@lens first(_)), val) = @set obj[firstindex(obj)] = val

set(obj::Array, ::typeof(@lens eltype(_)), T::Type) = collect(T, obj)
set(::Type{<:Array{<:Any, N}}, ::typeof(@lens eltype(_)), ::Type{T}) where {N, T} =
    Array{T, N}

set(obj::Dict, l::FunctionLens, T::Type) = set(typeof(obj), l, T)(obj)
set(::Type{<:Dict}, ::typeof(@lens eltype(_)), ::Type{Pair{K, V}}) where {K, V} =
    Dict{K, V}
set(::Type{<:Dict{<:Any,V}}, ::typeof(@lens keytype(_)), ::Type{K}) where {K, V} =
    Dict{K, V}
set(::Type{<:Dict{K}}, ::typeof(@lens valtype(_)), ::Type{V}) where {K, V} =
    Dict{K, V}
