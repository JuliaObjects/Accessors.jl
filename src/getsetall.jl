"""
    getall(obj, optic)

Extract all parts of `obj` that are selected by `optic`.
Returns a flat `Tuple` of values, or an `AbstractVector` if the selected parts contain arrays.

The details of `getall` behavior are consireded experimental: in particular, the precise output container type might change in the future.

See also [`setall`](@ref).


```jldoctest
julia> using Accessors

julia> obj = (a=1, b=(2, 3));

julia> getall(obj, @optic _.a)
(1,)

julia> getall(obj, @optic _ |> Elements() |> last)
(1, 3)
```
"""
function getall end

"""
    setall(obj, optic, values)

Replace a part of `obj` that is selected by `optic` with `values`.
The `values` collection should have the same number of elements as selected by `optic`.

The details of `setall` behavior are consireded experimental: in particular, supported container types for the `values` argument might change in the future.

See also [`getall`](@ref), [`set`](@ref). The former is dual to `setall`:

```jldoctest
julia> using Accessors

julia> obj = (a=1, b=(2, 3));

julia> optic = @optic _ |> Elements() |> last;

julia> getall(obj, optic)
(1, 3)

julia> setall(obj, optic, (4, 5))
(a = 4, b = (2, 5))
```
"""
function setall end

# implementations for individual noncomposite optics

getall(obj::Union{Tuple, AbstractVector}, ::Elements) = obj
getall(obj::Union{NamedTuple}, ::Elements) = values(obj)
getall(obj::AbstractArray, ::Elements) = vec(obj)
getall(obj::AbstractSet, ::Elements) = collect(obj)
getall(obj::AbstractDict, ::Elements) = collect(obj)
getall(obj::Number, ::Elements) = (obj,)
getall(obj::AbstractString, ::Elements) = collect(obj)
getall(obj, ::Elements) = error("Elements() not supported for $(typeof(obj))")
getall(obj, ::Properties) = getproperties(obj) |> values
getall(obj, o::If) = o.modify_condition(obj) ? (obj,) : ()
getall(obj, o) = OpticStyle(o) == SetBased() ? (o(obj),) : error("`getall` not supported for $o")

function setall(obj, ::Properties, vs)
    names = propertynames(obj)
    setproperties(obj, NamedTuple{names}(NTuple{length(names)}(vs)))
end
setall(obj::Tuple, ::Properties, vs) = setproperties(obj, vs)
setall(obj::NamedTuple{NS}, ::Elements, vs) where {NS} = NamedTuple{NS}(NTuple{length(NS)}(vs))
setall(obj::NTuple{N, Any}, ::Elements, vs) where {N} = (@assert length(vs) == N; ntuple(i -> vs[i], Val(N)))
setall(obj::AbstractArray, ::Elements, vs::AbstractArray) = (@assert length(obj) == length(vs); reshape(vs, size(obj)))
setall(obj::AbstractArray, ::Elements, vs) = setall(obj, Elements(), collect(vs))
setall(obj::Set, ::Elements, vs) = Set(vs)
setall(obj::Dict, ::Elements, vs) = Dict(vs)
setall(obj, ::Elements, vs) = error("Elements() not supported for $(typeof(obj))")
function setall(obj, o::If, vs)
    if o.modify_condition(obj)
        @assert o.modify_condition(only(vs))
        only(vs)
    else
        @assert isempty(vs)
        obj
    end
end
setall(obj, o, vs) = OpticStyle(o) == SetBased() ? set(obj, o, only(vs)) : error("`setall` not supported for $o")


# implementations for composite optics

# A straightforward recursive approach doesn't actually infer,
# see https://github.com/JuliaObjects/Accessors.jl/pull/64 and https://github.com/JuliaObjects/Accessors.jl/pull/68.
# Instead, we need to generate separate functions for each recursion level.

getall(obj, optic::ComposedFunction) = _getall(obj, decompose(optic))

function setall(obj, optic::ComposedFunction, vs)
    optics = decompose(optic)
    N = length(optics)
    lengths = getall_lengths(obj, optics)
    
    total_length = _val(nestedsum(lengths))
    length(vs) == total_length || throw(DimensionMismatch("tried to assign $(length(vs)) elements to $total_length destinations"))

    vss = to_nested_shape(vs, lengths, Val(N))
    _setall(obj, optics, vss)
end


# _getall: the actual workhorse for getall
_getall(obj, optics::Tuple{Any}) = getall(obj, only(optics))
for N in [2:10; :(<: Any)]
    @eval function _getall(obj, optics::NTuple{$N,Any})
        _reduce_concat(
            map(getall(obj, last(optics))) do obj
                _getall(obj, Base.front(optics))
            end
        )
    end
end

# _setall: the actual workhorse for setall
# takes values as a nested tuple with proper leaf lengths, prepared in setall above
_setall(obj, optics::Tuple{Any}, vs) = setall(obj, only(optics), vs)
for N in [2:10; :(<: Any)]
    @eval function _setall(obj, optics::NTuple{$N,Any}, vs)
        setall(obj, last(optics), map(getall(obj, last(optics)), vs) do obj, vss
            _setall(obj, Base.front(optics), vss)
        end)
    end
end


# helper functions

_concat(a::Tuple, b::Tuple) = (a..., b...)
_concat(a::Tuple, b::AbstractVector) = vcat(collect(a), b)
_concat(a::AbstractVector, b::Tuple) = vcat(a, collect(b))
_concat(a::AbstractVector, b::AbstractVector) = vcat(a, b)
_reduce_concat(xs::Tuple) = reduce(_concat, xs; init=())
_reduce_concat(xs::AbstractVector) = reduce(append!, xs; init=eltype(eltype(xs))[])
# fast path:
_reduce_concat(xs::Tuple{AbstractVector, Vararg{AbstractVector}}) = reduce(vcat, xs)
_reduce_concat(xs::AbstractVector{<:AbstractVector}) = reduce(vcat, xs)

_staticlength(::NTuple{N, Any}) where {N} = Val(N)
_staticlength(x::AbstractVector) = length(x)

getall_lengths(obj, optics::Tuple{Any}) = _staticlength(getall(obj, only(optics)))
for N in [2:10; :(<: Any)]
    @eval getall_lengths(obj, optics::NTuple{$N,Any}) =
        map(getall(obj, last(optics))) do o
            getall_lengths(o, Base.front(optics))
        end
end

_val(N::Int) = N
_val(::Val{N}) where {N} = N

_valadd(::Val{N}, ::Val{M}) where {N,M} = Val(N+M)
_valadd(n, m) = _val(n) + _val(m)

# nestedsum(): compute the sum of all values in a nested tuple/vector of int/val(int)
nestedsum(ls::Union{Int,Val}) = ls
nestedsum(ls::Tuple) = _valadd(nestedsum(first(ls)), nestedsum(Base.tail(ls)))
nestedsum(ls::Tuple{}) = Val(0)
nestedsum(ls::Vector) = sum(_val ∘ nestedsum, ls)

# splitelems() - split values provided to setall() into two parts: the first N elements, and the rest
# should always be type-stable
# if more collections should be supported, maybe add a fallback method that materializes to vectors; but is it actually needed?
splitelems(vs::NTuple{M,Any}, ::Val{N}) where {N,M} =
    ntuple(j -> vs[j], Val(N)), ntuple(j -> vs[N+j], Val(M-N))
splitelems(vs::Tuple, N) =
    map(i -> vs[i], 1:N), map(i -> vs[i], N+1:length(vs))
# staticarrays can be sliced into compile-time length slices for further efficiency, but this is still type-stable
splitelems(vs::AbstractVector, N) =
    (@view vs[1:_val(N)]), (@view vs[_val(N)+1:end])

_sliceview(v::AbstractVector, i::AbstractVector) = view(v, i)
_sliceview(v::Tuple, i::AbstractVector) = collect(Iterators.map(i -> v[i], i))  # should be regular map(), but it exceed the recursion depth heuristic

# to_nested_shape(): convert a flat tuple/vector of values (as provided to setall) into a nested structure of tuples/vectors following the shape (ls)
# shape is always a (nested) tuple or vector with int or val(int) values, it is generated by getall_lengths()
# values can be any collection passed to setall, here we support tuples and abstractvectors
to_nested_shape(vs, LS, ::Val{1}) = (@assert length(vs) == _val(LS); vs)

for i in 2:10
    @eval to_nested_shape(vs, ls::Tuple{}, ::Val{$i}) = ()

    @eval function to_nested_shape(vs, ls::Tuple, ::Val{$i})
        lss = first(ls)
        n = nestedsum(lss)
        elems, elemstail = splitelems(vs, n)
        reshead = to_nested_shape(elems, lss, $(Val(i - 1)))
        restail = to_nested_shape(elemstail, Base.tail(ls), $(Val(i)))
        return (reshead, restail...)
    end

    @eval function to_nested_shape(vs, ls::Vector, ::Val{$i})
        vi = Ref(1)
        map(ls) do lss
            n = nestedsum(lss) |> _val
            elems = _sliceview(vs, vi[]:vi[]+n-1)
            res = to_nested_shape(elems, lss, $(Val(i - 1)))
            vi[] += n
            res
        end
    end
end
