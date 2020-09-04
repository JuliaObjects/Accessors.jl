# Setfield

[![Build Status](https://travis-ci.org/jw3126/Setfield.jl.svg?branch=master)](https://travis-ci.org/jw3126/Setfield.jl)
[![codecov.io](https://codecov.io/github/jw3126/Setfield.jl/coverage.svg?branch=master)](http://codecov.io/github/jw3126/Setfield.jl?branch=master)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://jw3126.github.io/Setfield.jl/stable/intro)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://jw3126.github.io/Setfield.jl/dev/intro)

Update deeply nested immutable structs.

# Usage
Updating deeply nested immutable structs was never easier:
```julia
using Setfield
@set obj.a.b.c = d
```
For more information, see [the documentation](https://jw3126.github.io/Setfield.jl/latest/intro/) and/or watch this video:

[![JuliaCon2020 Changing the immutable](https://img.youtube.com/vi/vkAOYeTpLg0/0.jpg)](https://youtu.be/vkAOYeTpLg0 "Changing the immutable")

# Some creative usages of Setfield

* [VegaLite.jl](https://github.com/queryverse/VegaLite.jl) overloads
  `getproperty` and lens API to manipulate JSON-based nested objects.

* [Kaleido.jl](https://github.com/tkf/Kaleido.jl) is a library of
  additional lenses.

* [PhaseSpaceIO.jl](https://github.com/jw3126/PhaseSpaceIO.jl) overloads
  `getproperty` and `setproperties` to get/set values from/in packed bits.
