Base.@propagate_inbounds function setindex(args...)
    Base.setindex(args...)
end

@inline setindex(::Base.RefValue, val) = Ref(val)

Base.@propagate_inbounds function setindex(xs::AbstractArray, v, I_raw...)
    I = to_indices(xs, I_raw)
    T = promote_type(eltype(xs), I isa Tuple{Vararg{Integer}} ? typeof(v) : eltype(v))
    ys = similar(xs, T)
    if eltype(xs) !== Union{}
        copy!(ys, xs)
    end
    ys[I...] = v
    return ys
end

Base.@propagate_inbounds function setindex(d0::AbstractDict, v, k)
    K = promote_type(keytype(d0), typeof(k))
    V = promote_type(valtype(d0), typeof(v))
    d = empty(d0, K, V)
    copy!(d, d0)
    d[k] = v
    return d
end

# may be added to Base in https://github.com/JuliaLang/julia/pull/46453
@inline function setindex(t::Tuple, v, inds::AbstractVector{<:Integer})
    ntuple(length(t)) do i
        ix = findlast(==(i), inds)
        isnothing(ix) ? t[i] : v[ix]
    end
end

@inline setindex(x::NamedTuple{names}, v, i::Int) where {names} = NamedTuple{names}(setindex(values(x), v, i))

@inline setindex(nt::NamedTuple, v, idx::Tuple{Vararg{Symbol}}) = merge(nt, NamedTuple{idx}(v))

@inline setindex(p::Pair, v, idx::Integer) = Pair(setindex(Tuple(p), v, idx)...)

@inline function setindex(x::Number, v, idx::Integer)
    @boundscheck idx == only(eachindex(x)) || throw(BoundsError(x, idx))
    return v
end
@inline setindex(x::Number, v) = v

@inline setindex(s::AbstractString, v::AbstractChar, idx::Integer) = SubString(s, firstindex(s):prevind(s, idx)) * v * SubString(s, nextind(s, idx):lastindex(s))
