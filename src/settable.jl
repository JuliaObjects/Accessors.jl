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

function constructor_has_desired_fields(fields, d::Dict)
    args = d[:args]
    nargs = length(args)
    map(argsymbol, args) == fields[1:nargs] || return false
    Set(map(argsymbol, d[:kwargs])) == Set(fields[nargs+1:end])
end

function best_constructor_template(d)
    fields = map(first, d[:fields])
    constructors = map(splitdef, d[:constructors])
    constructors = filter(d -> constructor_has_desired_fields(fields, d), constructors)
    if isempty(constructors)
        error("""
              There is no appropriate inner constructor.  At least one
              constructor has to have positional or keyword arguments with
              name matching with the struct fields.
              """)
    end
    nparams(c) = haskey(c, :params) ? length(c[:params]) : 0
    nargs(c) = haskey(c, :args) ? length(c[:args]) : 0
    min_nparams = minimum(nparams,constructors)
    constructors = filter(c -> nparams(c) == min_nparams, constructors)
    max_nargs = maximum(nargs, constructors)
    filter(c->nargs(c) == max_nargs, constructors)
    first(constructors)
end

function posonly_constructor_dict(dtype::Dict)
    def = best_constructor_template(dtype)::Dict
    fields = map(first, dtype[:fields])
    arg_dict = Dict(first(splitarg(arg)) => arg for arg in def[:args])
    kwarg_dict = Dict(first(splitarg(arg)) => arg for arg in def[:kwargs])
    newargs = []
    for field in fields
        if haskey(arg_dict, field)
            newarg = arg_dict[field]
        else
            newarg = kwarg_dict[field]
            delete!(kwarg_dict, field)
        end
        push!(newargs, argsymbol_typed(newarg))
    end
    newkwargs = collect(values(kwarg_dict))
    def[:args] = newargs
    def[:kwargs] = newkwargs
    def
end

function posonly_constructor(dtype::Dict)
    combinedef(posonly_constructor_dict(dtype))
end

function add_posonly_constructor(ex::Expr)
    dtype = splittypedef(ex)
    isempty(dtype[:constructors]) && return ex
    has_posonly_constructor(dtype) && return ex
    push!(dtype[:constructors], posonly_constructor(dtype))
    @assert has_posonly_constructor(dtype)
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
