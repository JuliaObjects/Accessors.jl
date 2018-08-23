using BenchmarkTools
using BenchmarkTools: Benchmark, TrialEstimate
using Setfield
using Test
using InteractiveUtils

struct AB{A,B}
    a::A
    b::B
end

function lens_set_a(obj, val)
    @set obj.a = val
end

function hand_set_a(obj, val)
    AB(val, obj.b)
end

function lens_set_ab(obj, val)
    @set obj.a.b = val
end

function hand_set_ab(obj, val)
    a = AB(obj.a.a, val)
    AB(a, obj.b)
end

function lens_set_a_and_b(obj, val)
    o1 = @set obj.a = val
    o2 = @set o1.b = val
end

function hand_set_a_and_b(obj, val)
    AB(val, val)
end


function iswin(te_cont::TrialEstimate, te_ref::TrialEstimate)
    # te1 is winner, te2 is looser
    !isloose(te_cont, te_ref)
end
function isloose(te_cont, te_ref)
    jt = judge(te_cont, te_ref)
    jt.time   == :regression ||
    jt.memory == :regression
end

# test that best contender TrialEstimate beats worst reference TrialEstimate
function minimax_bench(contender::Benchmark, reference::Benchmark;
        max_runs=5,
        estimator=minimum,
        kw_judge...)
    tune!(contender)
    tune!(reference)
    best_te_cont = estimator(run(contender))
    worst_te_ref = estimator(run(reference))
    for i in 2:max_runs
        if iswin(best_te_cont, worst_te_ref)
            break
        end
        te_cont = estimator(run(contender))
        te_ref  = estimator(run(reference))
        if iswin(te_cont, best_te_cont)
            best_te_cont = te_cont
        end
        if isloose(te_ref, worst_te_ref)
            worst_te_ref = te_ref
        end
    end
    best_te_cont, worst_te_ref
end

function benchmark_lens_vs_hand(b_lens::Benchmark, b_hand::Benchmark)
    te_lens, te_hand = minimax_bench(b_lens, b_hand)
    @show te_lens
    @show te_hand
    @test iswin(te_lens, te_hand)
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

    code_lens = info_lens.code
    code_hand = info_hand.code

    # test no needless kinds of operations
    heads_lens = map(ex -> ex.head, code_lens)
    heads_hand = map(ex -> ex.head, code_hand)
    @test Set(heads_lens) == Set(heads_hand)

    # test no intermediate objects or lenses
    isnew(ex) = ex.head == :new
    isinvoke(ex) = ex.head == :invoke
    @test count(isnew, code_lens) == count(isnew, code_hand)

    # test inlining
    @assert count(isinvoke, code_hand) == 0
    @test count(isinvoke, code_lens) == 0

    # this test might be too strict
    @test uniquecounts(heads_lens) == uniquecounts(heads_hand)
end

@testset "benchmark" begin
    obj = AB(AB(1,2), :b)
    val = (1,2)
    for (f_lens, f_hand) in [
                             (lens_set_a, hand_set_a),
                             (lens_set_ab, hand_set_ab),
                             (lens_set_a_and_b, hand_set_a_and_b)
                            ]

        @assert f_lens(obj, val) == f_hand(obj, val)

        b_lens = @benchmarkable $f_lens($obj, $val)
        b_hand = @benchmarkable $f_hand($obj, $val)
        benchmark_lens_vs_hand(b_lens, b_hand)


        info_lens, _ = @code_typed f_lens(obj, val)
        info_hand, _ = @code_typed f_hand(obj, val)
        test_ir_lens_vs_hand(info_lens, info_hand)
    end
end
