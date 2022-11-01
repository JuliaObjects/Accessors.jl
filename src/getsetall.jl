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

function setall(obj, optic::ComposedFunction, vs)
    N = length(decompose(optic))
    vss = to_nested_shape(vs, typeof(getall_lengths(obj, optic, Val(N))), Val(N))
    _setall(obj, optic, vss, Val(N))
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
# _staticlength(x::AbstractVector) = length(x)

_val(::Val{N}) where {N} = N
_val(::Type{Val{N}}) where {N} = N

_staticsum(f, x) = sum(_val ∘ f, x) |> Val

getall_lengths(obj, optic, ::Val{1}) = _staticlength(getall(obj, optic))
for i in 2:10
    @eval function getall_lengths(obj, optic::ComposedFunction, ::Val{$i})
        map(getall(obj, optic.inner)) do o
            getall_lengths(o, optic.outer, Val($(i - 1)))
        end
    end
end


nestedsum(ls::Type{L}) where {L <: Val} = L
nestedsum(ls::Type{LS}) where {LS <: Tuple} = _staticsum(nestedsum, LS.parameters)


to_nested_shape(vs, ls::Type{LS}, ::Val{1}) where {LS <: Val} = (@assert length(vs) == _val(LS); vs)
for i in 2:10
    @eval @generated function to_nested_shape(vs, ls::Type{LS}, ::Val{$i}) where {LS <: Tuple}
        vi = 1
        subs = map(LS.parameters) do lss
            n = nestedsum(lss)
            elems = map(vi:vi+_val(n)-1) do j
                :( vs[$j] )
            end
            res = :( to_nested_shape(($(elems...),), $lss, $(Val($(i - 1)))) )
            vi = vi + _val(n)
            res
        end
        :( ($(subs...),) )
    end
end


_setall(obj, optic, vs, ::Val{1}) = setall(obj, optic, vs)
for i in 2:10
    @eval function _setall(obj, optic::ComposedFunction, vs, ::Val{$i})
        setall(obj, optic.inner, map(getall(obj, optic.inner), vs) do obj, vss
            _setall(obj, optic.outer, vss, Val($(i - 1)))
        end)
    end
end

