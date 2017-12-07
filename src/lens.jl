abstract type Lens end

export Lens, set, get, update

@inline function update(f, l::Lens, obj)
    old_val = get(l, obj)
    new_val = f(old_val)
    set(l, obj, new_val)
end

struct FieldLens{fieldname} <: Lens end
FieldLens(s::Symbol) = FieldLens{s}()

import Base.get
@generated function get(l::FieldLens{field}, obj) where {field}
    @assert field isa Symbol
    assert_hasfield(obj, field)
    Expr(:block,
        Expr(:meta, :inline),
        :(obj.$field)
    )
end

function set_field_lens_impl(T, field)
    args = map(fieldnames(T)) do fn
        fn == field ? :val : :(obj.$fn)
    end
    Expr(:block,
        Expr(:meta, :inline),
        Expr(:call, T, args...)
    )
end

function assert_hasfield(T, field)
    if !(field ∈ fieldnames(T))
        msg = "$T has no field $field"
        throw(ArgumentError(msg))
    end
end

@generated function set(l::FieldLens{field}, obj, val) where {field}
    @assert field isa Symbol
    assert_hasfield(obj, field)
    set_field_lens_impl(obj, field)
end

struct ComposedLens{L1, L2} <: Lens
    lens1::L1
    lens2::L2
end

compose(l::Lens) = l
compose(l1::Lens, l2 ::Lens) = ComposedLens(l1, l2)
compose(l::Lens, ls::Lens...) = compose(l, compose(ls...))

struct IndexLens{I} <: Lens
    indices::I
end
IndexLens(indices...) = IndexLens(indices)

get(l::IndexLens, obj) = getindex(obj, l.indices...)
set(l::IndexLens, obj, val) = Base.setindex(obj, val, l.indices...)

# hack to support static arrays
if Pkg.installed("StaticArrays") != nothing
    import StaticArrays
    Base.setindex(arr::StaticArrays.StaticArray, args...) = StaticArrays.setindex(arr,args...)
end


function get(l::ComposedLens, obj)
    inner_obj = get(l.lens2, obj)
    get(l.lens1, inner_obj)
end

function set(l::ComposedLens, obj, val)
    inner_obj = get(l.lens2, obj)
    inner_val = set(l.lens1, inner_obj, val)
    set(l.lens2, obj, inner_val)
end

struct Focused{O, L <: Lens}
    object::O
    lens::L
end

update(f, foc::Focused) = update(f, foc.lens, foc.object)
set(foc::Focused, val) = set(foc.lens, foc.object, val)
get(foc::Focused) = get(foc.lens, foc.object)
