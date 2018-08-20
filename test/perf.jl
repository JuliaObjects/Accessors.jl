using BenchmarkTools
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

function test_ir_lens_vs_hand(info_lens::Core.CodeInfo,
                              info_hand::Core.CodeInfo)

    code_lens = info_lens.code
    code_hand = info_hand.code

    # test no needless kinds of operations
    heads_lens = Set(map(ex -> ex.head, code_lens))
    heads_hand = Set(map(ex -> ex.head, code_hand))
    @test heads_lens == heads_hand

    # test no intermediate objects or lenses
    isnew(ex) = ex.head == :new
    @test count(isnew, code_lens) == count(isnew, code_hand)
end

@testset "benchmark" begin
    obj = AB(AB(1,2), :b)
    val = (1,2)
    for (f_lens, f_hand) in [
                             (lens_set_a, hand_set_a),
                             (lens_set_ab, hand_set_ab),
                             (lens_set_a_and_b, hand_set_a_and_b)
                            ]
        b_lens = @benchmark $f_lens($obj, $val)
        b_hand = @benchmark $f_hand($obj, $val)

        # actually they should be equal
        # but there is too much noise
        @test minimum(b_lens).time < 2*minimum(b_hand).time

        println("$f_lens: $b_lens")
        println("$f_hand: $b_hand")

        info_lens, _ = @code_typed f_lens(obj, val)
        info_hand, _ = @code_typed f_hand(obj, val)
        test_ir_lens_vs_hand(info_lens, info_hand)
    end
end
