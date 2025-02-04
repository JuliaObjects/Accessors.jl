export PropertyLens, IndexLens
export set, modify, delete, insert, getall, setall
export ∘, opcompose, var"⨟"
export Elements, Recursive, If, Properties
export setproperties
export constructorof
using ConstructionBase
using CompositionsBase
using Base: getproperty
using Base

const EXPERIMENTAL = """This function/type is experimental. It can be changed or deleted at any point without warning"""

"""
    modify(f, obj, optic)

Replace a part `x` of `obj` by `f(x)`. The `optic` argument selects
which part to replace.

```jldoctest
julia> using Accessors

julia> obj = (a=1, b=2); optic=@optic _.a; f = x -> "hello \$x";

julia> modify(f, obj, optic)
(a = "hello 1", b = 2)
```
See also [`set`](@ref).
"""
function modify end

"""
    set(obj, optic, val)

Replace a part according to `optic` of `obj` by `val`.

For a callable `optic`, this law defines the `set` operation: `optic(set(obj, optic, val)) == val` (for an appropriate notion of equality).

```jldoctest
julia> using Accessors

julia> obj = (a=1, b=2); lens=@optic _.a; val = 100;

julia> set(obj, lens, val)
(a = 100, b = 2)

julia> lens = Elements();

julia> set(obj, lens, val)
(a = 100, b = 100)
```
See also [`modify`](@ref).
"""
function set end

"""
    delete(obj, optic)

Delete a part according to `optic` of `obj`.

Note that `optic(delete(obj, optic))` can still have a valid value: for example, when deleting an element from a `Tuple` or `Vector`.

```jldoctest
julia> using Accessors

julia> obj = (a=1, b=2); lens=@optic _.a;

julia> obj_d = delete(obj, lens)
(b = 2,)

julia> lens(obj_d)
ERROR: type NamedTuple has no field a


julia> obj = (1, 2); lens=first;

julia> obj_d = delete(obj, lens)
(2,)

julia> lens(obj_d)
2
```
See also [`set`](@ref), [`insert`](@ref).
"""
function delete end

"""
    insert(obj, optic, val)

Insert a part according to `optic` into `obj` with the value `val`.

For a callable `optic`, this law defines the `insert` operation: `optic(insert(obj, optic, val)) == val` (for an appropriate notion of equality).

```jldoctest
julia> using Accessors

julia> obj = (a=1, b=2); lens=@optic _.c; val = 100;

julia> insert(obj, lens, val)
(a = 1, b = 2, c = 100)
```
See also [`set`](@ref), [`delete`](@ref).
"""
function insert end

"""
    optic₁ ⨟ optic₂

Compose optics `optic₁`, `optic₂`, ..., `opticₙ` to access nested objects.

# Example
```jldoctest
julia> using Accessors

julia> obj = (a = (b = (c = 1,),),);

julia> la = @optic _.a
       lb = @optic _.b
       lc = @optic _.c
       lens = la ⨟ lb ⨟ lc
(@o _.c) ∘ ((@o _.a.b))

julia> lens(obj)
1
```
"""
opcompose

const ComposedOptic{Outer,Inner} = ComposedFunction{Outer,Inner}
outertype(::Type{ComposedOptic{Outer,Inner}}) where {Outer,Inner} = Outer
innertype(::Type{ComposedOptic{Outer,Inner}}) where {Outer,Inner} = Inner

# TODO better name
# also better way to organize traits will
# probably only emerge over time
#
# TODO
# There is an inference regression as of Julia v1.7.0
# if recursion is combined with trait based dispatch
# https://github.com/JuliaLang/julia/issues/43296

abstract type OpticStyle end
struct ModifyBased <: OpticStyle end
struct SetBased <: OpticStyle end
# Base.@pure OpticStyle(obj) = OpticStyle(typeof(obj))
function OpticStyle(optic::T) where {T}
    OpticStyle(T)
end
# defining lenses should be very lightweight
# e.g. only a single `set` implementation
# so we choose this as the default trait
OpticStyle(::Type{T}) where {T} = SetBased()

function OpticStyle(::Type{ComposedOptic{O,I}}) where {O,I}
    composed_optic_style(OpticStyle(O), OpticStyle(I))
end
composed_optic_style(::SetBased, ::SetBased) = SetBased()
composed_optic_style(::ModifyBased, ::SetBased) = ModifyBased()
composed_optic_style(::SetBased, ::ModifyBased) = ModifyBased()
composed_optic_style(::ModifyBased, ::ModifyBased) = ModifyBased()

@inline function set(obj, optic::O, val) where {O}
    _set(obj, optic, val, OpticStyle(O))
end

function _set(obj, optic, val, ::SetBased)
    inv_func = inverse(optic)
    if !(inv_func isa NoInverse)
        return inv_func(val)
    end
    Optic = typeof(optic)
    error("""
    This should be unreachable. You probably need to overload
    `Accessors.set(obj::$(nameof(typeof(obj))), ::$Optic, val::$(nameof(typeof(val))))`
    """)
end

@inline function _set(obj, optic, val, ::ModifyBased)
    modify(Returns(val), obj, optic)
end

@inline function _set(obj, optic::ComposedOptic, val, ::SetBased)
    inner_obj = optic.inner(obj)
    inner_val = set(inner_obj, optic.outer, val)
    set(obj, optic.inner, inner_val)
end

@inline function modify(f, obj, optic::O) where {O}
    _modify(f, obj, optic, OpticStyle(O))
end

function _modify(f, obj, optic, ::ModifyBased)
    Optic = typeof(optic)
    error("""
    This should be unreachable. You probably need to overload:
    `Accessors.modify(f, obj::$(nameof(typeof(obj))), ::$Optic)`
    """)
end

function _modify(f, obj, optic::ComposedOptic, ::ModifyBased)
    otr = optic.outer
    inr = optic.inner
    modify(obj, inr) do o1
        modify(f, o1, otr)
    end
end

@inline function _modify(f, obj, optic, ::SetBased)
    set(obj, optic, f(optic(obj)))
end

function delete(obj, optic::ComposedOptic)
    modify(obj, optic.inner) do inner_obj
        delete(inner_obj, optic.outer)
    end
end

function insert(obj, optic::ComposedOptic, val)
    modify(obj, optic.inner) do inner_obj
        insert(inner_obj, optic.outer, val)
    end
end

"""
    Elements

Access all elements of a collection that implements `map`.
An alias for `Elements()` is available as `∗` (`\\ast`). This optic can also be written as `@o _[∗]`.

```jldoctest
julia> using Accessors

julia> obj = (1,2,3);

julia> set(obj, Elements(), 0)
(0, 0, 0)

julia> modify(x -> 2x, obj, Elements())
(2, 4, 6)
```
"""
struct Elements end
OpticStyle(::Type{<:Elements}) = ModifyBased()

modify(f, obj, ::Elements) = map(f, obj)
# sets and dicts don't support map(), but still have the concept of elements:
modify(f, obj::Set, ::Elements) = Set(f(p) for p in obj)
modify(f, obj::Dict, ::Elements) = Dict(f(p)::Pair for p in obj)

"""
    If(modify_condition)

Restric access to locations for which `modify_condition` holds.

```jldoctest
julia> using Accessors

julia> obj = (1,2,3,4,5,6);

julia> @set obj |> Elements() |> If(iseven) *= 10
(1, 20, 3, 40, 5, 60)
```

$EXPERIMENTAL
"""
struct If{C}
    modify_condition::C
end
OpticStyle(::Type{<:If}) = ModifyBased()

function modify(f, obj, w::If)
    if w.modify_condition(obj)
        f(obj)
    else
        obj
    end
end

# it doesn't seem possible to support delete(If) for collections
delete(obj, o::If) = error("`delete(obj, ::If)` not supported, try using `filter` as an optic instead")

"""
    mapproperties(f, obj)

Construct a copy of `obj`, with each property replaced by
the result of applying `f` to it.

```jldoctest
julia> using Accessors

julia> obj = (a=1, b=2);

julia> Accessors.mapproperties(x -> x+1, obj)
(a = 2, b = 3)
```

# Implementation

This function should not be overloaded directly. Instead both of
* `ConstructionBase.getproperties`
* `ConstructionBase.setproperties`
should be overloaded.
$EXPERIMENTAL
"""
function mapproperties(f, obj)
    nt = getproperties(obj)
    patch = map(f, nt)
    return setproperties(obj, patch)
end

"""
    Properties()

Access all properties of an object.
An alias for `Properties()` is available as `∗ₚ` (`\\ast\\_p`). This optic can also be written as `@o _[∗ₚ]`.

```jldoctest
julia> using Accessors

julia> obj = (a=1, b=2, c=3)
(a = 1, b = 2, c = 3)

julia> set(obj, Properties(), "hi")
(a = "hi", b = "hi", c = "hi")

julia> modify(x -> 2x, obj, Properties())
(a = 2, b = 4, c = 6)
```
Based on [`mapproperties`](@ref).
"""
struct Properties end
OpticStyle(::Type{<:Properties}) = ModifyBased()
modify(f, o, ::Properties) = mapproperties(f, o)

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
"""
struct Recursive{Descent,Optic}
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

"""
    PropertyLens{fieldname}()
    PropertyLens(fieldname)

Construct a lens for accessing a property `fieldname` of an object.

The second constructor may not be type stable when `fieldname` is not a constant.
"""
@inline PropertyLens(fieldname) = PropertyLens{fieldname}()

ConstructionBase.constructorof(::Type{PropertyLens{P}}) where {P} = PropertyLens{P}

function (l::PropertyLens{field})(obj) where {field}
    getproperty(obj, field)
end

# Julia seems to prefers if types stay in the type domain the whole time like NamedTuple{(field,)}, instead of going through the value domain and constprop like (; field => val)
@inline set(obj, l::PropertyLens{field}, val) where {field} = setproperties(obj, NamedTuple{(field,)}((val,)))
@inline delete(obj::NamedTuple, l::PropertyLens{field}) where {field} = Base.structdiff(obj, NamedTuple{(field,)})
@inline insert(obj::NamedTuple{KS}, l::PropertyLens{field}, val) where {KS, field} = NamedTuple{(KS..., field)}((values(obj)..., val))

@inline set(obj::Tuple, l::PropertyLens{field}, val) where {field} = set(obj, IndexLens(field), val)
@inline delete(obj::Tuple, l::PropertyLens{field}) where {field} = delete(obj, IndexLens(field))
@inline insert(obj::Tuple, l::PropertyLens{field}, val) where {field} = insert(obj, IndexLens(field), val)

struct IndexLens{I<:Tuple}
    indices::I
end

"""
    IndexLens(indices::Tuple)
    IndexLens(indices::Integer...)

Construct a lens for accessing an element of an object at `indices` via `[]`.
"""
IndexLens(indices::Integer...) = IndexLens(indices)

Base.@propagate_inbounds function (lens::IndexLens)(obj)
    getindex(obj, lens.indices...)
end
Base.@propagate_inbounds function set(obj, lens::IndexLens, val)
    setindex(obj, val, lens.indices...)
end

@inline function delete(obj::Tuple, l::IndexLens)
    i = only(l.indices)
    (i isa UnitRange || i isa Integer) || throw(ArgumentError("only UnitRange and Integer indices are supported"))
    ntuple(length(obj) - length(i)) do j
        j < minimum(i) ? obj[j] : obj[j + length(i)]
    end
end

@inline function insert(obj::Tuple, l::IndexLens, val)
    i = only(l.indices)
    ntuple(length(obj) + 1) do j
        j == i ? val : obj[j < i ? j : j - 1]
    end
end

@inline delete(obj::AbstractVector, l::IndexLens) = deleteat!(copy(obj), only(l.indices))
@inline delete(obj::AbstractDict, l::IndexLens) = delete!(copy(obj), only(l.indices))
@inline insert(obj::AbstractVector, l::IndexLens, val) = insert!(copy(obj), only(l.indices), val)
@inline insert(obj::AbstractDict, l::IndexLens, val) = setindex(obj, val, only(l.indices))

@inline function insert(obj::AbstractVector, l::IndexLens{<:Tuple{UnitRange}}, val)
    I = only(l.indices)
    length(I) == length(val) || throw(DimensionMismatch("tried to assign $(length(val)) elements to $(length(I)) destinations"))
    res = copy(obj)
    splice!(res, first(I):(first(I)-1), val)
    return res
end

@inline delete(obj::NamedTuple, l::IndexLens{Tuple{Symbol}}) = Base.structdiff(obj, NamedTuple{l.indices})
@inline delete(obj::NamedTuple, l::IndexLens{<:Tuple{Tuple{Vararg{Symbol}}}}) = Base.structdiff(obj, NamedTuple{only(l.indices)})
@inline delete(obj::NamedTuple, l::IndexLens{Tuple{Int}}) = Base.structdiff(obj, NamedTuple{(keys(obj)[only(l.indices)],)})
@inline delete(obj::NamedTuple, l::IndexLens{<:Tuple{Tuple{Vararg{Int}}}}) = Base.structdiff(obj, NamedTuple{map(i -> keys(obj)[i], only(l.indices))})
# resolve method ambiguity:
@inline delete(obj::NamedTuple, l::IndexLens{<:Tuple{Tuple{}}}) = obj
@inline insert(obj::NamedTuple, l::IndexLens{Tuple{Symbol}}, val) = merge(obj, NamedTuple{l.indices}((val,)))
@inline insert(obj::NamedTuple, l::IndexLens{<:Tuple{Tuple{Vararg{Symbol}}}}, vals) = merge(obj, NamedTuple{only(l.indices)}(vals))

@inline delete(obj::CartesianIndex, l::IndexLens{Tuple{Int}}) = delete(obj, l ∘ Tuple)
@inline insert(obj::CartesianIndex, l::IndexLens{Tuple{Int}}, val) = insert(obj, l ∘ Tuple, val)

struct DynamicIndexLens{F}
    f::F
end

Base.@propagate_inbounds function (lens::DynamicIndexLens)(obj)
    return obj[lens.f(obj)...]
end

Base.@propagate_inbounds function set(obj, lens::DynamicIndexLens, val)
    return setindex(obj, val, lens.f(obj)...)
end

@inline function delete(obj, lens::DynamicIndexLens)
    delete(obj, IndexLens(lens.f(obj)))
end


Broadcast.broadcastable(
    o::Union{PropertyLens,IndexLens,DynamicIndexLens,Elements,Properties,If,Recursive}
) = Ref(o)

Base.:(!)(f::Union{PropertyLens,IndexLens,DynamicIndexLens}) = (!) ∘ f


function make_salt(s64::UInt64)::UInt
    # used for faster hashes. See https://github.com/jw3126/Setfield.jl/pull/162
    if UInt === UInt64
        return s64
    else
        return UInt32(s64 >> 32)^UInt32(s64 & 0x00000000ffffffff)
    end
end
const SALT_INDEXLENS = make_salt(0x8b4fd6f97c6aeed6)
Base.hash(l::IndexLens, h::UInt) = hash(l.indices, SALT_INDEXLENS + h)
