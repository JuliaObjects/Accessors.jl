export @set
"""
    @set assignment

Update deeply nested fields of an immutable object.
```jldoctest
julia> using Setfield

julia> struct T;a;b end

julia> t = T(1,2)
T(1, 2)

julia> @set t.a = 5
T(5, 2)

julia> @set t.a = T(2,2)
T(T(2, 2), 2)

julia> @set t.a.b = 3
T(T(2, 3), 2)
```
"""
macro set(ex)
    atset_impl(ex)
end

function unquote(ex::QuoteNode)
    ex.value
end
function unquote(ex::Expr)
    @assert Meta.isexpr(ex, :quote)
    @assert length(ex.args) == 1
    first(ex.args)
end

function destruct_fieldref(ex)
    @assert Meta.isexpr(ex, Symbol("."))
    @assert length(ex.args) == 2
    a, qb = ex.args
    a, unquote(qb)
end

function destruct_deepfieldref(s::Symbol)
    s, ()
end
    
function destruct_deepfieldref(ex)
    front, last = destruct_fieldref(ex)
    a, middle = destruct_deepfieldref(front)
    a, tuple(middle..., last)
end

parse_obj_lenses(obj::Symbol) = esc(obj), ()

function parse_obj_lenses(ex::Expr)
    @assert ex.head isa Symbol
    @assert length(ex.args) == 2
    if Meta.isexpr(ex, :ref)
        index = esc(ex.args[2])
        lens = :(IndexLens($index))
    elseif Meta.isexpr(ex, :(.))
        field = ex.args[2]
        lens = :(FieldLens{$field}())
    end
    obj, lenses_tail = parse_obj_lenses(ex.args[1])
    lenses = tuple(lens, lenses_tail...)
    obj, lenses
end

function parse_obj_lens(ex::Expr)
    obj, lenses = parse_obj_lenses(ex)
    lens = Expr(:call, :compose, lenses...)
    obj, lens
end

const UPDATE_OPERATOR_TABLE = Dict(
:(+=) => +,
:(-=) => -,
:(*=) => *,
)

struct _UpdateOp{OP,V}
    op::OP
    val::V
end
(u::_UpdateOp)(x) = u.op(x, u.val)

function atset_impl(ex::Expr)
    @assert ex.head isa Symbol
    @assert length(ex.args) == 2
    ref, val = ex.args
    obj, lens = parse_obj_lens(ref)
    val = esc(val)
    ret = if ex.head == :(=)
        quote
            lens = $lens
            $obj = set(lens, $obj, $val)
        end
    else
        op = UPDATE_OPERATOR_TABLE[ex.head]
        f = :(_UpdateOp($op,$val))
        :($obj = update($f, $lens, $obj))
    end
    ret
end
