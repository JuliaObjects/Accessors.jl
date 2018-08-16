using Documenter

deploydocs(
    repo = "github.com/jw3126/Setfield.jl.git",
    julia = "1.0",
    target = "build",
    deps   = nothing,
    make   = nothing
)
