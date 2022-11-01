"""
    getall(obj, optic)

Extract all parts of `obj` that are selected by `optic`.
Returns a flat `Tuple` of values, or an `AbstractVector` if the selected parts contain arrays.
This function is experimental and we might change the precise output container in future.


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

getall(obj::Union{Tuple, AbstractVector}, ::Elements) = obj
getall(obj::Union{NamedTuple}, ::Elements) = values(obj)
getall(obj::AbstractArray, ::Elements) = vec(obj)
getall(obj::Number, ::Elements) = (obj,)
getall(obj::AbstractString, ::Elements) = collect(obj)
getall(obj, ::Properties) = getproperties(obj) |> values
getall(obj, o::If) = o.modify_condition(obj) ? (obj,) : ()
getall(obj, f) = (f(obj),)

setall(obj, ::Properties, vs::Tuple) = setproperties(obj, NamedTuple{propertynames(obj)}(vs))
setall(obj::NamedTuple{NS}, ::Elements, vs::Tuple) where {NS} = NamedTuple{NS}(vs)
setall(obj::NTuple{N, Any}, ::Elements, vs::NTuple{N, Any}) where {N} = vs
setall(obj, o::If, vs::Tuple) = error("Not supported")
setall(obj, o, vs::Tuple) = set(obj, o, only(vs))


# A recursive implementation of getall doesn't actually infer,
# see https://github.com/JuliaObjects/Accessors.jl/pull/64.
# Instead, we need to generate unrolled code explicitly.
function getall(obj, optic::ComposedFunction)
    N = length(decompose(optic))
    _GetAll{N}()(obj, optic)
end

function setall(obj, optic::ComposedFunction, vs::Tuple)
    N = length(decompose(optic))
    _SetAll{N}()(obj, optic, vs)
end


struct _GetAll{N} end
(::_GetAll{N})(_) where {N} = error("Too many chained optics: $N is not supported for now. See also https://github.com/JuliaObjects/Accessors.jl/pull/64.")

_concat(a::Tuple, b::Tuple) = (a..., b...)
_concat(a::Tuple, b::AbstractVector) = vcat(collect(a), b)
_concat(a::AbstractVector, b::Tuple) = vcat(a, collect(b))
_concat(a::AbstractVector, b::AbstractVector) = vcat(a, b)
_reduce_concat(xs::Tuple) = reduce(_concat, xs; init=())
_reduce_concat(xs::AbstractVector) = reduce(append!, xs; init=eltype(eltype(xs))[])
# fast path:
_reduce_concat(xs::Tuple{AbstractVector, Vararg{AbstractVector}}) = reduce(vcat, xs)
_reduce_concat(xs::AbstractVector{<:AbstractVector}) = reduce(vcat, xs)

function _generate_getall(N::Int)
    syms = [Symbol(:f_, i) for i in 1:N]

    expr = :( getall(obj, $(syms[end])) )
    for s in syms[1:end - 1] |> reverse
        expr = :(
            _reduce_concat(
                map(getall(obj, $(s))) do obj
                    $expr
                end
            )
        )
    end

    :(function (::_GetAll{$N})(obj, optic)
        ($(syms...),) = deopcompose(optic)
        $expr
    end)
end

for i in 2:10
    eval(_generate_getall(i))
end


_staticlength(::Number) = Val(1)
_staticlength(::NTuple{N, <:Any}) where {N} = Val(N)
# _staticlength(x::Vector) = length(x)

_val(::Val{N}) where {N} = N
_val(::Type{Val{N}}) where {N} = N

_staticsum(f, x) = sum(_val ∘ f, x) |> Val

getall_lengths(obj, optic) = _staticlength(getall(obj, optic))
function getall_lengths(obj, optic::ComposedFunction, ::Val{2})
    map(getall(obj, optic.inner)) do o
        getall_lengths(o, optic.outer)
    end
end
function getall_lengths(obj, optic::ComposedFunction, ::Val{3})
    map(getall(obj, optic.inner)) do o
        getall_lengths(o, optic.outer, Val(2))
    end
end
function getall_lengths(obj, optic::ComposedFunction, ::Val{4})
    map(getall(obj, optic.inner)) do o
        getall_lengths(o, optic.outer, Val(3))
    end
end


nestedsum(ls::Type{L}) where {L <: Val} = L
nestedsum(ls::Type{LS}) where {LS <: Tuple} = _staticsum(nestedsum, LS.parameters)


to_nested_shape(vs, ls::Type{LS}) where {LS <: Val} = (@assert length(vs) == _val(LS); vs)
to_nested_shape(vs, ls::LS, VN) where {LS <: Tuple} = to_nested_shape(vs, typeof(ls), VN)
@generated function to_nested_shape(vs, ls::Type{LS}, ::Val{2}) where {LS <: Tuple}
    i = 1
    subs = map(LS.parameters) do lss
        n = nestedsum(lss)
        elems = map(i:i+_val(n)-1) do j
            :( vs[$j] )
        end
        res = :( to_nested_shape(($(elems...),), $lss) )
        i = i + _val(n)
        res
    end
    :( ($(subs...),) )
end
@generated function to_nested_shape(vs, ls::Type{LS}, ::Val{3}) where {LS <: Tuple}
    i = 1
    subs = map(LS.parameters) do lss
        n = nestedsum(lss)
        elems = map(i:i+_val(n)-1) do j
            :( vs[$j] )
        end
        res = :( to_nested_shape(($(elems...),), $lss, Val(2)) )
        i = i + _val(n)
        res
    end
    :( ($(subs...),) )
end
@generated function to_nested_shape(vs, ls::Type{LS}, ::Val{4}) where {LS <: Tuple}
    i = 1
    subs = map(LS.parameters) do lss
        n = nestedsum(lss)
        elems = map(i:i+_val(n)-1) do j
            :( vs[$j] )
        end
        res = :( to_nested_shape(($(elems...),), $lss, Val(3)) )
        i = i + _val(n)
        res
    end
    :( ($(subs...),) )
end


_setall(obj, optic, vs) = setall(obj, optic, vs)
_setall(obj, optic::ComposedFunction, vs, ::Val{2}) =
    setall(obj, optic.inner, map(getall(obj, optic.inner), vs) do obj, vss
        _setall(obj, optic.outer, vss)
    end)
_setall(obj, optic::ComposedFunction, vs, ::Val{3}) =
    setall(obj, optic.inner, map(getall(obj, optic.inner), vs) do obj, vss
        _setall(obj, optic.outer, vss, Val(2))
    end)
_setall(obj, optic::ComposedFunction, vs, ::Val{4}) =
    setall(obj, optic.inner, map(getall(obj, optic.inner), vs) do obj, vss
        _setall(obj, optic.outer, vss, Val(3))
    end)


struct _SetAll{N} end

function (::_SetAll{N})(obj, optic, vs) where {N}
    vss = to_nested_shape(vs, getall_lengths(obj, optic, Val(N)), Val(N))
    # @info "" vs getall_lengths(obj, optic, Val(N)) vss
    _setall(obj, optic, vss, Val(N))
end

# split a into two parts: b-sized front and remaining
_split_n(a::NTuple{Na, Any}, b::NTuple{Nb, Any}) where {Na, Nb} = ntuple(i -> a[i], Nb), ntuple(i -> a[Nb + i], Na - Nb)

# split vs into parts sized according to getall(o, f)
_split_getall(ins_old, f, vs) = foldl(ins_old; init=((), vs)) do (acc, vs_), o
    vs_cur, vs_rest = _split_n(vs_, getall(o, f))
    (acc..., vs_cur), vs_rest
end |> first
