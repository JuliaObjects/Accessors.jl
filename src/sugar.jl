export @set, @optic, @o, @reset, @modify, @delete, @insert, @accessor, ∗, ∗ₚ
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

    @delete obj_optic

Define an optic and call [`delete`](@ref) on it.
```jldoctest
julia> using Accessors

julia> xs = (1,2,3);

julia> ys = @delete xs[2]
(1, 3)
```
Supports the same syntax as [`@optic`](@ref). See also [`@set`](@ref).
"""
macro delete(ex)
    obj, optic = parse_obj_optic(ex)
    Expr(:call, delete, obj, optic)
end

"""
    @insert assignment

Return a modified copy of deeply nested objects.

# Example
```jldoctest
julia> using Accessors

julia> t = (a=1, b=2);

julia> @insert t.c = 5
(a = 1, b = 2, c = 5)

julia> t
(a = 1, b = 2)
```

Supports the same syntax as [`@optic`](@ref). See also [`@set`](@ref).
"""
macro insert(ex)
    insertmacro(identity, ex, overwrite=false)
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

foldtree(op, init, x) = op(init, x)
foldtree(op, init, ex::Expr) =
    op(foldl((acc, x) -> foldtree(op, acc, x), ex.args; init=init), ex)

need_dynamic_optic(ex) =
    foldtree(false, ex) do yes, x
        yes || x === :end || (x === :begin) || x === :_
    end

replace_underscore(ex, to) = postwalk(x -> x === :_ ? to : x, ex)

function lower_index(collection::Symbol, index, dim)
    index = MacroTools.replace(
        index, :end,
        dim === nothing ? :($(Base.lastindex)($collection)) : :($(Base.lastindex)($collection, $dim))
    )
    index = MacroTools.replace(
        index, :begin,
        dim === nothing ? :($(Base.firstindex)($collection)) : :($(Base.firstindex)($collection, $dim))
    )
end

_secondarg(_, x) = x

_esc_and_dot_name_to_broadcasted(f) = esc(f)
_esc_and_dot_name_to_broadcasted(f::Symbol) =
    if f == :.
        # eg, in @set a[:] .= 1
        # the returned function will be called as func(a, 1)
        :(Base.BroadcastFunction($_secondarg))
    elseif startswith(string(f), '.')
        # eg, in @set a[:] .+= 1 or @optic _ .+ 1
        :(Base.BroadcastFunction($(esc(Symbol(string(f)[2:end])))))
    else
        esc(f)
    end

function parse_obj_optics(ex)
    dollar_exprs = foldtree([], ex) do exs, x
        x isa Expr && x.head == :$ ?
            push!(exs, only(x.args)) :
            exs
    end
    if !isempty(dollar_exprs)
        length(dollar_exprs) == 1 || error("Only a single dollar-expression is supported")
        # obj is the only dollar-expression:
        obj = esc(only(dollar_exprs))
        # parse expr with an underscore instead of the dollar-expression:
        _, optics = parse_obj_optics(postwalk(x -> x isa Expr && x.head == :$ ? :_ : x, ex))
        return obj, optics
    end

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
        property isa Union{Int,Symbol,String} || throw(ArgumentError(
            string("Error while parsing :($ex). Second argument to `getproperty` can only be",
                   "an `Int`, `Symbol` or `String` literal, received `$property` instead.")
        ))
        obj, frontoptic = parse_obj_optics(front)
        optic = :($PropertyLens{$(QuoteNode(property))}())
    elseif @capture(ex, f_(front_))
        # regular function call
        obj, frontoptic = parse_obj_optics(front)
        optic = _esc_and_dot_name_to_broadcasted(f)  # broadcasted operators like .- fall here
    elseif @capture(ex, f_.(front_))
        # broadcasted function call (not operator)
        obj, frontoptic = parse_obj_optics(front)
        optic = :(Base.BroadcastFunction($(esc(f))))
    elseif @capture(ex, f_(args__))
        # function call with multiple arguments
        args_contain_under = map(args) do arg
            foldtree((yes, x) -> yes || x === :_, false, arg)
        end
        if !any(args_contain_under)
            # as if f(args...) didn't match
            obj = esc(ex)
            return obj, ()
        end
        length(args) == 2 || error("Only 1- and 2-argument functions are supported")
        sum(args_contain_under) == 1 || error("Only a single function argument can be the optic target")
        f = _esc_and_dot_name_to_broadcasted(f)  # multi-arg broadcasted fall here, no matter if regular function or operator
        if args_contain_under[1]
            obj, frontoptic = parse_obj_optics(args[1])
            optic = :(Base.Fix2($f, $(esc(args[2]))))
        elseif args_contain_under[2]
            obj, frontoptic = parse_obj_optics(args[2])
            optic = :(Base.Fix1($f, $(esc(args[1]))))
        end
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
    if !(ex.head isa Symbol) || (length(ex.args) != 2)
        msg = """
        Invalid expression for set macro. Got: 
        $(ex)
        """
        throw(ArgumentError(msg))
    end
    ref, val = ex.args
    obj, optic = parse_obj_optic(ref)
    val = esc(val)
    ret = if ex.head == :(=)
        :($set($obj, ($optictransform)($optic), $val))
    else
        op = get_update_op(ex.head)
        f = :($Base.Fix2($(_esc_and_dot_name_to_broadcasted(op)), $val))
        :($modify($f, $obj, ($optictransform)($optic)))
    end
    return _macro_expression_result(obj, ret; overwrite=overwrite)
end

"""
    insertmacro(optictransform, ex::Expr; overwrite::Bool=false)

This function can be used to create a customized variant of [`@insert`](@ref).
It works by applying `optictransform` to the optic that is used in the customized `@insert` macro at runtime.

# Example
```julia
function mytransform(optic::Lens)::Lens
    ...
end
macro myinsert(ex)
    insertmacro(mytransform, ex)
end
```
See also [`opticmacro`](@ref),  [`setmacro`](@ref).
"""
function insertmacro(optictransform, ex::Expr; overwrite::Bool=false)
    if (ex.head != :(=)) || (length(ex.args) != 2)
        msg = """
        Expression for insert macro must be an assignment. Got:
        $(ex)
        """
        throw(ArgumentError(msg))
    end

    ref, val = ex.args
    obj, optic = parse_obj_optic(ref)
    val = esc(val)
    ret = :($insert($obj, ($optictransform)($optic), $val))
    return _macro_expression_result(obj, ret; overwrite=overwrite)
end

_macro_expression_result(obj, ret; overwrite) =
    if overwrite
        @assert Meta.isexpr(obj, :escape)
        only(obj.args) isa Symbol || throw(ArgumentError("Rebinding macros can only be used with plain variables as targets. Got expression: $obj"))
        return :($obj = $ret)
    else
        return ret
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
(@optic _.b.a.b)

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


"""
    @accessor func

Given a simple getter function, define the corresponding `set` method automatically.

# Example
```julia
julia> @accessor my_func(x) = x.a

julia> my_func((a=1, b=2))
1

julia> set((a=1, b=2), my_func, 100)
(a = 100, b = 2)
```
"""
macro accessor(ex)
    def = splitdef(ex)
    fname = def[:name]
    length(def[:args]) == 1 || throw(ArgumentError("@accessor only supports single argument functions. Overload `Accessors.set(obj, ::typeof($(def[:name])), v)` manually."))
    arg = only(def[:args])
    argname = splitarg(arg)[1]
    body_optic = MacroTools.replace(def[:body], argname, :_)
    farg = if @capture fname name_::T__
        fname
    else
        ftype = :(
            ::if $fname isa Function
                typeof($fname)
            elseif $fname isa Type
                Type{$fname}
            else
                # is it possible at all?
                error("Unsupported accessor $(fname)::$(typeof($fname))")
            end
        )
    end
    valarg = gensym(:v)
    quote
        Base.@__doc__ $ex
        $Accessors.set($arg, $farg, $valarg) = $set($argname, $Accessors.@optic($body_optic), $valarg)
    end |> esc
end

### shortcuts:
# optic macro
const var"@o" = var"@optic"

# Elements, Properties
const ∗ = Elements()
const ∗ₚ = Properties()
IndexLens(::Tuple{Elements}) = Elements()
IndexLens(::Tuple{Properties}) = Properties()

### nice show() for optics
_shortstring(prev, o::PropertyLens{field}) where {field} = "$prev.$field"
_shortstring(prev, o::IndexLens) ="$prev[$(join(repr.(o.indices), ", "))]"
_shortstring(prev, o::Function) = "$o($prev)"
_shortstring(prev, o::Base.Fix1) = "$(o.f)($(o.x), $prev)"
_shortstring(prev, o::Base.Fix2) = "$(o.f)($prev, $(o.x))"
_shortstring(prev, o::Elements) = "$prev[∗]"
_shortstring(prev, o::Properties) = "$prev[∗ₚ]"

function show_optic(io, optic)
    opts = deopcompose(optic)
    inner = Iterators.takewhile(x -> applicable(_shortstring, "", x), opts)
    outer = Iterators.dropwhile(x -> applicable(_shortstring, "", x), opts)
    if !isempty(outer)
        show(io, opcompose(outer...))
        print(io, " ∘ ")
    end
    shortstr = reduce(_shortstring, inner; init="_")
    if get(io, :compact, false)
        print(io, shortstr)
    else
        print(io, "(@optic ", shortstr, ")")
    end
end

const _OpticsTypes = Union{IndexLens,PropertyLens,Elements,Properties}

Base.show(io::IO, optic::_OpticsTypes) = show_optic(io, optic)
Base.show(io::IO, ::MIME"text/plain", optic::_OpticsTypes) = show(io, optic)

# only need show(io, optic) here because Base defines show(io::IO, ::MIME"text/plain", c::ComposedFunction) = show(io, c)
Base.show(io::IO, optic::ComposedFunction{<:Any, <:_OpticsTypes}) = show_optic(io, optic)
# resolve method ambiguity with Base:
Base.show(io::IO, optic::ComposedFunction{typeof(!), <:_OpticsTypes}) = show_optic(io, optic)

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

