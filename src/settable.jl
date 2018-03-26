export @settable
using MacroTools: prewalk, splitdef, combinedef

macro settable(ex)
    esc(settable(ex))
end

function splitarg_no_default(arg_expr)
    # this is a limitation in `MacroTools.splitarg`. If it is fixed
    # it throws if the default value is a literal nothing in the ast
    # e.g. Expr(:(=), :x, nothing))
    splitvar(arg) =
        @match arg begin
            ::T_ => (nothing, T)
            name_::T_ => (name, T)
            x_ => (x, :Any)
        end
    (is_splat = @capture(arg_expr, arg_expr2_...)) || (arg_expr2 = arg_expr)
    if @capture(arg_expr2, arg_ = default_)
        return (splitvar(arg)..., is_splat)
    else
        return (splitvar(arg_expr2)..., is_splat)
    end
end

argsymbol(arg) = first(splitarg_no_default(arg))
function argsymbol_typed(arg)
    name, T, = splitarg_no_default(arg)
    MacroTools.combinearg(name,T,false,nothing)
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
            newargs = map(argsymbol_typed, def[:args])
            newkwargs = []
            for a in def[:kwargs]
                if argsymbol(a) in fields
                    push!(newargs, argsymbol_typed(a))
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

function add_posonly_constructor(ex::Expr)
    dtype = splittypedef(ex)
    isempty(dtype[:constructors]) && return ex
    push!(dtype[:constructors], posonly_constructor(dtype))
    combinetypedef(dtype)
end

function settable(code)
    M = current_module()
    code = macroexpand(M, code)
    MacroTools.postwalk(code) do ex
        ret = if isstructdef(ex)
            add_posonly_constructor(ex)
        else
            ex
        end
    end
end
