using Setfield
using Base.Test

struct T
    a
    b
end

@testset "@set" begin
    t = T(1,2)
    @test T(1, T(1,2)) === @set t.b = T(1,2)
    @test_throws ArgumentError @set t.c = 3

    t = T(T(2,2), 1)
    @set t.a.a = 3
    @test t === T(T(3, 2), 1)
        
    t = T(1, T(2, T(T(4,4),3)))
    @test T(1, T(2, 4)) === @set t.b.b = 4

    t = T(1, T(2, T(T(4,4),3)))
    @set t.b.b.a.a = 5
    @test t === T(1, T(2, T(T(5, 4), 3)))
    @test_throws ArgumentError @set t.b.b.a.a.a = 3

    t = T(1,2)
    @set t.a += 1
    @test t === T(2,2)

    t = T(1,2)
    @set t.b -= 2
    @test t === T(1,0)

    t = T(10, 20)
    @set t.a *= 10
    @test t === T(100, 20)
end
