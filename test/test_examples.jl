module TestExamples
using Test
dir = joinpath("..", "examples")
@testset "example $filename" for filename in readdir(dir)
    path = joinpath(dir, filename)
    @eval module $(Symbol("TestExample_$filename"))
    include($path)
    end
end
end#module
