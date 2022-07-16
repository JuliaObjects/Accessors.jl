getall(obj, ::Elements) = obj |> values
getall(obj, ::Properties) = getproperties(obj) |> values
getall(obj, o::If) = o.modify_condition(obj) ? (obj,) : ()
getall(obj, f) = (f(obj),)


# A recursive implementation of getall doesn't actually infer,
# see https://github.com/JuliaObjects/Accessors.jl/pull/64.
# Instead, we need to generate unrolled code explicitly.
function getall(obj, optic::CO) where {CO <: ComposedFunction}
    N = length(decompose(optic))
    _GetAll{N}()(obj, optic)
end

struct _GetAll{N} end
(::_GetAll{N})(_) where {N} = error("Too many chained optics: $N is not supported for now.")

_concat(a::Tuple, b::Tuple) = (a..., b...)
_concat(a::Tuple, b::AbstractVector) = vcat(collect(a), b)
_concat(a::AbstractVector, b::Tuple) = vcat(a, collect(b))
_concat(a::AbstractVector, b::AbstractVector) = vcat(a, b)
_reduce_concat(xs::Tuple) = reduce(_concat, xs; init=())
_reduce_concat(xs::AbstractVector) = reduce(append!, xs; init=eltype(eltype(xs))[])
# fast path:
_reduce_concat(xs::Tuple{AbstractVector, Vararg{AbstractVector}}) = reduce(vcat, xs)
_reduce_concat(xs::AbstractVector{<:AbstractVector}) = reduce(vcat, xs)

macro _generate_getall(N::Int)
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
    end) |> esc
end

for i in 2:10
    @eval @_generate_getall $i
end
