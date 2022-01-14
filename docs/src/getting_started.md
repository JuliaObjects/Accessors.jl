# Getting started
Say you have a `NamedTuple` and you want to update it:
```jldoctest getting_started
julia> x = (greeting="Hello", name="World")
(greeting = "Hello", name = "World")

julia> x.greeting = "Hi"
ERROR: setfield!: immutable struct of type NamedTuple cannot be changed
[...]
```
This fails, because named tuples are immutable. Instead you can use Accessors to carry out the update:

```jldoctest getting_started
julia> using Accessors

julia> @set x.greeting = "Hi"
(greeting = "Hi", name = "World")

julia> x # still the same. Accessors did not overwrite x, it just created an updated copy
(greeting = "Hello", name = "World")

julia> x_new = @set x.greeting = "Hi" # typically you will assign a name to the updated copy
(greeting = "Hi", name = "World")
```
Accessors.jl does not only support `NamedTuple`, but arbitrary structs and nested updates.
```jldoctest getting_started
julia> struct HelloWorld
           greeting::String
           name::String
       end

julia> x = HelloWorld("hi", "World")
HelloWorld("hi", "World")

julia> @set x.name = "Accessors" # update a struct
HelloWorld("hi", "Accessors")

julia> x = (a=1, b=(c=3, d=4))
(a = 1, b = (c = 3, d = 4))

julia> @set x.b.c = 10 # nested update
(a = 1, b = (c = 10, d = 4))
```
Accessors.jl does not only support updates of properties, but also index updates.
```jldoctest getting_started
julia> x = (10,20,21)
(10, 20, 21)

julia> @set x[3] = 30
(10, 20, 30)
```
In fact Accessors.jl supports many more notions of update:
```jldoctest getting_started
julia> x = [1,2,3];

julia> x_new = @set eltype(x) = UInt8;

julia> @show x_new;
x_new = UInt8[0x01, 0x02, 0x03]
```
Accessors.jl is very composable, which means different updates can be nested and combined.
```jldoctest getting_started
julia> data = (a = (b = (1,2),), c=3)
(a = (b = (1, 2),), c = 3)

julia> @set data.a.b[end] = 20
(a = (b = (1, 20),), c = 3)

julia> @set splitext("some_file.py")[2] = ".jl"
"some_file.jl"
```
