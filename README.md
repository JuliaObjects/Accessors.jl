# Setfield

## Usage
```julia
t = T(1,1)
@set t.a = 5
# T(5, 2)

t = T(1, T(2, T(3,3)))
@set t.b.b = 42
# T(1, T(2, 42))
```
