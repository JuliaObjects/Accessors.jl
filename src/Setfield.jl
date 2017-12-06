module Setfield

using ArgCheck
export @set

function setfield_impl(obj, val, field::Symbol)
    T = obj
    @argcheck field ∈ fieldnames(T)
    fieldvals = map(fieldnames(T)) do fn
        fn == field ? :(val) : :(obj.$fn)
    end
    Expr(:block,
        Expr(:meta, :inline),
        Expr(:call, T, fieldvals...)
    )
end
@generated function setfield(obj, val, ::Val{field}) where {field}
    setfield_impl(obj,val,field)
end

function setdeepfield_impl(obj, val, path::NTuple{N,Symbol}) where {N}
    @argcheck N > 0
    @argcheck length(path) > 0
    head = first(path)
    vhead = QuoteNode(Val{first(path)}())
    vtail = QuoteNode(Val{Base.tail(path)}())
    ex = if N == 1
        quote
            setfield(obj, val, $vhead)
        end
    else
        quote
            inner_object = obj.$(first(path))
            inner = setdeepfield(inner_object, val, $vtail)
            setfield(obj, inner, $vhead)
        end
    end
    unshift!(ex.args, Expr(:meta, :inline))
    ex
end

@generated function setdeepfield(obj, val, ::Val{path}) where {path}
    setdeepfield_impl(obj, val, path)
end

dotsplit(s::Symbol) = (s,)
function dotsplit(ex::Expr)
    # :(a.b.c) -> (:a, :b, :c)
    @assert Meta.isexpr(ex, :(.))
    @assert length(ex.args) == 2
    front, qlast = ex.args
    last = unquote(qlast)
    @assert last isa Symbol
    tuple(dotsplit(front)..., last)
end

function unquote(ex::QuoteNode)
    ex.value
end
function unquote(ex::Expr)
    @assert Meta.isexpr(ex, :quote)
    @assert length(ex.args) == 1
    first(ex.args)
end

function obj_val_path(ex)
    # obj_val_path(:(obj.p.a.th = val)) -> (:obj, :val, (:p, :a, :th))
    @argcheck Meta.isexpr(ex, :(=))
    @assert length(ex.args) == 2
    ex_path, val = ex.args
    obj_path = dotsplit(ex_path)
    obj = first(obj_path)
    path = Base.tail(obj_path)
    obj, val, path
end

macro set(ex)
    obj, val, path = obj_val_path(ex)
    vpath = QuoteNode(Val{path}())
    :(Setfield.setdeepfield($(esc(obj)), $(esc(val)), $vpath))
end

end
