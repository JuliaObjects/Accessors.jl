"""
    getall(obj, optic)

Extract all parts of `obj` that are selected by `optic`.
Returns a flat `Tuple` of values, or an `AbstractVector` if the selected parts contain arrays.

This function is experimental and we might change the precise output container in the future.

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

This function is experimental and might change in the future.

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
getall(obj::Number, ::Elements) = (obj,)
getall(obj::AbstractString, ::Elements) = collect(obj)
getall(obj, ::Properties) = getproperties(obj) |> values
getall(obj, o::If) = o.modify_condition(obj) ? (obj,) : ()
getall(obj, f) = (f(obj),)

function setall(obj, ::Properties, vs)
    names = propertynames(obj)
    setproperties(obj, NamedTuple{names}(NTuple{length(names)}(vs)))
end
setall(obj::NamedTuple{NS}, ::Elements, vs) where {NS} = NamedTuple{NS}(NTuple{length(NS)}(vs))
setall(obj::NTuple{N, Any}, ::Elements, vs) where {N} = (@assert length(vs) == N; NTuple{N}(vs))
setall(obj::AbstractArray, ::Elements, vs::AbstractArray) = (@assert length(obj) == length(vs); reshape(vs, size(obj)))
setall(obj::AbstractArray, ::Elements, vs) = setall(obj, Elements(), collect(vs))
setall(obj, o::If, vs) = error("Not supported")
setall(obj, o, vs) = set(obj, o, only(vs))


# implementations for composite optics

# A straightforward recursive approach doesn't actually infer,
# see https://github.com/JuliaObjects/Accessors.jl/pull/64 and https://github.com/JuliaObjects/Accessors.jl/pull/68.
# Instead, we need to generate separate functions for each recursion level.

function getall(obj, optic::ComposedFunction)
    N = length(decompose(optic))
    _getall(obj, optic, Val(N))
end

function setall(obj, optic::ComposedFunction, vs)
    N = length(decompose(optic))
    vss = to_nested_shape(vs, Val(getall_lengths(obj, optic, Val(N))), Val(N))
    _setall(obj, optic, vss, Val(N))
end


# _getall: the actual workhorse for getall
_getall(_, _, ::Val{N}) where {N} = error("Too many chained optics: $N is not supported for now. See also https://github.com/JuliaObjects/Accessors.jl/pull/64.")
_getall(obj, optic, ::Val{1}) = getall(obj, optic)
for i in 2:10
    @eval function _getall(obj, optic, ::Val{$i})
        _reduce_concat(
            map(getall(obj, optic.inner)) do obj
                _getall(obj, optic.outer, Val($(i-1)))
            end
        )
    end
end

# _setall: the actual workhorse for setall
# takes values as a nested tuple with proper leaf lengths, prepared in setall above
_setall(_, _, _, ::Val{N}) where {N} = error("Too many chained optics: $N is not supported for now. See also https://github.com/JuliaObjects/Accessors.jl/pull/68.")
_setall(obj, optic, vs, ::Val{1}) = setall(obj, optic, vs)
for i in 2:10
    @eval function _setall(obj, optic, vs, ::Val{$i})
        setall(obj, optic.inner, map(getall(obj, optic.inner), vs) do obj, vss
            _setall(obj, optic.outer, vss, Val($(i - 1)))
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

_staticlength(::NTuple{N, <:Any}) where {N} = Val(N)
_staticlength(x::AbstractVector) = length(x)

getall_lengths(obj, optic, ::Val{1}) = _staticlength(getall(obj, optic))
for i in 2:10
    @eval function getall_lengths(obj, optic, ::Val{$i})
        # convert to Tuple: vectors cannot be put into Val
        map(getall(obj, optic.inner) |> Tuple) do o
            getall_lengths(o, optic.outer, Val($(i - 1)))
        end
    end
end

_val(N::Int) = N
_val(::Val{N}) where {N} = N

nestedsum(ls::Union{Int,Val}) = _val(ls)
nestedsum(ls::Tuple) = sum(nestedsum, ls; init=0)

# to_nested_shape() definition uses both @eval and @generated
#
# @eval is needed because the code for different recursion depths should be different for inference,
# not the same method with different parameters.
#
# @generated is used to unpack target lengths from the second argument at compile time to make to_nested_shape() as cheap as possible.
#
# Note: to_nested_shape() only operates on plain Julia types and won't be affected by user lens definition, unlike setall for example.
# That's why it's safe to make it @generated.
to_nested_shape(vs, ::Val{LS}, ::Val{1}) where {LS} = (@assert length(vs) == _val(LS); vs)
for i in 2:10
    @eval @generated function to_nested_shape(vs, ls::Val{LS}, ::Val{$i}) where {LS}
        vi = 1
        subs = map(LS) do lss
            n = nestedsum(lss)
            elems = map(vi:vi+n-1) do j
                :( vs[$j] )
            end
            res = :( to_nested_shape(($(elems...),), $(Val(lss)), $(Val($(i - 1)))) )
            vi += n
            res
        end
        :( ($(subs...),) )
    end
end
