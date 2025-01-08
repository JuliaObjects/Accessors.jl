module IntervalSetsExt
using Accessors
using IntervalSets

Accessors.set(x::Interval, ::typeof(endpoints), v::NTuple{2, Any}) = setproperties(x, left=first(v), right=last(v))
Accessors.set(x::Interval, ::typeof(leftendpoint), v) = @set x.left = v
Accessors.set(x::Interval, ::typeof(rightendpoint), v) = @set x.right = v
Accessors.set(x::Interval, ::typeof(closedendpoints), v::NTuple{2, Bool}) = Interval{v[1] ? :closed : :open, v[2] ? :closed : :open}(endpoints(x)...)

Accessors.set(x, f::Base.Fix2{typeof(mod), <:Interval}, v) = @set x |> mod(_ - leftendpoint(f.x), width(f.x)) = v - leftendpoint(f.x)
end
