__precompile__(true)
module Setfield
using MacroTools
using MacroTools: isstructdef, splitstructdef

include("lens.jl")
include("sugar.jl")
include("functionlenses.jl")
include("settable.jl")
include("experimental.jl")
end
