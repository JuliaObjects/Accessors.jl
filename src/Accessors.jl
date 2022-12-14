module Accessors
using MacroTools
using MacroTools: isstructdef, splitstructdef, postwalk
using InverseFunctions


if !isdefined(Base, :only)
    # Julia pre-1.4
    function only(x)
        length(x) == 1 || throw(ArgumentError("Collection contains $(length(x)) elements, must contain exactly 1 element"))
        first(x)
    end
end

if !isdefined(Base, :get_extension)
    using Requires
end
@static if !isdefined(Base, :get_extension)
    function __init__()
        @require StaticArrays = "90137ffa-7385-5640-81b9-e52037218182" include("../ext/StaticArraysExt.jl")
    end
end

include("setindex.jl")
include("optics.jl")
include("getsetall.jl")
include("sugar.jl")
include("functionlenses.jl")
include("testing.jl")

end
