# Accessors

[![DocStable](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliaobjects.github.io/Accessors.jl/stable/intro)
[![DocDev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliaobjects.github.io/Accessors.jl/dev/intro)
![CI](https://github.com/JuliaObjects/Accessors.jl/workflows/CI/badge.svg)

The goal of [Accessors.jl](https://github.com/JuliaObjects/Accessors.jl) is to make updating immutable data simple.
It is the successor of [Setfield.jl](https://github.com/jw3126/Setfield.jl).

## Warning

Accessors.jl is currently in an experimental stage. We may introduce breaking changes without clear deprecation path. For a more stable package we recommend [Setfield.jl](https://github.com/jw3126/Setfield.jl).

# Usage
Updating immutable data was never easier:
```julia
using Accessors
@set obj.a.b.c = d
```
For more information, see [the documentation](https://juliaobjects.github.io/Accessors.jl/dev/intro/) and/or watch this video:

[![JuliaCon2020 Changing the immutable](https://img.youtube.com/vi/vkAOYeTpLg0/0.jpg)](https://youtu.be/vkAOYeTpLg0 "Changing the immutable")