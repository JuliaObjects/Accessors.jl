using Setfield, Documenter

makedocs(
         format = :html,
         modules = [Setfield],
         sitename = "Setfield.jl",
         pages = [
            "Introduction" => "intro.md",
            "Docstrings" => "index.md",
            ],
        strict = true,  # to exit with non-zero code on error
        )

deploydocs(
    repo = "github.com/jw3126/Setfield.jl.git",
    julia = "1.0",
    target = "build",
    deps   = nothing,
    make   = nothing
)
