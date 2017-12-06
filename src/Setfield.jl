__precompile__(true)
module Setfield

if Pkg.installed("StaticArrays") != nothing
    import StaticArrays: setindex
end

include("lens.jl")
include("sugar.jl")
end
