export Lens, set, get, modify
export @lens
export set, get, modify
export setproperties

import Base: get
using Base: setindex, getproperty

"""
    Lens

A `Lens` allows to access or replace deeply nested parts of complicated objects.

# Example
```jldoctest
julia> using Setfield

julia> struct T;a;b; end

julia> obj = T("AA", "BB")
T("AA", "BB")

julia> lens = @lens _.a
(@lens _.a)

julia> get(obj, lens)
"AA"

julia> set(obj, lens, 2)
T(2, "BB")

julia> obj
T("AA", "BB")

julia> modify(lowercase, obj, lens)
T("aa", "BB")
```

# Interface
Concrete subtypes of `Lens` have to implement
* `set(obj, lens, val)`
* `get(obj, lens)`

These must be pure functions, that satisfy the three lens laws:

```jldoctest; output = false, setup = :(using Setfield; obj = (a="A", b="B"); lens = @lens _.a; val = 2; val1 = 10; val2 = 20)
@assert get(set(obj, lens, val), lens) == val
        # You get what you set.
@assert set(obj, lens, get(obj, lens)) == obj
        # Setting what was already there changes nothing.
@assert set(set(obj, lens, val1), lens, val2) == set(obj, lens, val2)
        # The last set wins.

# output

```

See also [`@lens`](@ref), [`set`](@ref), [`get`](@ref), [`modify`](@ref).
"""
abstract type Lens end

"""
    modify(f, obj, l::Lens)

Replace a deeply nested part `x` of `obj` by `f(x)`. See also [`Lens`](@ref).
"""
function modify end


"""
    get(obj, l::Lens)

Access a deeply nested part of `obj`. See also [`Lens`](@ref).
"""
function get end

"""
    set(obj, l::Lens, val)

Replace a deeply nested part of `obj` by `val`. See also [`Lens`](@ref).
"""
function set end

@inline function modify(f, obj, l::Lens)
    old_val = get(obj, l)
    new_val = f(old_val)
    set(obj, l, new_val)
end

struct IdentityLens <: Lens end
get(obj, ::IdentityLens) = obj
set(obj, ::IdentityLens, val) = val

struct PropertyLens{fieldname} <: Lens end

function get(obj, l::PropertyLens{field}) where {field}
    getproperty(obj, field)
end

@generated function set(obj, l::PropertyLens{field}, val) where {field}
    Expr(:block,
         Expr(:meta, :inline),
        :(setproperties(obj, ($field=val,)))
       )
end

@generated constructor_of(::Type{T}) where T =
    getfield(T.name.module, Symbol(T.name.name))

function assert_hasfields(T, fnames)
    for fname in fnames
        if !(fname in fieldnames(T))
            msg = "$T has no field $fname"
            throw(ArgumentError(msg))
        end
    end
end

"""
    setproperties(obj, patch)

Return a copy of `obj` with attributes updates accoring to `patch`.

# Examples
```jldoctest
julia> using Setfield

julia> struct S;a;b;c; end

julia> s = S(1,2,3)
S(1, 2, 3)

julia> setproperties(s, (a=10,c=4))
S(10, 2, 4)

julia> setproperties((a=1,c=2,b=3), (a=10,c=4))
(a = 10, c = 4, b = 3)
```
"""
function setproperties end

@generated function setproperties(obj, patch)
    assert_hasfields(obj, fieldnames(patch))
    args = map(fieldnames(obj)) do fn
        if fn in fieldnames(patch)
            :(patch.$fn)
        else
            :(obj.$fn)
        end
    end
    Expr(:block,
        Expr(:meta, :inline),
        Expr(:call,:(constructor_of($obj)), args...)
    )
end

@generated function setproperties(obj::NamedTuple, patch)
    # this function is only generated to force the following check
    # at compile time
    assert_hasfields(obj, fieldnames(patch))
    Expr(:block,
        Expr(:meta, :inline),
        :(merge(obj, patch))
    )
end

struct ComposedLens{LO, LI} <: Lens
    outer::LO
    inner::LI
end

compose() = IdentityLens()
compose(l::Lens) = l
compose(::IdentityLens, ::IdentityLens) = IdentityLens()
compose(::IdentityLens, l::Lens) = l
compose(l::Lens, ::IdentityLens) = l
compose(outer::Lens, inner::Lens) = ComposedLens(outer, inner)
function compose(l1::Lens, ls::Lens...)
    # We can build _.a.b.c as (_.a.b).c or _.a.(b.c)
    # The compiler prefers (_.a.b).c
    compose(l1, compose(ls...))
end

"""
    lens₁ ∘ lens₂
    compose([lens₁, [lens₂, [lens₃, ...]]])

Compose lenses `lens₁`, `lens₂`, ..., `lensₙ` to access nested objects.

# Example
```jldoctest
julia> using Setfield

julia> obj = (a = (b = (c = 1,),),);

julia> la = @lens _.a
       lb = @lens _.b
       lc = @lens _.c
       lens = la ∘ lb ∘ lc
(@lens _.a.b.c)

julia> get(obj, lens)
1
```
"""
Base.:∘(l1::Lens, l2::Lens) = compose(l1, l2)

function get(obj, l::ComposedLens)
    inner_obj = get(obj, l.outer)
    get(inner_obj, l.inner)
end

function set(obj,l::ComposedLens, val)
    inner_obj = get(obj, l.outer)
    inner_val = set(inner_obj, l.inner, val)
    set(obj, l.outer, inner_val)
end

struct IndexLens{I <: Tuple} <: Lens
    indices::I
end

Base.@propagate_inbounds function get(obj, l::IndexLens)
    getindex(obj, l.indices...)
end
Base.@propagate_inbounds function set(obj, l::IndexLens, val)
    setindex(obj, val, l.indices...)
end

"""
    ConstIndexLens{I}

Lens with index stored in type parameter.  This is useful for type-stable
[`get`](@ref) and [`set`](@ref) operations on tuples and named tuples.

This lens can be constructed by, e.g., `@lens _[\$1]`.  Complex expression
must be wrapped with `\$(...)` like `@lens _[\$(length(xs))]`.

# Examples
```jldoctest
julia> using Setfield

julia> get((1, 2.0), @lens _[\$1])
1

julia> Base.promote_op(get, typeof.(((1, 2.0), @lens _[\$1]))...)
Int64

julia> Base.promote_op(get, typeof.(((1, 2.0), @lens _[1]))...) !== Int
true
```
"""
struct ConstIndexLens{I} <: Lens end

Base.@propagate_inbounds get(obj, ::ConstIndexLens{I}) where I = obj[I...]

Base.@propagate_inbounds set(obj, ::ConstIndexLens{I}, val) where I =
    setindex(obj, val, I...)

@generated function set(obj::Union{Tuple, NamedTuple},
                        ::ConstIndexLens{I},
                        val) where I
    if length(I) == 1
        n, = I
        args = map(1:length(obj.types)) do i
            i == n ? :val : :(obj[$i])
        end
        quote
            $(Expr(:meta, :inline))
            ($(args...),)
        end
    else
        quote
            throw(ArgumentError($(string(
                "A `Tuple` and `NamedTuple` can only be indexed with one ",
                "integer.  Given: $I"))))
        end
    end
end

Base.@deprecate get(lens::Lens, obj)       get(obj, lens)
Base.@deprecate set(lens::Lens, obj, val)  set(obj, lens, val)
Base.@deprecate modify(f, lens::Lens, obj) modify(f, obj, lens)
