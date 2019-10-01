module Experimental
using Setfield
using ConstructionBase: constructorof
import Setfield: get, set
export MultiPropertyLens

const NNamedTupleLens{N,s} = NamedTuple{s, T} where {T <: NTuple{N, Lens}}
struct MultiPropertyLens{L <: NNamedTupleLens} <: Lens
    lenses::L
end

_keys(::Type{MultiPropertyLens{NamedTuple{s,T}}}) where {s,T} = s
@generated function get(obj, l::MultiPropertyLens)
    get_arg(fieldname) = :($fieldname = get(obj.$fieldname, l.lenses.$fieldname))
    args = map(get_arg, _keys(l))
    Expr(:tuple, args...)
end

@generated function set(obj, l::MultiPropertyLens, val)
    T = obj
    args = map(fieldnames(T)) do fn
        if fn in _keys(l)
            quote
                obj_inner = obj.$fn
                lens_inner = l.lenses.$fn
                val_inner = val.$fn
                set(obj_inner, lens_inner, val_inner)
            end
        else
            :(obj.$fn)
        end
    end
    Expr(:block,
        Expr(:meta, :inline),
        Expr(:call, :(constructorof($T)), args...)
    )
end

function Base.show(io::IO, l::MultiPropertyLens)
    print(io, "MultiPropertyLens(")
    print(io, l.lenses)
    print(io, ')')
end
end
