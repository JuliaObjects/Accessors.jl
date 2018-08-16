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
