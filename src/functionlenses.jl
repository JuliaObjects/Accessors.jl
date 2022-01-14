using LinearAlgebra: norm, normalize

set(obj, ::typeof(last), val) = @set obj[lastindex(obj)] = val
set(obj, ::typeof(first), val) = @set obj[firstindex(obj)] = val
delete(obj, ::typeof(last)) = delete(obj, IndexLens((lastindex(obj),)))
delete(obj, ::typeof(first)) = delete(obj, IndexLens((firstindex(obj),)))
insert(obj, ::typeof(last), val) = insert(obj, IndexLens((lastindex(obj) + 1,)), val)
insert(obj, ::typeof(first), val) = insert(obj, IndexLens((firstindex(obj),)), val)

set(obj, ::typeof(identity), val) = val
set(obj, ::typeof(inv), new_inv) = inv(new_inv)

function set(obj, ::typeof(only), val)
    only(obj) # error check
    set(obj, first, val)
end

################################################################################
##### eltype
################################################################################
set(obj::Array, ::typeof(eltype), T::Type) = collect(T, obj)
set(obj::Number, ::typeof(eltype), T::Type) = T(obj)
set(obj::Type{<:Number}, ::typeof(eltype), ::Type{T}) where {T} = T
set(obj::Type{<:Array{<:Any,N}}, ::typeof(eltype), ::Type{T}) where {N,T} = Array{T,N}
set(obj::Type{<:Dict}, ::typeof(eltype), ::Type{Pair{K,V}}) where {K,V} = Dict{K,V}
set(obj::Dict, ::typeof(eltype), ::Type{T}) where {T} = set(typeof(obj), eltype, T)(obj)

set(obj::Dict, lens::Union{typeof(keytype),typeof(valtype)}, T::Type) =
    set(typeof(obj), lens, T)(obj)
set(obj::Type{<:Dict{<:Any,V}}, lens::typeof(keytype), ::Type{K}) where {K,V} = Dict{K,V}
set(obj::Type{<:Dict{K}}, lens::typeof(valtype), ::Type{V}) where {K,V} = Dict{K,V}

################################################################################
##### os
################################################################################
set(path, ::typeof(splitext), (stem, ext))     = string(stem, ext)
set(path, ::typeof(splitdir), (dir, last))     = joinpath(dir, last)
set(path, ::typeof(splitdrive), (drive, rest)) = joinpath(drive, rest)
set(path, ::typeof(splitpath), pieces)         = joinpath(pieces...)
set(path, ::typeof(dirname), new_name)         = @set splitdir(path)[1] = new_name
set(path, ::typeof(basename), new_name)        = @set splitdir(path)[2] = new_name
delete(path, ::typeof(basename)) = dirname(path)
delete(path, ::typeof(dirname)) = basename(path)

################################################################################
##### math
################################################################################
set(x::Real, ::typeof(real), y) = y
set(x,       ::typeof(real), y) = y + im*imag(x)
set(x,       ::typeof(imag), y) = real(x) + im*y

set(arr, ::typeof(normalize), val) = norm(arr) * val
set(arr, ::typeof(norm), val)      = val/norm(arr) * arr # should we check val is positive?
