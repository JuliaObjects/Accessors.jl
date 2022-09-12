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

include("setindex.jl")
include("optics.jl")
include("getsetall.jl")
include("sugar.jl")
include("functionlenses.jl")
include("testing.jl")

end
