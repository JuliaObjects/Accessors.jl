export @lens
export set, modify
export ∘, ⨟
export Elements, Properties, Recursive
export setproperties
export constructorof
using ConstructionBase
using CompositionsBase
using Base: getproperty

const EXPERIMENTAL = """This function/method/type is experimental. It can be changed or deleted at any point without warning"""

"""
    modify(f, obj, lens)

Replace a deeply nested part `x` of `obj` by `f(x)`.

```jldoctest
julia> using Accessors

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
julia> using Accessors

julia> obj = (a=1, b=2); lens=@lens _.a; val = 100;

julia> set(obj, lens, val)
(a = 100, b = 2)
```
See also [`modify`](@ref).
"""
function set end

"""
    lens₁ ⨟ lens₂

Compose lenses `lens₁`, `lens₂`, ..., `lensₙ` to access nested objects.

# Example
```jldoctest
julia> using Accessors

julia> obj = (a = (b = (c = 1,),),);

julia> la = @lens _.a
       lb = @lens _.b
       lc = @lens _.c
       lens = la ⨟ lb ⨟ lc
(@lens _.c) ∘ (@lens _.b) ∘ (@lens _.a)

julia> lens(obj)
1
```
"""
⨟

function mapproperties(f, obj)
    # TODO move this helper elsewhere?
    pnames = propertynames(obj)
    if isempty(pnames)
        return obj
    else
        ctor = constructorof(typeof(obj))
        new_props = map(pnames) do p
            f(getproperty(obj, p))
        end
        return ctor(new_props...)
    end
end

const ComposedLens{Outer, Inner} = Base.ComposedFunction{Outer, Inner}
outer(o::ComposedLens) = o.f
inner(o::ComposedLens) = o.g
outertype(::Type{ComposedLens{Outer, Inner}}) where {Outer, Inner} = Outer
innertype(::Type{ComposedLens{Outer, Inner}}) where {Outer, Inner} = Inner

# TODO better name
# also better way to organize traits will
# probably only emerge over time
abstract type OpticStyle end
struct ModifyBased end
struct SetBased end
OpticStyle(obj) = OpticStyle(typeof(obj))
# defining lenses should be very lightweight
# e.g. only a single `set` implementation
# so we choose this as the default trait
OpticStyle(::Type{T}) where {T} = SetBased()


function OpticStyle(::Type{ComposedLens{O,I}}) where {O,I}
    composed_optic_style(OpticStyle(O), OpticStyle(I))
end
composed_optic_style(::SetBased, ::SetBased) = SetBased()
composed_optic_style(::ModifyBased, ::SetBased) = ModifyBased()
composed_optic_style(::SetBased, ::ModifyBased) = ModifyBased()
composed_optic_style(::ModifyBased, ::ModifyBased) = ModifyBased()

@inline function set(obj, optic, val)
    _set(obj, optic, val, OpticStyle(optic))
end

function _set(obj, optic, val, ::SetBased)
    Optic = typeof(optic)
    error("""
    This should be unreachable. You probably need to overload
    `Accessors.set(obj, ::$Optic, val)
    """
   )
end

struct Constant{V}
    value::V
end
(o::Constant)(x) = o.value

@inline function _set(obj, optic, val, ::ModifyBased)
    modify(Constant(val), obj, optic)
end

@inline function _set(obj, optic::ComposedLens, val, ::SetBased)
    inner_obj = inner(optic)(obj)
    inner_val = set(inner_obj, outer(optic), val)
    set(obj, inner(optic), inner_val)
end

@inline function modify(f, obj, optic)
    _modify(f, obj, optic, OpticStyle(optic))
end

function _modify(f, obj, optic, ::ModifyBased)
    Optic = typeof(optic)
    error("""
          This should be unreachable. You probably need to overload:
          `Accessors.modify(f, obj, ::$Optic)`
          """)
end

function _modify(f, obj, optic::ComposedLens, ::ModifyBased)
    otr = outer(optic)
    inr = inner(optic)
    modify(obj, inr) do o1
        modify(f, o1, otr)
    end
end

function _modify(f, obj, optic, ::SetBased)
    set(obj, optic, f(optic(obj)))
end

"""
    Properties()

Access all properties of an objects.

```jldoctest
julia> using Accessors

julia> obj = (a=1, b=2, c=3)
(a = 1, b = 2, c = 3)

julia> set(obj, Properties(), "hi")
(a = "hi", b = "hi", c = "hi")

julia> modify(x -> 2x, obj, Properties())
(a = 2, b = 4, c = 6)
```
Based on [`Accessors.mapproperties`](@ref).

$EXPERIMENTAL
"""
struct Properties end
OpticStyle(::Type{Properties}) = ModifyBased()

function modify(f, o, ::Properties)
    mapproperties(f, o)
end

"""
    Elements

Access all elements of a collection that implements [`Base.map`](@ref).
```jldoctest
julia> using Accessors

julia> obj = [1,2,3]
3-element Vector{Int64}:
 1
 2
 3

julia> set(obj, Elements(), 0)
3-element Vector{Int64}:
 0
 0
 0

julia> modify(x -> 2x, obj, Elements())
3-element Vector{Int64}:
 2
 4
 6
```
$EXPERIMENTAL
"""
struct Elements end
OpticStyle(::Type{Elements}) = ModifyBased()

function modify(f, obj, ::Elements)
    map(f, obj)
end

"""
    Recursive(descent_condition, optic)

Apply `optic` recursively as long as `descent_condition` holds.
```jldoctest
julia> using Accessors

julia> obj = (a=missing, b=1, c=(d=missing, e=(f=missing, g=2)))
(a = missing, b = 1, c = (d = missing, e = (f = missing, g = 2)))

julia> set(obj, Recursive(!ismissing, Properties()), 100)
(a = 100, b = 1, c = (d = 100, e = (f = 100, g = 2)))

julia> obj = (1,2,(3,(4,5),6))
(1, 2, (3, (4, 5), 6))

julia> modify(x -> 100x, obj, Recursive(x -> (x isa Tuple), Elements()))
(100, 200, (300, (400, 500), 600))
```

$EXPERIMENTAL
"""
struct Recursive{Descent, Optic}
    descent_condition::Descent
    optic::Optic
end
OpticStyle(::Type{Recursive{D,O}}) where {D,O} = ModifyBased() # Is this a good idea?

function _modify(f, obj, r::Recursive, ::ModifyBased)
    modify(obj, r.optic) do o
        if r.descent_condition(o)
            modify(f, o, r)
        else
            f(o)
        end
    end
end

################################################################################
##### Lenses
################################################################################
struct PropertyLens{fieldname} end

function (l::PropertyLens{field})(obj) where {field}
    getproperty(obj, field)
end

@inline function set(obj, l::PropertyLens{field}, val) where {field}
    patch = (;field => val)
    setproperties(obj, patch)
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
