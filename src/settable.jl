export @settable
using MacroTools: prewalk
using MacroTools: splitdef, combinedef
using MacroTools: splitstructdef, isstructdef, combinestructdef

macro settable(ex)
    @warn """
    `Setfield.@settable` is planned to be removed. We believe that it is no longer needed.
    Please try to remove it from your code. This might involve fixing some constructor calls,
    but should be easy. If it turns out hard and you believe you have a use case, where `@settable`
    is really crucial, please open an issue in the `Setfield` github repo:
    https://github.com/jw3126/Setfield.jl/issues
    """
    esc(settable(__module__, ex))
end

function arg_type(ex)::Tuple
    @match ex begin
        (name_::T_ = default_) => (name, T  )
        (name_ = default_    ) => (name, Any)
        (name_::T_           ) => (name, T  )
        (name_               ) => (name, Any)
    end
end

argsymbol(arg)::Symbol = first(arg_type(arg))
function argsymbol_typed(arg)::Expr
    name, T, = arg_type(arg)
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

function constructor_has_desired_fields(fields, dconstr::Dict)
    args = dconstr[:args]
    nargs = length(args)
    map(argsymbol, args) == fields[1:nargs] || return false
    Set(map(argsymbol, dconstr[:kwargs])) == Set(fields[nargs+1:end])
end

function best_constructor_template(dtype::Dict)::Dict
    fields = map(first, dtype[:fields])
    constructors = map(splitdef, dtype[:constructors])
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

function posonly_constructor_dict(dtype::Dict)::Dict
    def = best_constructor_template(dtype)::Dict
    fields = map(first, dtype[:fields])
    arg_dict = Dict(argsymbol(arg) => arg for arg in def[:args])
    kwarg_dict = Dict(argsymbol(arg) => arg for arg in def[:kwargs])
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

function posonly_constructor(dtype::Dict)::Expr
    combinedef(posonly_constructor_dict(dtype))
end

function add_posonly_constructor(ex::Expr)::Expr
    dtype = splitstructdef(ex)
    if isempty(dtype[:constructors])
        ex
    elseif has_posonly_constructor(dtype)
        ex
    else
        push!(dtype[:constructors], posonly_constructor(dtype))
        @assert has_posonly_constructor(dtype)
        combinestructdef(dtype)
    end
end

function settable(M, code)::Expr
    code = macroexpand(M, code)
    MacroTools.postwalk(code) do ex
        ret = if isstructdef(ex)
            add_posonly_constructor(ex)
        else
            ex
        end
    end
end
