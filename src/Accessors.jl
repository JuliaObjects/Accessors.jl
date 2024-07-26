module Accessors
using MacroTools
using MacroTools: isstructdef, splitstructdef, postwalk
using InverseFunctions

if !isdefined(Base, :get_extension)
    using Requires
end


include("setindex.jl")
include("optics.jl")
include("getsetall.jl")
include("sugar.jl")
include("functionlenses.jl")
include("testing.jl")

# always included for now
include("../ext/AccessorsDatesExt.jl")
include("../ext/AccessorsLinearAlgebraExt.jl")
include("../ext/AccessorsTestExt.jl")

function __init__()
    @static if !isdefined(Base, :get_extension)
        @require StaticArrays = "90137ffa-7385-5640-81b9-e52037218182" include("../ext/AccessorsStaticArraysExt.jl")
    end
end

end
