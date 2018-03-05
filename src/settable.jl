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
            newargs = copy(def[:args])
            newkwargs = []
            for a in def[:kwargs]
                if argsymbol(a) in fields
                    push!(newargs, a)
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
    dtype = splittypedef(ex)
    isempty(dtype[:constructors]) && return ex
    M = current_module()
    ex = macroexpand(M, ex)
    dtype = splittypedef(ex)
    if has_posonly_constructor(dtype)
        return ex
    else
        push!(dtype[:constructors], posonly_constructor(dtype))
        return combinetypedef(dtype)
    end
end
