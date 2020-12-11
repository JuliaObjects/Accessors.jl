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

makedocs(
    modules = [Accessors],
    sitename = "Accessors.jl",
    pages = [
        "Getting started" => "intro.md",
        "Explanation" => "lenses.md",
        "Reference" => "index.md",
        "How to guides" => [
            "Custom Optics" => "examples/custom_optics.md",
            "Custom Macros" => "examples/custom_macros.md",
        ],
        hide("examples/specter.md"),
        hide("internals.md"),
    ],
    strict = true,  # to exit with non-zero code on error
)

deploydocs(repo = "github.com/JuliaObjects/Accessors.jl.git")
