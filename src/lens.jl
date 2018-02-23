export Lens, set, get, modify

import Base: get, setindex

abstract type MutationPolicy end
struct EncourageMutation <: MutationPolicy end
struct ForbidMutation <: MutationPolicy end

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

set(l::Lens, obj, val) = set(l,obj,val,ForbidMutation())
modify(f,l::Lens, obj) = modify(f, l,obj,ForbidMutation())
@inline function modify(f, l::Lens, obj, m::MutationPolicy)
    old_val = get(l, obj)
    new_val = f(old_val)
    set(l, obj, new_val, m)
end

struct IdentityLens <: Lens end
get(::IdentityLens, obj) = obj
set(::IdentityLens, obj, val,::MutationPolicy) = val

struct PropertyLens{fieldname} <: Lens end
PropertyLens(s::Symbol) = PropertyLens{s}()

function get(l::PropertyLens{field}, obj) where {field}
    getproperty(obj,field)
end

function assert_hasfield(T, field)
    if !(field ∈ fieldnames(T))
        msg = "$T has no field $field"
        throw(ArgumentError(msg))
    end
end


@generated function set(l::PropertyLens{field}, obj, val, m::MutationPolicy) where {field}
    T = obj
    M = m
    if T.mutable && (M == EncourageMutation)
        :(setproperty!(obj, field, val); obj)
    else
        :(setproperty(obj, Val{field}(), val))
    end
end

# function setproperty(obj, name, val)
#     props_new = properties_patched(obj, name, val)
#     @show name
#     ret = constructor_of(typeof(obj))(props_new...)
#     @show ret
#     ret
# end

constructor_of(::Type{T}) where {T} = T

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

function set(l::ComposedLens, obj, val, m::MutationPolicy)
    inner_obj = get(l.lens2, obj)
    inner_val = set(l.lens1, inner_obj, val, m)
    set(l.lens2, obj, inner_val, m)
end

struct IndexLens{I <: Tuple} <: Lens
    indices::I
end

get(l::IndexLens, obj) = getindex(obj, l.indices...)
set(l::IndexLens, obj, val, ::ForbidMutation) = Base.setindex(obj, val, l.indices...)
function set(l::IndexLens, obj, val, ::EncourageMutation)
    if hassetindex!(obj)
        setindex!(obj, val, l.indices...)
    else
        set(l, obj, val, ForbidMutation())
    end
end

hassetindex!(obj::AbstractArray) = true
hassetindex!(obj::Associative) = true
hassetindex!(obj::Tuple) = false

struct Focused{O, L <: Lens}
    object::O
    lens::L
end

modify(f, foc::Focused) = modify(f, foc.lens, foc.object)
set(foc::Focused, val) = set(foc.lens, foc.object, val)
get(foc::Focused) = get(foc.lens, foc.object)
