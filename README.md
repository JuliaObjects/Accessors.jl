# Setfield

[![Build Status](https://travis-ci.org/jw3126/Setfield.jl.svg?branch=master)](https://travis-ci.org/jw3126/Setfield.jl)
[![codecov.io](https://codecov.io/github/jw3126/Setfield.jl/coverage.svg?branch=master)](http://codecov.io/github/jw3126/Setfield.jl?branch=master)

Update deeply nested immutable structs.

## Usage
```juliarepl
julia> using Setfield

julia> struct T;a;b end

julia> t = T(1,2)
T(1, 2)

julia> @set t.a = 5
T(5, 2)

julia> @set t.a = T(2,2)
T(T(2, 2), 2)

julia> @set t.a.b = 3
T(T(2, 3), 2)
```
