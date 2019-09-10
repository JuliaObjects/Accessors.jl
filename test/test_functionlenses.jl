module TestFunctionLenses
using Test
using Setfield

@testset "first" begin
    obj = (1, 2.0, '3')
    l = @lens first(_)
    @test get(obj, l) === 1
    @test set(obj, l, "1") === ("1", 2.0, '3')
    @test (@set first(obj) = "1") === ("1", 2.0, '3')

    obj2 = (a=((b=1,), 2), c=3)
    @test (@set first(obj2.a).b = '1') === (a=((b='1',), 2), c=3)
end

@testset "last" begin
    obj = (1, 2.0, '3')
    l = @lens last(_)
    @test get(obj, l) === '3'
    @test set(obj, l, '4') === (1, 2.0, '4')
    @test (@set last(obj) = '4') === (1, 2.0, '4')

    obj2 = (a=(1, (b=2,)), c=3)
    @test (@set last(obj2.a).b = '2') === (a=(1, (b='2',)), c=3)
end

end  # module
