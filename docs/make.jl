using Setfield, Documenter

makedocs(
         format = :html,
         modules = [Setfield],
         sitename = "Setfield.jl",
         pages = [
            "Introduction" => "intro.md",
            "Docstrings" => "index.md",
            ],
        )

deploydocs(
    repo = "github.com/jw3126/Setfield.jl.git",
    julia = "0.6",
    target = "build",
    deps   = nothing,
    make   = nothing
)
