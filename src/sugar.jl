export @set, @optic, @reset, @modify
using MacroTools

"""
    @set assignment

Return a modified copy of deeply nested objects.

# Example
```jldoctest
julia> using Accessors

julia> struct T;a;b end

julia> t = T(1,2)
T(1, 2)

julia> @set t.a = 5
T(5, 2)

julia> t
T(1, 2)

julia> t = @set t.a = T(2,2)
T(T(2, 2), 2)

julia> @set t.a.b = 3
T(T(2, 3), 2)
```
Supports the same syntax as [`@optic`](@ref). See also [`@reset`](@ref).
"""
macro set(ex)
    setmacro(identity, ex, overwrite=false)
end

"""
    @reset assignment

Shortcut for `obj = @set obj...`.

# Example
```jldoctest
julia> using Accessors

julia> t = (a=1,)
(a = 1,)

julia> @reset t.a=2
(a = 2,)

julia> t
(a = 2,)
```
Supports the same syntax as [`@optic`](@ref). See also [`@set`](@ref).
"""
macro reset(ex)
    setmacro(identity, ex, overwrite=true)
end

"""

    @modify(f, obj_optic)

Define an optic and call [`modify`](@ref) on it.
```jldoctest
julia> using Accessors

julia> xs = [1,2,3];

julia> @modify(xs |> Elements() |> If(isodd)) do x
           x + 1
       end
3-element Array{Int64,1}:
 2
 2
 4
```
Supports the same syntax as [`@optic`](@ref). See also [`@set`](@ref).
"""
macro modify(f, obj_optic)
    modifymacro(identity, f, obj_optic)
end

"""
    modifymacro(optictransform, f, obj_optic)

This function can be used to create a customized variant of [`@modify`](@ref).
See also [`opticmacro`](@ref), [`setmacro`](@ref).
"""

function modifymacro(optictransform, f, obj_optic)
    f = esc(f)
    obj, optic = parse_obj_lens(obj_optic)
    :(let
        optic = $(optictransform)($optic)
        ($modify)($f, $obj, optic)
    end)
end

foldtree(op, init, x) = op(init, x)
foldtree(op, init, ex::Expr) =
    op(foldl((acc, x) -> foldtree(op, acc, x), ex.args; init=init), ex)

need_dynamic_lens(ex) =
    foldtree(false, ex) do yes, x
        yes || x === :end || x === :_
    end

replace_underscore(ex, to) = postwalk(x -> x === :_ ? to : x, ex)

function lower_index(collection::Symbol, index, dim)
    if isexpr(index, :call)
        return Expr(:call, lower_index.(collection, index.args, dim)...)
    elseif index === :end
        if dim === nothing
            return :($(Base.lastindex)($collection))
        else
            return :($(Base.lastindex)($collection, $dim))
        end
    end
    return index
end

function parse_obj_lenses(ex)
    if @capture(ex, (front_ |> back_))
        obj, frontlens = parse_obj_lenses(front)
        backlens = try
            # allow e.g. obj |> first |> _.a.b
            obj_back, backlens = parse_obj_lenses(back)
            if obj_back == esc(:_)
                backlens
            else
                (esc(back),)
            end
        catch ArgumentError
            backlens = (esc(back),)
        end
        return obj, tuple(frontlens..., backlens...)
    elseif @capture(ex, front_[indices__])
        obj, frontlens = parse_obj_lenses(front)
        if any(need_dynamic_lens, indices)
            @gensym collection
            indices = replace_underscore.(indices, collection)
            dims = length(indices) == 1 ? nothing : 1:length(indices)
            lindices = esc.(lower_index.(collection, indices, dims))
            lens = :($DynamicIndexLens($(esc(collection)) -> ($(lindices...),)))
        else
            index = esc(Expr(:tuple, indices...))
            lens = :($IndexLens($index))
        end
    elseif @capture(ex, front_.property_)
        property isa Union{Symbol,String} || throw(ArgumentError(
            string("Error while parsing :($ex). Second argument to `getproperty` can only be",
                   "a `Symbol` or `String` literal, received `$property` instead.")
        ))
        obj, frontlens = parse_obj_lenses(front)
        lens = :($PropertyLens{$(QuoteNode(property))}())
    elseif @capture(ex, f_(front_))
        obj, frontlens = parse_obj_lenses(front)
        lens = esc(f) # function lens
    else
        obj = esc(ex)
        return obj, ()
    end
    return (obj, tuple(frontlens..., lens))
end

"""
    opticcompose([lens₁, [lens₂, [lens₃, ...]]])

Compose `lens₁`, `lens₂` etc. There is one subtle point here:
While the two composition orders `(lens₁ ⨟ lens₂) ⨟ lens₃` and `lens₁ ⨟ (lens₂ ⨟ lens₃)` have equivalent semantics, their performance may not be the same.

The `opticcompose` function tries to use a composition order, that the compiler likes. The composition order is therefore not part of the stable API.
"""
opticcompose() = identity
opticcompose(args...) = opcompose(args...)

function parse_obj_lens(ex)
    obj, lenses = parse_obj_lenses(ex)
    lens = Expr(:call, opticcompose, lenses...)
    obj, lens
end

function get_update_op(sym::Symbol)
    s = String(sym)
    if !endswith(s, '=') || isdefined(Base, sym)
        # 'x +=' etc. is actually 'x = x +', and so '+=' isn't defined in Base.
        # '>=' however is a function, and not an assignment operator.
        msg = "Operation $sym doesn't look like an assignment"
        throw(ArgumentError(msg))
    end
    Symbol(s[1:end-1])
end

struct _UpdateOp{OP,V}
    op::OP
    val::V
end
(u::_UpdateOp)(x) = u.op(x, u.val)

"""
    setmacro(optictransform, ex::Expr; overwrite::Bool=false)

This function can be used to create a customized variant of [`@set`](@ref).
It works by applying `optictransform` to the lens that is used in the customized `@set` macro
at runtime.

# Example
```julia
function mytransform(lens::Lens)::Lens
    ...
end
macro myset(ex)
    setmacro(mytransform, ex)
end
```
See also [`opticmacro`](@ref).
"""
function setmacro(optictransform, ex::Expr; overwrite::Bool=false)
    @assert ex.head isa Symbol
    @assert length(ex.args) == 2
    ref, val = ex.args
    obj, lens = parse_obj_lens(ref)
    dst = overwrite ? obj : gensym("_")
    val = esc(val)
    ret = if ex.head == :(=)
        quote
            lens = ($optictransform)($lens)
            $dst = $set($obj, lens, $val)
        end
    else
        op = get_update_op(ex.head)
        f = :($_UpdateOp($op,$val))
        quote
            lens = ($optictransform)($lens)
            $dst = $modify($f, $obj, lens)
        end
    end
    ret
end

"""
    @optic

Construct an optic from property access and similar.

# Example

```jldoctest
julia> using Accessors

julia> struct T;a;b;end

julia> t = T("A1", T(T("A3", "B3"), "B2"))
T("A1", T(T("A3", "B3"), "B2"))

julia> l = @optic _.b.a.b
(@optic _.b) ∘ (@optic _.a) ∘ (@optic _.b)

julia> l(t)
"B3"

julia> set(t, l, 100)
T("A1", T(T("A3", 100), "B2"))

julia> t = ("one", "two")
("one", "two")

julia> set(t, (@optic _[1]), "1")
("1", "two")
```

See also [`@set`](@ref).
"""
macro optic(ex)
    opticmacro(identity, ex)
end


"""
    opticmacro(optictransform, ex::Expr)

This function can be used to create a customized variant of [`@optic`](@ref).
It works by applying `optictransform` to the created lens at runtime.
```julia
# new_lens = mytransform(lens)
macro mylens(ex)
    opticmacro(mytransform, ex)
end
```
See also [`setmacro`](@ref).
"""
function opticmacro(optictransform, ex)
    obj, lens = parse_obj_lens(ex)
    if obj != esc(:_)
        msg = """Cannot parse lens $ex. Lens expressions must start with _, got $obj instead."""
        throw(ArgumentError(msg))
    end
    :($(optictransform)($lens))
end


_show(io::IO, lens::PropertyLens{field}) where {field} = print(io, "(@optic _.$field)")
_show(io::IO, lens::IndexLens) = print(io, "(@optic _[", join(repr.(lens.indices), ", "), "])")
Base.show(io::IO, lens::Union{IndexLens, PropertyLens}) = _show(io, lens)
Base.show(io::IO, ::MIME"text/plain", lens::Union{IndexLens, PropertyLens}) = _show(io, lens)

# debugging
show_composition_order(lens) = (show_composition_order(stdout, lens); println())
show_composition_order(io::IO, lens) = show(io, lens)
function show_composition_order(io::IO, lens::ComposedOptic)
    print(io, "(")
    show_composition_order(io, lens.outer)
    print(io, " ∘  ")
    show_composition_order(io, lens.inner)
    print(io, ")")
end

