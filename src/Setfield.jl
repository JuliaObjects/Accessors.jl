__precompile__(true)
module Setfield
using MacroTools
using MacroTools: isstructdef, splitstructdef, postwalk
using Requires: @require

if VERSION < v"1.1-"
    using Future: copy!
end

include("setindex.jl")
include("lens.jl")
include("sugar.jl")
include("functionlenses.jl")

# To correctly dispatch to `show(::IO, ::CustomLens)` when it is defined by a
# user, we avoid defining the generic `show(::IO, ::Lens)`.  This way, we can
# safely call `show` inside `ComposedLens` without worrying about the
# `StackOverflowError` that can be easily triggered in the previous approach.
# See also:
# * https://github.com/jw3126/Setfield.jl/pull/86
# * https://github.com/jw3126/Setfield.jl/pull/88
for n in names(Setfield, all=true)
    T = getproperty(Setfield, n)
    if T isa Type && T <: Lens && (T === ComposedLens || has_atlens_support(T))
        @eval Base.show(io::IO, l::$T) = _show(io, nothing, l)
    end
end

function __init__()
    @require StaticArrays="90137ffa-7385-5640-81b9-e52037218182" begin
        setindex(a::StaticArrays.StaticArray, args...) =
            Base.setindex(a, args...)
    end
end

end
