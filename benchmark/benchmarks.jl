using PkgBenchmark
using Setfield

struct AB{A,B}
    a::A
    b::B
end


function set_hand_optimized(obj, val)
    AB(AB(AB(val, obj.a.a.b),obj.a.b),obj.b)
end

function set_lens_inlined(obj, val)
    l = @lens _.a.a.a
    set(l, obj, val)
end

function set_macro(obj, val)
    @set obj.a.a.a = val
end

@benchgroup "@set" begin
    # these benchmarks are only few ns, hence noisy
    l = @lens _.a.a.a
    obj = AB(AB(AB(0,1),2),3)
    val = 2
    @bench "@set" set_macro($obj, $val)
    @bench "set with lens at compile time" set_lens_inlined($obj, $val)
    @bench "hand optimized" set_hand_optimized($obj, $val)
    @bench "set" set($l,$obj,$val)
end
