export @set, @optic, @reset, @modify, @getall, @setall
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

julia> xs = (1,2,3);

julia> ys = @modify(xs |> Elements() |> If(isodd)) do x
           x + 1
       end
(2, 2, 4)
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
    obj, optic = parse_obj_optic(obj_optic)
    :(($modify)($f, $obj, $(optictransform)($optic)))
end

"""
    @getall f(obj, arg...)
    @setall [x for x in obs if x isa Number] = values

@getall obj isa Number
"""
macro getall(ex)
    getallmacro(ex)
end
macro getall(ex, descend)
    getallmacro(ex; descend)
end

function getallmacro(ex; descend=true)
    # Wrap descend in an anonoymous function
    descend = :(descend -> $descend)
    if @capture(ex, (lens_ for var_ in obj_ if select_))
        select = _select(select, var)
        optic =_optics(lens)
        :(Query($select, $descend, $optic)($(esc(obj))))
    elseif @capture(ex, [lens_ for var_ in obj_ if select_])
        select = _select(select, var)
        optic =_optics(lens)
        :([Query($select, $descend, $optic)($(esc(obj)))...])
    elseif @capture(ex, (lens_ for var_ in obj_))
        select = _ -> false
        optic = _optics(lens)
        :(Query($select, $descend, $optic)($(esc(obj))))
    elseif @capture(ex, [lens_ for var_ in obj_])
        select = _ -> false
        optic = _optics(lens)
        :([Query($select, $descend, $optic)($(esc(obj)))...])
    else 
        error("@getall must be passed a generator")
    end
end

# Turn this into an anonoymous function so it
# doesn't matter which argument val is in
_select(select, val) = :($(esc(val)) -> $(esc(select)))
function _optics(ex)
    obj, optic = parse_obj_optic(ex)
    :($optic ∘ Fields())
end


"""
    @setall f(obj, arg...) = values
    
    @setall [x for x in obs if x isa Number] = values

"""
macro setall(ex)
    setallmacro(ex)
end

function setallmacro(ex)
    if @capture(ex, ((lens_ for var_ in obj_ if select_) = vals_))
        select = _select(select, var)
        optic =_optics(lens)
        :(set($(esc(obj)), Query(; select=$select, optic=$optic), $(esc(vals))))
    elseif @capture(ex, ((lens_ for var_ in obj_) = vals_))
        optic = _optics(lens)
        :(set($(esc(obj)), Query(; optic=$optic), $(esc(vals))))
    else 
        error("@getall must be passed a generator")
    end
end

foldtree(op, init, x) = op(init, x)
foldtree(op, init, ex::Expr) =
    op(foldl((acc, x) -> foldtree(op, acc, x), ex.args; init=init), ex)

need_dynamic_optic(ex) =
    foldtree(false, ex) do yes, x
        yes || x === :end || (x === :begin) || x === :_
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
    elseif (index === :begin)
        if dim === nothing
            return :($(Base.firstindex)($collection))
        else
            return :($(Base.firstindex)($collection, $dim))
        end
    end
    return index
end

function parse_obj_optics(ex)
    if @capture(ex, (front_ |> back_))
        obj, frontoptic = parse_obj_optics(front)
        backoptic = try
            # allow e.g. obj |> first |> _.a.b
            obj_back, backoptic = parse_obj_optics(back)
            if obj_back == esc(:_)
                backoptic
            else
                (esc(back),)
            end
        catch ArgumentError
            backoptic = (esc(back),)
        end
        return obj, tuple(frontoptic..., backoptic...)
    elseif @capture(ex, front_[indices__])
        obj, frontoptic = parse_obj_optics(front)
        if any(need_dynamic_optic, indices)
            @gensym collection
            indices = replace_underscore.(indices, collection)
            dims = length(indices) == 1 ? nothing : 1:length(indices)
            lindices = esc.(lower_index.(collection, indices, dims))
            optic = :($DynamicIndexLens($(esc(collection)) -> ($(lindices...),)))
        else
            index = esc(Expr(:tuple, indices...))
            optic = :($IndexLens($index))
        end
    elseif @capture(ex, front_.property_)
        property isa Union{Symbol,String} || throw(ArgumentError(
            string("Error while parsing :($ex). Second argument to `getproperty` can only be",
                   "a `Symbol` or `String` literal, received `$property` instead.")
        ))
        obj, frontoptic = parse_obj_optics(front)
        optic = :($PropertyLens{$(QuoteNode(property))}())
    elseif @capture(ex, f_(front_))
        obj, frontoptic = parse_obj_optics(front)
        optic = esc(f) # function optic
    else
        obj = esc(ex)
        return obj, ()
    end
    return (obj, tuple(frontoptic..., optic))
end

"""
    opticcompose([optic₁, [optic₂, [optic₃, ...]]])

Compose `optic₁`, `optic₂` etc. There is one subtle point here:
While the two composition orders `(optic₁ ⨟ optic₂) ⨟ optic₃` and `optic₁ ⨟ (optic₂ ⨟ optic₃)` have equivalent semantics, their performance may not be the same.

The `opticcompose` function tries to use a composition order, that the compiler likes. The composition order is therefore not part of the stable API.
"""
opticcompose() = identity
opticcompose(args...) = opcompose(args...)

function parse_obj_optic(ex)
    obj, optics = parse_obj_optics(ex)
    optic = Expr(:call, opticcompose, optics...)
    obj, optic
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
It works by applying `optictransform` to the optic that is used in the customized `@set` macro
at runtime.

# Example
```julia
function mytransform(optic::Lens)::Lens
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
    obj, optic = parse_obj_optic(ref)
    dst = overwrite ? obj : gensym("_")
    val = esc(val)
    ret = if ex.head == :(=)
        :($dst = $set($obj, ($optictransform)($optic), $val))
    else
        op = get_update_op(ex.head)
        f = :($_UpdateOp($op,$val))
        :($dst = $modify($f, $obj, ($optictransform)($optic)))
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
It works by applying `optictransform` to the created optic at runtime.
```julia
# new_optic = mytransform(optic)
macro myoptic(ex)
    opticmacro(mytransform, ex)
end
```
See also [`setmacro`](@ref).
"""
function opticmacro(optictransform, ex)
    obj, optic = parse_obj_optic(ex)
    if obj != esc(:_)
        msg = """Cannot parse optic $ex. Lens expressions must start with _, got $obj instead."""
        throw(ArgumentError(msg))
    end
    :($(optictransform)($optic))
end


_show(io::IO, optic::PropertyLens{field}) where {field} = print(io, "(@optic _.$field)")
_show(io::IO, optic::IndexLens) = print(io, "(@optic _[", join(repr.(optic.indices), ", "), "])")
Base.show(io::IO, optic::Union{IndexLens, PropertyLens}) = _show(io, optic)
Base.show(io::IO, ::MIME"text/plain", optic::Union{IndexLens, PropertyLens}) = _show(io, optic)

# debugging
show_composition_order(optic) = (show_composition_order(stdout, optic); println())
show_composition_order(io::IO, optic) = show(io, optic)
function show_composition_order(io::IO, optic::ComposedOptic)
    print(io, "(")
    show_composition_order(io, optic.outer)
    print(io, " ∘  ")
    show_composition_order(io, optic.inner)
    print(io, ")")
end

