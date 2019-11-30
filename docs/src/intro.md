## Usage

Say we have a deeply nested struct:

```jldoctest spaceship
julia> using StaticArrays;

julia> struct Person
           name::Symbol
           age::Int
       end;

julia> struct SpaceShip
           captain::Person
           velocity::SVector{3, Float64}
           position::SVector{3, Float64}
       end;

julia> s = SpaceShip(Person(:julia, 2009), [0.0, 0.0, 0.0], [0.0, 0.0, 0.0])
SpaceShip(Person(:julia, 2009), [0.0, 0.0, 0.0], [0.0, 0.0, 0.0])
```
Lets update the captains name:
```jldoctest spaceship; filter = r" .*$"
julia> s.captain.name = :JULIA
ERROR: type Person is immutable
```
It's a bit cryptic but what it means that Julia tried very hard to set the field but gave it up since the struct is immutable.  So we have to do:
```jldoctest spaceship
julia> SpaceShip(Person(:JULIA, s.captain.age), s.velocity, s.position)
SpaceShip(Person(:JULIA, 2009), [0.0, 0.0, 0.0], [0.0, 0.0, 0.0])
```
This is messy and things get worse, if the structs are bigger. `Setfields` to the rescue!

```jldoctest spaceship
julia> using Setfield

julia> s = @set s.captain.name = :JULIA
SpaceShip(Person(:JULIA, 2009), [0.0, 0.0, 0.0], [0.0, 0.0, 0.0])

julia> s = @set s.velocity[1] += 999999
SpaceShip(Person(:JULIA, 2009), [999999.0, 0.0, 0.0], [0.0, 0.0, 0.0])

julia> s = @set s.velocity[1] += 1000001
SpaceShip(Person(:JULIA, 2009), [2.0e6, 0.0, 0.0], [0.0, 0.0, 0.0])

julia> @set s.position[2] = 20
SpaceShip(Person(:JULIA, 2009), [2.0e6, 0.0, 0.0], [0.0, 20.0, 0.0])
```

## Under the hood

Under the hood this package implements a simple [lens](https://hackage.haskell.org/package/lens) api.
This api may be useful in its own right and works as follows:

```jldoctest
julia> using Setfield

julia> l = @lens _.a.b
(@lens _.a.b)

julia> struct AB;a;b;end

julia> obj = AB(AB(1,2),3)
AB(AB(1, 2), 3)

julia> set(obj, l, 42)
AB(AB(1, 42), 3)

julia> obj
AB(AB(1, 2), 3)

julia> get(obj, l)
2

julia> modify(x->10x, obj, l)
AB(AB(1, 20), 3)
```

Now the `@set` macro simply provides sugar for creating a `lens` and applying it.
For instance
```julia
@set obj.a.b = 42
```
expands roughly to
```julia
l = @lens _.a.b
set(obj, l, 42)
```
