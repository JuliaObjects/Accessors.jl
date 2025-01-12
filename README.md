# Accessors

[![DocStable](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliaobjects.github.io/Accessors.jl/stable/)
[![DocDev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliaobjects.github.io/Accessors.jl/dev/)
![CI](https://github.com/JuliaObjects/Accessors.jl/workflows/CI/badge.svg)

The goal of [Accessors.jl](https://github.com/JuliaObjects/Accessors.jl) is to make updating immutable data simple.
It is the successor of [Setfield.jl](https://github.com/jw3126/Setfield.jl).

# Usage
Say you have some immutable data structure, such as a `NamedTuple`:
```julia
julia> nt = (a=1, b=2)
(a = 1, b = 2)

```
If you try something like `nt.b=3`, it will throw an error. But 
using Accessors, we can change it anyways:
```julia
julia> using Accessors

julia> @set nt.b=3
(a = 1, b = 3)
```

Note that this only returns an updated copy of `nt`, and *does not overwrite or mutate* the 
value bound to `nt`:
```julia
julia> nt
(a = 1, b = 2)
```

To overwrite the old definition, we can rebind `nt` to the new version:
```julia
julia> nt = @set nt.b=3
(a = 1, b = 3)

julia> nt
(a = 1, b = 3)
```

As this is a common use case, the convenience macro `@reset` rebinds the variable (`nt`) to the updated version:
```julia
julia> @reset nt.b=4
(a = 1, b = 4)

julia> nt
(a = 1, b = 4)
```

For more detail, see [this tutorial](https://juliaobjects.github.io/Accessors.jl/stable/getting_started/) and/or watch this video:

[![JuliaCon2020 Changing the immutable](https://img.youtube.com/vi/vkAOYeTpLg0/0.jpg)](https://youtu.be/vkAOYeTpLg0 "Changing the immutable")

# Featured extensions

- [AccessorsExtra.jl](https://github.com/JuliaAPlavin/AccessorsExtra.jl) [[docs](https://aplavin.github.io/AccessorsExtra.jl/test/notebook.html)] introduces additional optics and related functions that are considered too opinionated or too experimental for inclusion in `Accessors`.
