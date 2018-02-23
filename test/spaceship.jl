using StaticArrays
struct Person
    name::Symbol
    birthyear::Int
end

struct SpaceShip
    captain::Person
    velocity::SVector{3, Float64}
    position::SVector{3, Float64}
end

@testset "SpaceShip" begin
    s = SpaceShip(
                  Person("julia", 2009),
                  [0,0,0],
                  [0,0,0]
                 )
    s = @set s.captain.name = "JULIA"
    s = @set s.velocity[1] += 10
    s = @set s.position[2]  = 20
    @test s === SpaceShip(Person("JULIA", 2009), [10.0, 0.0, 0.0], [0.0, 20.0, 0.0])
end
