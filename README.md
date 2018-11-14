# Setfield

[![Build Status](https://travis-ci.org/jw3126/Setfield.jl.svg?branch=master)](https://travis-ci.org/jw3126/Setfield.jl)
[![codecov.io](https://codecov.io/github/jw3126/Setfield.jl/coverage.svg?branch=master)](http://codecov.io/github/jw3126/Setfield.jl?branch=master)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://jw3126.github.io/Setfield.jl/stable/intro.html)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://jw3126.github.io/Setfield.jl/latest/intro.html)

Update deeply nested immutable structs.

# Usage
Updating deeply nested immutable structs was never easier:
```julia
using Setfield
@set obj.a.b.c = d
```
For more information, see [the documentation](https://jw3126.github.io/Setfield.jl/latest/intro.html).
