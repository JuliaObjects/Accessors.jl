export @set, @lens

"""
    @set assignment

Update deeply nested parts of an immutable object.

# Example
```jldoctest
julia> using Setfield

julia> struct T;a;b end

julia> t = T(1,2)
T(1, 2)

julia> @set t.a = 5
T(5, 2)

julia> t
T(1, 2)

julia> t = @set t.a = T(2,2)
T(T(2, 2), 2)

julia> @set t.a.b = 3
T(T(2, 3), 2)
```
"""
macro set(ex)
    atset_impl(ex)
end

parse_obj_lenses(obj::Symbol) = esc(obj), ()

function parse_obj_lenses(ex::Expr)
    @assert ex.head isa Symbol
    if Meta.isexpr(ex, :ref)
        lens = parse_indexlens(ex)
    elseif Meta.isexpr(ex, :(.))
        lens = parse_fieldlens(ex)
    else
        obj = esc(ex)
        lenses = ()
        return obj, lenses
    end
    obj, lenses_tail = parse_obj_lenses(ex.args[1])
    lenses = tuple(lens, lenses_tail...)
    obj, lenses
end

function parse_indexlens(ex)
    index = map(esc, ex.args[2:end])
    Expr(:call, :IndexLens,
        Expr(:tuple, index...))
end

function parse_fieldlens(ex)
    @assert length(ex.args) == 2
    field = ex.args[2]
    :(PropertyLens{$field}())
end

function parse_obj_lens(ex)
    obj, lenses = parse_obj_lenses(ex)
    lens = Expr(:call, :compose, lenses...)
    obj, lens
end

const UPDATE_OPERATOR_TABLE = Dict(
:(+=) => +,
:(-=) => -,
:(*=) => *,
:(/=) => /,
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
            set(lens, $obj, $val, EncourageMutation())
        end
    else
        op = UPDATE_OPERATOR_TABLE[ex.head]
        f = :(_UpdateOp($op,$val))
        :(modify($f, $lens, $obj, EncourageMutation()))
    end
    ret
end

"""
    @lens

Construct a lens from a field access.

# Example

```jldoctest
julia> using Setfield

julia> struct T;a;b;end

julia> t = T("A1", T(T("A3", "B3"), "B2"))
T("A1", T(T("A3", "B3"), "B2"))

julia> l = @lens _.b.a.b
(@lens _.b.a.b)

julia> get(l, t)
"B3"

julia> set(l, t, 100)
T("A1", T(T("A3", 100), "B2"))

julia> t = ("one", "two")
("one", "two")

julia> set((@lens _[1]), t, "1")
("1", "two")
```

"""
macro lens(ex)
    obj, lens = parse_obj_lens(ex)
    if obj != esc(:_)
        msg = """Cannot parse lens $ex. Lens expressions must start with @lens _"""
        throw(ArgumentError(msg))
    end
    lens
end

macro focus(ex)
    obj, lens = parse_obj_lens(ex)
    quote
        object = $obj
        lens = $lens
        Focused(object, lens)
    end
end

print_application(io::IO, l::PropertyLens{field}) where {field} = print(io, ".", field)
print_application(io::IO, l::IndexLens) = print(io, "[", join(l.indices, ", "), "]")
print_application(io::IO, l::IdentityLens) = print(io, "")

function print_application(io::IO, l::ComposedLens)
    print_application(io, l.lens2)
    print_application(io, l.lens1)
end

function Base.show(io::IO, l::Lens)
    print(io, "(@lens _")
    print_application(io, l)
    print(io, ')')
end

function show_generic(io::IO, args...)
    types = tuple(typeof(io), Base.Iterators.repeated(Any, length(args))...)
    Types = Tuple{types...}
    invoke(show, Types, io, args...)
end
show_generic(args...) = show_generic(STDOUT, args...)
