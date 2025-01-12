module Accessors
using MacroTools
using MacroTools: isstructdef, splitstructdef, postwalk
using InverseFunctions


include("setindex.jl")
include("optics.jl")
include("getsetall.jl")
include("sugar.jl")
include("functionlenses.jl")
include("testing.jl")

# always include for now; see https://github.com/JuliaObjects/Accessors.jl/issues/192
include("../ext/DatesExt.jl")

function __init__()
    if isdefined(Base.Experimental, :register_error_hint)
        Base.Experimental.register_error_hint(MethodError) do io, exc, argtypes, kwargs
            if exc.f === insert && argtypes[2] <: Accessors.DynamicIndexLens
                println(io)
                print(io, """
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
            elseif (exc.f === test_getset_laws || exc.f === test_modify_law || exc.f === test_getsetall_laws || exc.f === test_insertdelete_laws) && Base.get_extension(Accessors, :AccessorsTestExt) === nothing
                print(io, "\nDid you forget to load Test?")
            end
        end
    end
end

end
