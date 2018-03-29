using Kwonly
using Base.Test
using Setfield

@settable struct AKW
    x
    y
    @add_kwonly AKW(x; y=2) = new(x, y)
end

@testset "kwonly" begin
    x0 = AKW(AKW(AKW(5), AKW(6, 7)))
    x1 = @set x0.x.x.x = 10
    x2 = @set x1.x.y.y = 20
    
    @test x2.x.x.x == 10
    @test x2.x.y.y == 20
    @test x2.x.y.x == x0.x.y.x == 6
end
