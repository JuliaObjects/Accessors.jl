# Lenses

Accessors.jl is build around so called lenses. A Lens allows to access or replace deeply nested parts of complicated objects.

# Example

```jldoctest
julia> using Accessors

julia> struct T;a;b; end

julia> obj = T("AA", "BB");

julia> lens = @optic _.a
(@o _.a)

julia> lens(obj)
"AA"

julia> set(obj, lens, 2)
T(2, "BB")

julia> obj # the object was not mutated, instead an updated copy was created
T("AA", "BB")

julia> modify(lowercase, obj, lens)
T("aa", "BB")
```

Lenses can also be constructed directly and composed with [`opcompose`](@ref), `⨟`, or `∘` (note reverse order).

```jldoctest
julia> using Accessors

julia> v = (a = 1:3, )
(a = 1:3,)

julia> l = opcompose(PropertyLens(:a), IndexLens(1))
(@o _.a[1])

julia> l ≡ @optic _.a[1]   # equivalent to macro form
true

julia> l(v)
1

julia> set(v, l, 3)
(a = [3, 2, 3],)
```

# Interface

Implementing lenses is straight forward. They can be of any type and just need to implement the following interface:
* `Accessors.set(obj, lens, val)`
* `lens(obj)`

These must be pure functions, that satisfy the three lens laws:

```jldoctest; output = false, setup = :(using Accessors; (≅ = (==)); obj = (a="A", b="B"); lens = @optic _.a; val = 2; val1 = 10; val2 = 20)
@assert lens(set(obj, lens, val)) ≅ val
        # You get what you set.
@assert set(obj, lens, lens(obj)) ≅ obj
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

See also [`@optic`](@ref), [`set`](@ref), [`modify`](@ref).
