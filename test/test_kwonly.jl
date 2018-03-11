module TestKwonly

using Base.Test
using Setfield
using Reconstructables: @add_kwonly

@settable struct A
    x
    y
    @add_kwonly A(x; y=2) = new(x, y)
end

x0 = A(A(A(5), A(6, 7)))
x1 = @set x0.x.x.x = 10
x2 = @set x1.x.y.y = 20

@test x2.x.x.x == 10
@test x2.x.y.y == 20
@test x2.x.y.x == x0.x.y.x == 6

end  # module
