__precompile__(true)
module Setfield
using MacroTools
using MacroTools: isstructdef, splitstructdef, postwalk
using Requires: @require

# TODO erase these
const get = nothing
const Lens = nothing


if VERSION < v"1.1-"
    using Future: copy!
end

include("setindex.jl")
include("lens.jl")
include("sugar.jl")
include("functionlenses.jl")

function __init__()
    @require StaticArrays="90137ffa-7385-5640-81b9-e52037218182" begin
        setindex(a::StaticArrays.StaticArray, args...) =
            Base.setindex(a, args...)
    end
end

end
