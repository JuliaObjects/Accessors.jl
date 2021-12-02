module Accessors
using MacroTools
using MacroTools: isstructdef, splitstructdef, postwalk
using Requires: @require



if !isdefined(Base, :only)
    # Julia pre-1.4
    function only(x)
        length(x) == 1 || throw(ArgumentError("Collection contains $(length(x)) elements, must contain exactly 1 element"))
        first(x)
    end
end

function __init__()
    @require StaticArrays = "90137ffa-7385-5640-81b9-e52037218182" include("staticarrays.jl")
end

include("setindex.jl")
include("optics.jl")
include("sugar.jl")
include("functionlenses.jl")
include("testing.jl")

end
