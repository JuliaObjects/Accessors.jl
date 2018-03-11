export @settable
using MacroTools: prewalk, splitdef, combinedef
macro settable(ex)
    esc(settable(ex))
end

argsymbol(s::Symbol) = s

function argsymbol(ex::Expr)::Symbol
    if isexpr(ex, :(::))
        return argsymbol(ex.args[1])
    elseif isexpr(ex, :kw)
        return argsymbol(ex.args[1])
    else
        error("Unsupported expression: $(ex)")
    end
end

"""
    strip_default_value(s::Symbol)
    strip_default_value(ex::Expr)

Strip-off the value part when `ex` is a key-value expression.
It is an identity function for `Symbol`.
"""
strip_default_value(s::Symbol) = s

function strip_default_value(ex::Expr)
    arg = if isexpr(ex, :kw)
        ex.args[1]
    else
        ex
    end
    @assert arg isa Symbol || isexpr(arg, :(::))
    return arg
end

function has_posonly_constructor(dtype::Dict)
    fields = map(first, dtype[:fields])
    for constructor in dtype[:constructors]
        args = map(argsymbol, splitdef(constructor)[:args])
        if args == fields
            return true
        end
    end
    return false
end

function posonly_constructor_dict(dtype::Dict)
    fields = map(first, dtype[:fields])
    for constructor in dtype[:constructors]
        def = splitdef(constructor)
        args = map(argsymbol, def[:args])
        kwargs = map(argsymbol, def[:kwargs])
        if fields[1:length(args)] == args &&
                Set(fields[length(args)+1:end]) <= Set(kwargs)
            newargs = map(strip_default_value, def[:args])
            newkwargs = []
            for a in def[:kwargs]
                if argsymbol(a) in fields
                    push!(newargs, strip_default_value(a))
                else
                    push!(newkwargs, a)
                end
            end
            return Dict(def...,
                        :args => newargs,
                        :kwargs => newkwargs)
        end
    end
    error("""
          There is no appropriate inner constructor.  At least one
          constructor has to have positional or keyword arguments with
          name matching with the struct fields.
          """)
end

function posonly_constructor(dtype::Dict)
    combinedef(posonly_constructor_dict(dtype))
end

function settable(ex)
    is_trivial_struct(ex) && return ex
    M = current_module()
    ex = macroexpand(M, ex)
    return _settable(ex)
end

_settable(ex::Expr) = _settable(Val{ex.head}, ex)
_settable(x) = x

function _settable(::Type{Val{STRUCTSYMBOL}}, ex)
    dtype = splittypedef(ex)
    if has_posonly_constructor(dtype)
        return ex
    else
        push!(dtype[:constructors], posonly_constructor(dtype))
        return combinetypedef(dtype)
    end
end

_settable(::Union{Type{Val{:toplevel}},
                  Type{Val{:block}}},
          ex) =
    Expr(ex.head, _settable.(ex.args)...)

_settable(::Type{<: Val}, ex) = ex
