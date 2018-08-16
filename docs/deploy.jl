using Documenter

deploydocs(
    repo = "github.com/jw3126/Setfield.jl.git",
    julia = "0.6",
    target = "build",
    deps   = nothing,
    make   = nothing
)
