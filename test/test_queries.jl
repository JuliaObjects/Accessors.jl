using Accessors, Test, BenchmarkTools, Static

obj = (7, (a=17.0, b=2.0f0), ("3", 4, 5.0), ((x=19, a=6.0,), [1,]))
vals = (1.0, 2.0, 3.0, 4.0)


# Fields is the default
q = Query(; 
    select=x -> x isa NamedTuple, 
    descend=x -> x isa Tuple, 
    optic = (Accessors.@optic _.a) ∘ Accessors.Fields()
    # optic = Accessors.Fields()
)
slowq = Query(; 
    select=x -> x isa NamedTuple, 
    descend=x -> x isa Tuple, 
    optic = (Accessors.@optic _.a) ∘ Accessors.Properties()
)

q(obj)
@code_native q(obj)
@code_native slowq(obj)

@code_warntype q(obj)
@code_warntype slowq(obj)


println("get")
@benchmark $q($obj)
@benchmark $slowlens($obj)
@test q(obj) == slowq(obj) == (17.0, 6.0)

missings_obj = (a=missing, b=1, c=(d=missing, e=(f=missing, g=2)))
@test Query(ismissing)(missings_obj) === (missing, missing, missing)
@benchmark Query(ismissing)($missings_obj)

println("set")
# Need a wrapper so we don't have to pass in the starting iterator
set(obj, q, vals) 
@benchmark set($obj, $q, $vals)

# Package deinition
# set(obj, q::Query, vals) = _set(obj, q, (vals, 1))[1][1]
# REPL definition
f(obj, q::Query, vals) = Accessors._set(obj, q, (vals, 1))[1][1]

julia> @btime f(obj, q, vals)
  19.302 ns (1 allocation: 80 bytes)
(7, (a = 1.0, b = 2.0f0), ("3", 4, 5.0), ((x = 19, a = 2.0), [1]))

julia> @btime set(obj, q, vals)
  89.260 ns (6 allocations: 464 bytes)
(7, (a = 1.0, b = 2.0f0), ("3", 4, 5.0), ((x = 19, a = 2.0), [1]))

@eval Accessors begin
    set(obj, q::Query, vals) = _set(obj, q, (vals, 1))[1][1]
end

@btime f(obj, q, vals)
@btime set(obj, q, vals) 

# @btime Accessors.set($obj, $slowlens, $vals)
@test Accessors.set(obj, lens, vals) == 
    (7, (a=1.0, b=2.0f0), ("3", 4, 5.0), ((x=19, a=2.0,), [1]))

@code_warntype set(obj, lens, vals) 
@code_native set(obj, lens, vals) 
@code_native Accessors._set(obj, lens, (vals, 1))[1]

# using Cthulhu
# using ProfileView
# @profview  for i in 1:1000000 Accessors.set(obj, lens, vals) end
# @descend Accessors.set(obj, lens, vals) 

println("unstable set")
unstable_lens = Accessors.Query(select=x -> x isa Float64 && x > 2, descend=x -> x isa NamedTuple)
@btime set($obj, $unstable_lens, $vals)
# slow_unstable_lens = Accessors.Query(; select=x -> x isa Number && x > 4, optic=Properties())
# @btime Accessors.set($obj, $slow_unstable_lens, $vals))

# Somehow modify compiles away almost completely
@btime modify(x -> 10x, $obj, $lens)

# Macros
@test (@getall missings_obj isa Number) == (1, 2)
expected = (a=missing, b=5, c=(d=missing, e=(f=missing, g=6)))
@test (@setall missings_obj isa Number = (5, 6)) === expected
@getall missings_obj isa Number
@setall missings_obj isa Number = (5, 6)

using Accessors

obj = (a=missing, b=1, c=(d=missing, e=(f=missing, g=2)))

q = Query(ismissing);

obj2 = set(obj, q, ["first", "wins", "here"])

set(obj2, Query(x -> x isa String), ["second", "should", "win"])

@getall missings_obj isa Number
missings_obj = (a=missing, b=(1, (; a=4)), c=(d=missing, e=(f=missing, g=2)))
@setall (x for x in missings_obj if x isa Missing) = (100.0, 200.0, 300.0)
@getall (x[1] for x in missings_obj if x isa NamedTuple) !(descend isa Dict)
