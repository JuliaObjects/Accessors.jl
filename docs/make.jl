using Accessors, Documenter, Literate

inputdir = joinpath(@__DIR__, "..", "examples")
outputdir = joinpath(@__DIR__, "src", "examples")
mkpath(outputdir)
mkpath(joinpath(outputdir, "examples"))
for filename in readdir(inputdir)
    inpath = joinpath(inputdir, filename)
    cp(inpath, joinpath(outputdir, "examples", filename), force = true)
    Literate.markdown(inpath, outputdir; documenter = true)
end
cp(joinpath(@__DIR__, "..", "README.md"), joinpath(@__DIR__, "src", "index.md"), force=true)

makedocs(
    modules = [Accessors],
    sitename = "Accessors.jl",
    pages = [
        "Home" => "index.md",
        "Tutorials" => ["Getting started" => "getting_started.md",],
        "Explanation" => ["Lenses" => "lenses.md",],
        "Reference" => ["Docstrings" => "docstrings.md"],
        "How-to guides" => [
            "Custom Optics" => "examples/custom_optics.md",
            "Custom Macros" => "examples/custom_macros.md",
        ],
        hide("examples/specter.md"),
        hide("internals.md"),
    ],
    strict = true,  # to exit with non-zero code on error
)

deploydocs(;
    repo = "github.com/JuliaObjects/Accessors.jl.git",
    push_preview=true
)
