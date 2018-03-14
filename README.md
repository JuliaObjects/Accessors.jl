# Setfield

[![Build Status](https://travis-ci.org/jw3126/Setfield.jl.svg?branch=master)](https://travis-ci.org/jw3126/Setfield.jl)
[![codecov.io](https://codecov.io/github/jw3126/Setfield.jl/coverage.svg?branch=master)](http://codecov.io/github/jw3126/Setfield.jl?branch=master)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://jw3126.github.io/Setfield.jl/stable)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://jw3126.github.io/Setfield.jl/latest)

Update deeply nested immutable structs.

## Usage

Say we have a deeply nested struct:
```julia
julia> using StaticArrays

julia> struct Person
           name::Symbol
           birthyear::Int
       end

julia> struct SpaceShip
           captain::Person
           velocity::SVector{3, Float64}
           position::SVector{3, Float64}
       end

julia> s = SpaceShip(Person(:julia, 2009), [0.0, 0.0, 0.0], [0.0, 0.0, 0.0])
SpaceShip(Person(:julia, 2009), [0.0, 0.0, 0.0], [0.0, 0.0, 0.0])
```
Lets update the captains name:
```julia
julia> s.captain.name = "JULIA"
ERROR: type Person is immutable
```
Oh right, the struct is immutable, so we have to do:
```julia
julia> SpaceShip(Person("JULIA", s.captain.age), s.velocity, s.position)
SpaceShip(Person(:JULIA, 2009), [0.0, 0.0, 0.0], [0.0, 0.0, 0.0])
```
This is messy and things get worse, if the structs are bigger. `Setfields` to the rescue!

```julia
julia> using Setfield

julia> s = @set s.captain.name = "JULIA"
SpaceShip(Person(:JULIA, 2009), [0.0, 0.0, 0.0], [0.0, 0.0, 0.0])

julia> s = @set s.velocity[1] += 999999
SpaceShip(Person(:JULIA, 2009), [999999.0, 0.0, 0.0], [0.0, 0.0, 0.0])

julia> s = @set s.velocity[1] += 999999
SpaceShip(Person(:JULIA, 2009), [2.0e6, 0.0, 0.0], [0.0, 0.0, 0.0])

julia> @set s.position[2] = 20
SpaceShip(Person(:JULIA, 2009), [2.0e6, 0.0, 0.0], [0.0, 20.0, 0.0])
```

## Under the hood

Under the hood this package implements a simple [lens](https://hackage.haskell.org/package/lens) api.
This api may be useful in its own rite and works as follows:

```julia
julia> using Setfield
julia> l = @lens _.a.b
(@lens _.a.b)

julia> struct AB;a;b;end

julia> obj = AB(AB(1,2),3)
AB(AB(1, 2), 3)

julia> set(l, obj, 42)
AB(AB(1, 42), 3)

julia> obj
AB(AB(1, 2), 3)

julia> get(l, obj)
2

julia> modify(x->10x,l, obj)
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
set(l, obj, 42)
```

## Alternatives

### [Recostructables.jl](https://github.com/tkf/Reconstructables.jl)

[Reconstructables.jl](https://github.com/tkf/Reconstructables.jl) requires
keyword only constructors, while this package does not. 
Also there are no type stability issues and good performance with this package.
