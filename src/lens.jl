export @lens
export set, modify
export ∘, ⨟
using ConstructionBase
using CompositionsBase
export setproperties
export constructorof

using Base: getproperty

"""
    modify(f, obj, lens)

Replace a deeply nested part `x` of `obj` by `f(x)`.

```jldoctest
julia> using Setfield

julia> obj = (a=1, b=2); lens=@lens _.a; f = x -> "hello \$x";

julia> modify(f, obj, lens)
(a = "hello 1", b = 2)
```
See also [`set`](@ref).
"""
function modify end

"""
    set(lens, obj, val)

Replace a deeply nested part of `obj` by `val`.

```jldoctest
julia> using Setfield

julia> obj = (a=1, b=2); lens=@lens _.a; val = 100;

julia> set(obj, lens, val)
(a = 100, b = 2)
```
See also [`modify`](@ref).
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

@inline function set(obj, lens::ComposedLens, val)
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
