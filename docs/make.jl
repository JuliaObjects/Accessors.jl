using Setfield, Documenter

makedocs(
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
)
