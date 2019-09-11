set(obj, ::FunctionLens{last}, val) = @set obj[lastindex(obj)] = val
set(obj, ::FunctionLens{first}, val) = @set obj[firstindex(obj)] = val

set(obj::Array, ::FunctionLens{eltype}, T::Type) = collect(T, obj)
set(::Type{<:Array{<:Any, N}}, ::FunctionLens{eltype}, ::Type{T}) where {N, T} =
    Array{T, N}

set(obj::Dict, l::FunctionLens, T::Type) = set(typeof(obj), l, T)(obj)
set(::Type{<:Dict}, ::FunctionLens{eltype}, ::Type{Pair{K, V}}) where {K, V} =
    Dict{K, V}
set(::Type{<:Dict{<:Any,V}}, ::FunctionLens{keytype}, ::Type{K}) where {K, V} =
    Dict{K, V}
set(::Type{<:Dict{K}}, ::FunctionLens{valtype}, ::Type{V}) where {K, V} =
    Dict{K, V}
