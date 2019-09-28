__precompile__(true)
module Setfield
using MacroTools
using MacroTools: isstructdef, splitstructdef

include("lens.jl")
include("sugar.jl")
include("functionlenses.jl")
include("settable.jl")
include("experimental.jl")

for n in names(Setfield, all=true)
    T = getproperty(Setfield, n)
    if T isa Type && T <: Lens && (T === ComposedLens || has_atlens_support(T))
        @eval Base.show(io::IO, l::$T) = _show(io, nothing, l)
    end
end

end
