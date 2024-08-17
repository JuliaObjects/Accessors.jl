module Accessors
using MacroTools
using MacroTools: isstructdef, splitstructdef, postwalk
using InverseFunctions
using Markdown: Markdown, @md_str, term

include("setindex.jl")
include("optics.jl")
include("getsetall.jl")
include("sugar.jl")
include("functionlenses.jl")
include("testing.jl")

function __init__()
    Base.Experimental.register_error_hint(MethodError) do io, exc, argtypes, kwargs
        if exc.f === insert && argtypes[2] <: Accessors.DynamicIndexLens
            println(io)
            term(io, md"""
               `insert` with a `DynamicIndexLens` is not supported, this can happen when you write
               code such as `@insert a[end] = 1` or `@insert a[begin] = 1` since `end` and `begin`
               are functions of `a`. The reason we do not support these with `insert` is that 
               Accessors.jl tries to guarentee that `f(insert(obj, f, val)) == val`, but 
               `@insert a[end] = 1` and `@insert a[begin] = 1` will violate that invariant.
               
               Instead, you can use `first` and `last` directly, e.g.
               ```
               julia> a = (1, 2, 3, 4)
               
               julia> @insert last(a) = 5
               (1, 2, 3, 4, 5)
               
               julia> @insert first(a) = 0
               (0, 1, 2, 3, 4)
               ```
               """)
        end
    end
end

end
