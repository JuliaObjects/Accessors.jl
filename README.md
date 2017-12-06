# Setfield

[![Build Status](https://travis-ci.org/jw3126/Setfield.jl.svg?branch=master)](https://travis-ci.org/jw3126/Setfield.jl)
[![codecov.io](https://codecov.io/github/jw3126/Setfield.jl/coverage.svg?branch=master)](http://codecov.io/github/jw3126/Setfield.jl?branch=master)

Update deeply nested immutable structs.

## Usage
```julia
struct T
    a
    b
end

t = T(1,1)
@set t.a = 5
# T(5, 1)

t = T(1, T(2, T(3,3)))
@set t.b.b.a = 42
# T(1, T(2, T(42,3)))
```
