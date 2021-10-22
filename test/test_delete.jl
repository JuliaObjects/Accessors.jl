module TestDelete
using Test
using Accessors

@testset "test delete" begin
    @test delete( (a=1, b=2, c=3), @optic(_.a) ) == (b=2, c=3)
    @test delete( (a=1, b=(c=2, d=3)), @optic(_.b.c) ) == (a=1, b=(d=3,))
    @test delete( (1,2,3), @optic(last(_)) ) == (1, 2)
    @test delete([1,2,3], @optic(_[2])) == [1, 3]
    @test delete( (a=1, b=(2, 3, 4)), @optic(first(_.b)) ) == (a=1, b=(3, 4))
    @test delete(2+3im, @optic(imag(_))) == 2
    @test delete( "path/to/file", @optic(basename(_)) ) == "path/to"
    @test delete( "path/to/file", @optic(dirname(_)) ) == "file"
end

end