@settable struct SetMe{A,B}
    b::B
    SetMe{A}(b::B) where {A,B} = new{A,B}(b)
end

@testset "settable" begin
    s1 = SetMe{:a}(1)
    s2 = @set s1.b = 2
    @test s2 === SetMe{:a,Int64}(2)
end
