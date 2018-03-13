export @set, @set!, @lens
using MacroTools

"""
    @set assignment

Return a modified copy of deeply nested objects.

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
See also [`@set!`](@ref).
"""
macro set(ex)
    atset_impl(ex)
end

"""
    @set! assignment

Update deeply nested parts of an object. In contrast to `@set`, `@set!`
overwrites variable the variable binding an mutates the original object
if possible.
```jldoctest
julia> using Setfield

julia> struct T;a;b end

julia> t = T(1,2)
T(1, 2)

julia> @set! t.a = 5
T(5, 2)

julia> t
T(5, 2)

julia> @set t.a = 10
T(10, 2)

julia> t
T(5, 2)
```
See also [`@set`](@ref).
"""
macro set!(ex)
    atset_impl(ex, :(EncourageMutation()), true)
end

function parse_obj_lenses(ex)
    if @capture(ex, front_[indices__])
        obj, frontlens = parse_obj_lenses(front)
        index = esc(Expr(:tuple, indices...))
        lens = :(IndexLens($index))
    elseif @capture(ex, front_.property_)
        obj, frontlens = parse_obj_lenses(front)
        lens = :(PropertyLens{$(QuoteNode(property))}())
    else
        obj = esc(ex)
        return obj, ()
    end
    obj, tuple(frontlens..., lens)
end

function parse_obj_lens(ex)
    obj, lenses = parse_obj_lenses(ex)
    lens = Expr(:call, :compose, reverse(lenses)...)
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

function atset_impl(ex::Expr, mut=:(ForbidMutation()), rebind=false)
    @assert ex.head isa Symbol
    @assert length(ex.args) == 2
    ref, val = ex.args
    obj, lens = parse_obj_lens(ref)
    val = esc(val)
    ret = if ex.head == :(=)
        quote
            lens = $lens
            set(lens, $obj, $val, $mut)
        end
    else
        op = UPDATE_OPERATOR_TABLE[ex.head]
        f = :(_UpdateOp($op,$val))
        quote
            modify($f, $lens, $obj, $mut)
        end
    end
    if rebind
        ret = :($obj = $ret)
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
