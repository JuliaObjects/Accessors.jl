module Perf
using BenchmarkTools
using BenchmarkTools: Benchmark, TrialEstimate
using Setfield
using Test
using InteractiveUtils
using StaticArrays

struct AB{A,B}
    a::A
    b::B
end

function lens_set_a((obj, val))
    @set obj.a = val
end

function hand_set_a((obj, val))
    AB(val, obj.b)
end

function lens_set_ab((obj, val))
    @set obj.a.b = val
end

function hand_set_ab((obj, val))
    a = AB(obj.a.a, val)
    AB(a, obj.b)
end

function lens_set_a_and_b((obj, val))
    o1 = @set obj.a = val
    o2 = @set o1.b = val
end

function hand_set_a_and_b((obj, val))
    AB(val, val)
end

function lens_set_i((obj, val, i))
    @inbounds (@set obj[i] = val)
end

function hand_set_i((obj, val, i))
    @inbounds Base.setindex(obj, val, i)
end

function benchmark_lens_vs_hand(b_lens::Benchmark, b_hand::Benchmark)

    te_hand = minimum(run(b_lens))
    te_lens = minimum(run(b_hand))
    @show te_lens
    @show te_hand
    @test te_lens.memory == te_hand.memory
    @test te_lens.allocs == te_hand.allocs
    @test te_lens.time <= 2*te_hand.time
end

function uniquecounts(iter)
    ret = Dict{eltype(iter), Int}()
    for x in iter
        ret[x] = get!(ret, x, 0) + 1
    end
    ret
end

function test_ir_lens_vs_hand(info_lens::Core.CodeInfo,
                              info_hand::Core.CodeInfo)

    heads(info) = [ex.head for ex in info.code if ex isa Expr]

    # test no needless kinds of operations
    heads_lens = heads(info_lens)
    heads_hand = heads(info_hand)
    @test Set(heads_lens) == Set(heads_hand)

    # test no intermediate objects or lenses
    @test count(==(:new), heads_lens) == count(==(:new), heads_hand)

    # this test might be too strict
    @test uniquecounts(heads_lens) == uniquecounts(heads_hand)
end

let
    obj = AB(AB(1,2), :b)
    val = (1,2)
    @testset "$(setup.lens)" for setup in [
            (lens=lens_set_a,           hand=hand_set_a,       args=(obj, val)),
            (lens=lens_set_a,           hand=hand_set_a,       args=(obj, val)),
            (lens=lens_set_ab,          hand=hand_set_ab,      args=(obj, val)),
            (lens=lens_set_a_and_b,     hand=hand_set_a_and_b, args=(obj, val)),
            (lens=lens_set_i,           hand=hand_set_i,
             args=(@SVector[1,2], 10, 1))
            ]
        f_lens = setup.lens
        f_hand = setup.hand
        args = setup.args

        @assert f_hand(args) == f_lens(args)

        @testset "IR" begin
            info_lens, _ = @code_typed f_lens(args)
            info_hand, _ = @code_typed f_hand(args)
            test_ir_lens_vs_hand(info_lens, info_hand)
        end

        @testset "benchmark" begin
            b_lens = @benchmarkable $f_lens($args)
            b_hand = @benchmarkable $f_hand($args)
            benchmark_lens_vs_hand(b_lens, b_hand)
        end
    end
end

function compose_left_assoc(obj, val)
    l = @lens ((_.a∘_.b)∘_.c)∘_.d
    set(obj, l, val)
end

function compose_right_assoc(obj, val)
    l = @lens _.a∘(_.b∘(_.c∘_.d))
    set(obj, l, val)
end
function compose_default_assoc(obj, val)
    l = @lens _.a.b.c.d
    set(obj, l, val)
end
@testset "Lens composition compiler prefered associativity" begin

    obj = (a=(b=(c=(d=1,d2=2),c2=2),b2=3), a2=2)
    val = 2.2
    @test compose_left_assoc(obj, val) == compose_default_assoc(obj, val)
    @test compose_right_assoc(obj, val) == compose_default_assoc(obj, val)

    b_default = minimum(@benchmark compose_default_assoc($obj, $val))
    println("Default associative composition: $b_default")
    b_left    = minimum(@benchmark compose_left_assoc($obj, $val)   )
    println("Left associative composition: $b_left")
    b_right   = minimum(@benchmark compose_right_assoc($obj, $val)  )
    println("Right associative composition: $b_right")

    @test b_default.allocs == 0
    @test b_right.allocs == 0
    @test_broken b_left.allocs == 0

    @test b_left.time > 2b_default.time
    @test b_right.time ≈ b_default.time rtol=0.8
end

end
