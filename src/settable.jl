export @settable
using MacroTools: prewalk, splitdef, combinedef
macro settable(ex)
    esc(settable(ex))
end

function default_constructor_dict(dtype::Dict)
    fieldsymbols = map(first, dtype[:fields])
    body = splitdef(first(dtype[:constructors]))[:body]
    Dict(:params => dtype[:params],
    :body => body,
    :name => dtype[:name],
    :whereparams => dtype[:params],
    :args => map(combinefield, dtype[:fields]),
    :kwargs => [],
    # :rtype => dtype[:name]
    )
end
function default_constructor(dtype::Dict)
    combinedef(default_constructor_dict(dtype))
end
function settable(ex)
    dtype = splittypedef(ex)
    isempty(dtype[:constructors]) && return ex
    M = current_module()
    ex = macroexpand(M, ex)
    dtype = splittypedef(ex)
    
    push!(dtype[:constructors], default_constructor(dtype))
    typedef = combinetypedef(dtype)
    quote
        $typedef
    end
end

