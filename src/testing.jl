using Test: @test
function test_getset_laws(lens, obj, val1, val2; cmp=(==))

    # set ⨟ get
    val = lens(obj)
    @test cmp(set(obj, lens, val), obj)

    # get ⨟ set
    obj1 = set(obj, lens, val1)
    @test cmp(lens(obj1), val1)

    # set idempotent
    obj12 = set(obj1, lens, val2)
    obj2 = set(obj12, lens, val2)
    @test cmp(obj12, obj2)
end

function test_modify_law(f, lens, obj)
    obj_modify = modify(f, obj, lens)
    old_val = lens(obj)
    val = f(old_val)
    obj_setfget = set(obj, lens, val)
    @test obj_modify == obj_setfget
end

function test_getsetall_laws(optic, obj, vals1, vals2; cmp=(==))

    # setall ⨟ getall
    vals = getall(obj, optic)
    @test cmp(setall(obj, optic, vals), obj)

    # getall ⨟ setall
    obj1 = setall(obj, optic, vals1)
    @test cmp(collect(getall(obj1, optic)), collect(vals1))

    # setall idempotent
    obj12 = setall(obj1, optic, vals2)
    obj2 = setall(obj12, optic, vals2)
    @test obj12 == obj2
end
