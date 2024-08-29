using ArgCheck: @argcheck

function test_getset_laws(lens, obj, val1, val2; cmp=(==))
    # set ⨟ get
    val = lens(obj)
    @argcheck cmp(set(obj, lens, val), obj)

    # get ⨟ set
    obj1 = set(obj, lens, val1)
    @argcheck cmp(lens(obj1), val1)

    # set idempotent
    obj12 = set(obj1, lens, val2)
    obj2 = set(obj12, lens, val2)
    @argcheck cmp(obj12, obj2)

    test_modify_law(identity, lens, obj; cmp)
end

function test_modify_law(f, lens, obj; cmp=(==))
    obj_modify = modify(f, obj, lens)
    old_vals = getall(obj, lens)
    vals = map(f, old_vals)
    obj_setfget = setall(obj, lens, vals)
    @argcheck cmp(obj_modify, obj_setfget)
end

function test_insertdelete_laws(lens, obj, val; cmp=(==))
    obj1 = insert(obj, lens, val)
    @argcheck cmp(lens(obj1), val)
    obj2 = set(obj1, lens, val)
    @argcheck cmp(obj1, obj2)
    obj3 = delete(obj1, lens)
    @argcheck cmp(obj, obj3)
end

function test_getsetall_laws(optic, obj, vals1, vals2; cmp=(==))
    # setall ⨟ getall
    vals = getall(obj, optic)
    @argcheck cmp(setall(obj, optic, vals), obj)

    # getall ⨟ setall
    obj1 = setall(obj, optic, vals1)
    @argcheck cmp(collect(getall(obj1, optic)), collect(vals1))

    # setall idempotent
    obj12 = setall(obj1, optic, vals2)
    obj2 = setall(obj12, optic, vals2)
    @argcheck obj12 == obj2

    test_modify_law(identity, optic, obj; cmp)
end