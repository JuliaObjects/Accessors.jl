# Accessors

[![DocStable](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliaobjects.github.io/Accessors.jl/stable/intro)
[![DocDev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliaobjects.github.io/Accessors.jl/dev/intro)
![CI](https://github.com/JuliaObjects/Accessors.jl/workflows/CI/badge.svg)

The goal of [Accessors.jl](https://github.com/JuliaObjects/Accessors.jl) is to make updating immutable simple.
It is the successor of [Setfield.jl](https://github.com/jw3126/Setfield.jl).

# Usage
Updating deeply nested immutable structs was never easier:
```julia
using Accessors
@set obj.a.b.c = d
```
For more information, see [the documentation](https://juliaobjects.github.io/Accessors.jl/dev/intro/) and/or watch this video:

[![JuliaCon2020 Changing the immutable](https://img.youtube.com/vi/vkAOYeTpLg0/0.jpg)](https://youtu.be/vkAOYeTpLg0 "Changing the immutable")

# Some creative usages of Accessors

* [VegaLite.jl](https://github.com/queryverse/VegaLite.jl) overloads
  `getproperty` and lens API to manipulate JSON-based nested objects.

* [Kaleido.jl](https://github.com/tkf/Kaleido.jl) is a library of
  additional lenses.

* [PhaseSpaceIO.jl](https://github.com/jw3126/PhaseSpaceIO.jl) overloads
  `getproperty` and `setproperties` to get/set values from/in packed bits.
