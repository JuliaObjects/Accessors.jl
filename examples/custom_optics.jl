# # Custom optics
#
# This guide demonstrates how to implement new kinds of optics.
# There are multiple possibilities, the most straight forward one is function lenses
#
# ### Function lenses
# Say we are dealing with points in the plane and polar coordinates are of interest:

struct Point
    x::Float64
    y::Float64
end

function Base.isapprox(pt1::Point, pt2::Point; kw...)
    return isapprox([pt1.x,pt1.y], [pt2.x, pt2.y]; kw...)
end

function polar(pt::Point)
    r = sqrt(pt.x^2 + pt.y^2)
    θ = atan(pt.y,pt.x)
    return (r=r, θ=θ)
end

function Point_from_polar(rθ)
    r, θ = rθ
    x = cos(θ)*r
    y = sin(θ)*r
    return Point(x,y)
end

# It would certainly be ergonomic to do things like
# `@set polar(pt) = ...`
# `@set polar(pt).θ = ...`
# `@set polar(pt).r = 1`
# To enable this, a function lens can be implemented:
#
using Accessors
using Test
Accessors.set(pt, ::typeof(polar), rθ) = Point_from_polar(rθ)
#
# And now it is possible to do
pt = Point(2,0)
pt2 = @set polar(pt).r = 5
@test pt2 ≈ Point(5,0)

pt3 = @set polar(pt).θ = π/2
@test pt3 ≈ Point(0, 2)

# ### Modify based optics
#
# Say we have a `Dict` and we want to update all of its keys. This can be done as follows:
function mapkeys(f, d::Dict)
    return Dict(f(k) => v for (k,v) in pairs(d))
end
# Lets make this more ergonomic by defining an optic for it
#
using Accessors
struct Keys end
Accessors.OpticStyle(::Type{Keys}) = ModifyBased()
Accessors.modify(f, obj, ::Keys) = mapkeys(f, obj)
# It can be used as follows:
obj = Dict("A" =>1, "B" => 2, "C" => 3)
obj2 = @modify(lowercase, obj |> Keys())
@test obj2 == Dict("a" =>1, "b" => 2, "c" => 3)
