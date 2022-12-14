# # Extending `@set` and `@optic`
# This code demonstrates how to extend the `@set` and `@optic` mechanism with custom
# lenses.
# As a demo, we want to implement `@mylens!` and `@myreset`, which work much like
# `@optic` and `@set`, but mutate objects instead of returning modified copies.

using Accessors
using Accessors: IndexLens, PropertyLens, ComposedOptic

struct Lens!{L}
    pure::L
end

(l::Lens!)(o) = l.pure(o)
function Accessors.set(o, l::Lens!{<: ComposedOptic}, val)
    o_inner = l.pure.inner(o)
    set(o_inner, Lens!(l.pure.outer), val)
end
function Accessors.set(o, l::Lens!{PropertyLens{prop}}, val) where {prop}
    setproperty!(o, prop, val)
    o
end
function Accessors.set(o, l::Lens!{<:IndexLens}, val)
    o[l.pure.indices...] = val
    o
end

# Now this implements the kind of `lens` the new macros should use.
# Of course there are more variants like `Lens!(<:DynamicIndexLens)`, for which we might
# want to overload `set`, but lets ignore that. Instead we want to check, that everything works so far:

using Test
mutable struct M
    a
    b
end

o = M(1,2)
l = Lens!(@optic _.b)
set(o, l, 20)
@test o.b == 20

l = Lens!(@optic _.foo[1])
o = (foo=[1,2,3], bar=:bar)
set(o, l, 100)
@test o == (foo=[100,2,3], bar=:bar)

# Now we can implement the syntax macros

using Accessors: setmacro, opticmacro, modifymacro

macro myreset(ex)
    setmacro(Lens!, ex)
end

macro mylens!(ex)
    opticmacro(Lens!, ex)
end

macro mymodify!(f, ex)
    modifymacro(Lens!, f, ex)
end

o = M(1,2)
@myreset o.a = :hi
@myreset o.b += 98
@test o.a == :hi
@test o.b == 100

o = M(1,3)
@mymodify!(x -> x+1, o.a)
@test o.a === 2
@test o.b === 3

deep = [[[[1]]]]
@myreset deep[1][1][1][1] = 2
@test deep[1][1][1][1] === 2

l = @mylens! _.foo[1]
o = (foo=[1,2,3], bar=:bar)
set(o, l, 100)
@test o == (foo=[100,2,3], bar=:bar)

# Everything works, we can do arbitrary nesting and also use `+=` syntax etc.
