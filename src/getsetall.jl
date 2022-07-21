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



struct _SetAll{N} end

# don't review SetAll{2} and {3}
function (::_SetAll{2})(obj, optic, vs)
    (f1, f2) = deopcompose(optic)

    ins_old = getall(obj, f1)
    vss = reduce(ins_old; init=((), vs)) do (acc, vs), o
        vs_cur, vs_rest = _split_n(vs, getall(o, f2))
        (acc..., vs_cur), vs_rest
    end |> first
    ins = map(ins_old, vss) do o, vs_cur
        setall(o, f2, vs_cur)
    end
    setall(obj, f1, ins)
end

function (::_SetAll{3})(obj, optic, vs)
    (f1, f2, f3) = deopcompose(optic)

    ins_old_1 = getall(obj, f1)
    vss_1 = _split_getall(ins_old_1, f3 ∘ f2, vs)
    ins_1 = map(ins_old_1, vss_1) do o, vs_cur
        ins_old_2 = getall(o, f2)
        vss_2 = _split_getall(ins_old_2, f3, vs_cur)
        ins_2 = map(ins_old_2, vss_2) do o, vs_cur
            setall(o, f3, vs_cur)
        end
        setall(o, f2, ins_2)
    end
    setall(obj, f1, ins_1)
end

# only review SetAll{4} and helpers below
function (::_SetAll{4})(o, optic, vs)
    (f1, f2, f3, f4) = deopcompose(optic)

    ins_old_1 = getall(o, f1)
    vss_1 = _split_getall(ins_old_1, f4 ∘ f3 ∘ f2, vs)
    ins_1 = map(ins_old_1, vss_1) do o, vs_cur
        ins_old_2 = getall(o, f2)
        vss_2 = _split_getall(ins_old_2, f4 ∘ f3, vs_cur)
        ins_2 = map(ins_old_2, vss_2) do o, vs_cur
            ins_old_3 = getall(o, f3)
            vss_3 = _split_getall(ins_old_3, f4, vs_cur)
            ins_3 = map(ins_old_3, vss_3) do o, vs_cur
                setall(o, f4, vs_cur)
            end
            setall(o, f3, ins_3)
        end
        setall(o, f2, ins_2)
    end
    setall(o, f1, ins_1)
end

# split a into two parts: b-sized front and remaining
_split_n(a::NTuple{Na, Any}, b::NTuple{Nb, Any}) where {Na, Nb} = ntuple(i -> a[i], Nb), ntuple(i -> a[Nb + i], Na - Nb)

# split vs into parts sized according to getall(o, f)
_split_getall(ins_old, f, vs) = foldl(ins_old; init=((), vs)) do (acc, vs_), o
    vs_cur, vs_rest = _split_n(vs_, getall(o, f))
    (acc..., vs_cur), vs_rest
end |> first
