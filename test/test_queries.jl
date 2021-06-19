using Accessors, Test, BenchmarkTools, Static
using Accessors: setall, getall, context
obj = (7, (a=17.0, b=2.0f0), ("3", 4, 5.0), ((x=19, a=6.0,)), [1])
vals = (1.0, 2.0, 3.0, 4.0)
# Fields is the default
q = Query(; 
    select=x -> x isa NamedTuple, 
    descend=x -> x isa Tuple, 
    optic = (Accessors.@optic _.a) ∘ Accessors.Properties()
    # optic = Accessors.Properties()
)
getall(obj, q)

@code_native getall(obj, q)
@code_warntype getall(obj, q)

@benchmark getall($obj, $q)
@test getall(obj, q) == (17.0, 6.0)

# using ProfileView, Cthulhu
# @descend getall(obj, q)
# f(obj, q) = for i in 1:10000000 getall(obj, q) end
# @profview f(obj, q)

missings_obj = (a=missing, b=1, c=(d=missing, e=(f=missing, g=2)))
@test getall(missings_obj, Query(ismissing)) === (missing, missing, missing)
@benchmark getall($missings_obj, Query(ismissing))

# Need a wrapper so we don't have to pass in the starting iterator
setall(obj, q, vals) 
@benchmark setall($obj, $q, $vals)
# using ProfileView
# @profview for i in 1:1000000 setall(obj, q, vals) end
@code_native setall(obj, q, vals)
@code_warntype setall(obj, q, vals)

# @btime Accessors.set($obj, $slowlens, $vals)
@test setall(obj, q, vals) == 
    (7, (a=1.0, b=2.0f0), ("3", 4, 5.0), ((x=19, a=2.0,)), [1])

unstable_q = Accessors.Query(select=x -> x isa Float64 && x > 2, descend=x -> x isa NamedTuple)
@btime setall($obj, $unstable_q, $vals)
# slow_unstable_lens = Accessors.Query(; select=x -> x isa Number && x > 4, optic=Properties())
# @btime Accessors.set($obj, $slow_unstable_lens, $vals))

# Somehow modify compiles away almost completely
@btime modify(x -> 10x, $obj, $q)

# Context
q = Query(; 
    select=x -> x isa Int, 
    descend=x -> x isa NamedTuple, 
    optic = Accessors.Properties()
)
obj2 = (1.0, :a, (b=2, c=2))
@test context((o, fn) -> fn, obj2, q) == (:b, :c)
@test context((o, fn) -> typeof(o), obj2, q) == (typeof(obj2[3]), typeof(obj2[3]))
@btime context((o, fn) -> fn, $obj2, $q)

# Macros
@test (@getall (x for x in missings_obj if x isa Number)) == (1, 2)
expected = (a=missing, b=5, c=(d=missing, e=(f=missing, g=6)))
@test (@setall (x for x in missings_obj if x isa Number) = (5, 6)) === expected
@getall (x[2].g for x in missings_obj if x isa NamedTuple)
@setall (x[2].g for x in missings_obj if x isa NamedTuple) = (5, 6)
