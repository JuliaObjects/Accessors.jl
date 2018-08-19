export Lens, set, get, modify
export @lens
export set, get, modify

import Base: get
using Base: setindex, getproperty

"""
    Lens

A `Lens` allows to access or replace deeply nested parts of complicated objects.

# Example
```jldoctest
julia> using Setfield

julia> struct T;a;b; end

julia> t = T("AA", "BB")
T("AA", "BB")

julia> l = @lens _.a
(@lens _.a)

julia> get(l, t)
"AA"

julia> set(l, t, 2)
T(2, "BB")

julia> t
T("AA", "BB")

julia> modify(lowercase, l, t)
T("aa", "BB")
```

# Interface
Concrete subtypes of `Lens` have to implement
* `set(lens, obj, val)`
* `get(lens, obj)`

These must be pure functions, that satisfy the three lens laws:
* `get(lens, set(lens, obj, val)) == val` (You get what you set.)
* `set(lens, obj, get(lens, obj)) == obj` (Setting what was already there changes nothing.)
* `set(lens, set(lens, obj, val1), val2) == set(lens, obj, val2)` (The last set wins.)

See also [`@lens`](@ref), [`set`](@ref), [`get`](@ref), [`modify`](@ref).
"""
abstract type Lens end

"""
    modify(f, l::Lens, obj)

Replace a deeply nested part `x` of `obj` by `f(x)`. See also [`Lens`](@ref).
"""
function modify end


"""
    get(l::Lens, obj)

Access a deeply nested part of `obj`. See also [`Lens`](@ref).
"""
function get end

"""
    set(l::Lens, obj, val)

Replace a deeply nested part of `obj` by `val`. See also [`Lens`](@ref).
"""
function set end

@inline function modify(f, l::Lens, obj)
    old_val = get(l, obj)
    new_val = f(old_val)
    set(l, obj, new_val)
end

struct IdentityLens <: Lens end
get(::IdentityLens, obj) = obj
set(::IdentityLens, obj, val) = val

struct PropertyLens{fieldname} <: Lens end

function get(l::PropertyLens{field}, obj) where {field}
    getproperty(obj,field)
end

function assert_hasfield(T, field)
    if !(field ∈ fieldnames(T))
        msg = "$T has no field $field"
        throw(ArgumentError(msg))
    end
end

@generated function set(l::PropertyLens{field}, obj, val) where {field}
    :(setproperty(obj, Val{field}(), val))
end

@generated constructor_of(::Type{T}) where T =
    getfield(T.name.module, Symbol(T.name.name))

@generated function setproperty(obj, ::Val{name}, val) where {name}
    T = obj
    assert_hasfield(T, name)
    args = map(fieldnames(T)) do fn
        fn == name ? :val : Expr(:call, :getproperty, :obj, QuoteNode(fn))
    end
    Expr(:block,
        Expr(:meta, :inline),
        Expr(:call, :(constructor_of($T)), args...)
    )
end

@generated function setproperty(nt::NamedTuple, ::Val{name}, val) where {name}
    assert_hasfield(nt, name)
    args = map(fieldnames(nt)) do fn
        if fn == name
            :($fn = val)
        else
            :($fn = nt.$fn)
        end
    end
    Expr(:block,
        Expr(:meta, :inline),
        Expr(:tuple, args...)
    )
end

struct ComposedLens{L1, L2} <: Lens
    lens1::L1
    lens2::L2
end

compose() = IdentityLens()
compose(l::Lens) = l
compose(::IdentityLens, ::IdentityLens) = IdentityLens()
compose(::IdentityLens, l::Lens) = l
compose(l::Lens, ::IdentityLens) = l
compose(l1::Lens, l2 ::Lens) = ComposedLens(l1, l2)
function compose(ls::Lens...)
    # We can build _.a.b.c as (_.a.b).c or _.a.(b.c)
    # The compiler prefers (_.a.b).c
    compose(compose(Base.front(ls)...), last(ls))
end

function get(l::ComposedLens, obj)
    inner_obj = get(l.lens2, obj)
    get(l.lens1, inner_obj)
end

function set(l::ComposedLens, obj, val)
    inner_obj = get(l.lens2, obj)
    inner_val = set(l.lens1, inner_obj, val)
    set(l.lens2, obj, inner_val)
end

struct IndexLens{I <: Tuple} <: Lens
    indices::I
end

get(l::IndexLens, obj) = getindex(obj, l.indices...)
set(l::IndexLens, obj, val) = setindex(obj, val, l.indices...)
