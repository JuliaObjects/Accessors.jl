export @lens
export set, modify
export ∘, ⨟
using ConstructionBase
using CompositionsBase
export setproperties
export constructorof

using Base: getproperty

TODO = """
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

```jldoctest; output = false, setup = :(using Setfield; (≅ = (==)); obj = (a="A", b="B"); lens = @lens _.a; val = 2; val1 = 10; val2 = 20)
@assert get(set(obj, lens, val), lens) ≅ val
        # You get what you set.
@assert set(obj, lens, get(obj, lens)) ≅ obj
        # Setting what was already there changes nothing.
@assert set(set(obj, lens, val1), lens, val2) ≅ set(obj, lens, val2)
        # The last set wins.

# output

```
Here `≅` is an appropriate notion of equality or an approximation of it. In most contexts
this is simply `==`. But in some contexts it might be `===`, `≈`, `isequal` or something
else instead. For instance `==` does not work in `Float64` context, because
`get(set(obj, lens, NaN), lens) == NaN` can never hold. Instead `isequal` or
`≅(x::Float64, y::Float64) = isequal(x,y) | x ≈ y` are possible alternatives.

See also [`@lens`](@ref), [`set`](@ref), [`get`](@ref), [`modify`](@ref).
"""

"""
    modify(f, lens, obj)

Replace a deeply nested part `x` of `obj` by `f(x)`.
"""
function modify end

"""
    set(lens, obj, val)

Replace a deeply nested part of `obj` by `val`.
"""
function set end

@inline function modify(f, obj, lens)
    set(obj, lens, f(lens(obj)))
end

struct PropertyLens{fieldname} end

function (l::PropertyLens{field})(obj) where {field}
    getproperty(obj, field)
end

@inline function set(obj, l::PropertyLens{field}, val) where {field}
    patch = (;field => val)
    setproperties(obj, patch)
end


"""
    lens₁ ⨟ lens₂

Compose lenses `lens₁`, `lens₂`, ..., `lensₙ` to access nested objects.

# Example
```jldoctest
julia> using Setfield

julia> obj = (a = (b = (c = 1,),),);

julia> la = @lens _.a
       lb = @lens _.b
       lc = @lens _.c
       lens = la ⨟ lb ⨟ lc
(@lens _.a.b.c)

julia> get(obj, lens)
1
```
"""

const ComposedLens{Outer, Inner} = Base.ComposedFunction{Outer, Inner}
outer(o::ComposedLens) = o.f
inner(o::ComposedLens) = o.g

@inline function set(obj, lens::Base.ComposedFunction, val)
    inner_obj = inner(lens)(obj)
    inner_val = set(inner_obj, outer(lens), val)
    set(obj, inner(lens), inner_val)
end

struct IndexLens{I <: Tuple}
    indices::I
end

Base.@propagate_inbounds function (lens::IndexLens)(obj)
    getindex(obj, lens.indices...)
end
Base.@propagate_inbounds function set(obj, lens::IndexLens, val)
    setindex(obj, val, lens.indices...)
end

struct DynamicIndexLens{F}
    f::F
end

Base.@propagate_inbounds (lens::DynamicIndexLens)(obj) = obj[lens.f(obj)...]

Base.@propagate_inbounds set(obj, lens::DynamicIndexLens, val) =
    setindex(obj, val, lens.f(obj)...)

TODO = """
    FunctionLens(f)
    @lens f(_)

Lens with [`get`](@ref) method definition that simply calls `f`.
[`set`](@ref) method for each function `f` must be implemented manually.
Use `methods(set, (Any, Setfield.FunctionLens, Any))` to get a list of
supported functions.

Note that `FunctionLens` flips the order of composition; i.e.,
`(@lens f(_)) ⨟ (@lens g(_)) == @lens g(f(_))`.

# Example
```jldoctest
julia> using Setfield

julia> obj = ((1, 2), (3, 4));

julia> lens = (@lens first(_)) ⨟ (@lens last(_))
(@lens last(first(_)))

julia> get(obj, lens)
2

julia> set(obj, lens, '2')
((1, '2'), (3, 4))
```

# Implementation

To use `myfunction` as a lens, define a `set` method with the following
signature:

```julia
Setfield.set(obj, ::typeof(@lens myfunction(_)), val) = ...
```

`typeof` is used above instead of `FunctionLens` because how actual
type of `@lens myfunction(_)` is implemented is not the part of stable
API.
"""
