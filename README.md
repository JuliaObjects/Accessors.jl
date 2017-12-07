# Setfield

[![Build Status](https://travis-ci.org/jw3126/Setfield.jl.svg?branch=master)](https://travis-ci.org/jw3126/Setfield.jl)
[![codecov.io](https://codecov.io/github/jw3126/Setfield.jl/coverage.svg?branch=master)](http://codecov.io/github/jw3126/Setfield.jl?branch=master)

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

julia> @set s.captain.name = "JULIA"
SpaceShip(Person(:JULIA, 2009), [0.0, 0.0, 0.0], [0.0, 0.0, 0.0])

julia> @set s.velocity[1] += 999999
SpaceShip(Person(:JULIA, 2009), [999999.0, 0.0, 0.0], [0.0, 0.0, 0.0])

julia> @set s.velocity[1] += 999999
SpaceShip(Person(:JULIA, 2009), [2.0e6, 0.0, 0.0], [0.0, 0.0, 0.0])

julia> @set s.position[2] = 20
SpaceShip(Person(:JULIA, 2009), [2.0e6, 0.0, 0.0], [0.0, 20.0, 0.0])
```
