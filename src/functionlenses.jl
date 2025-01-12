# first and last on general indexable collections
set(obj, ::typeof(first), val) = @set obj[firstindex(obj)] = val
set(obj, ::typeof(last), val) = @set obj[lastindex(obj)] = val
delete(obj, ::typeof(first)) = delete(obj, IndexLens((firstindex(obj),)))
delete(obj, ::typeof(last)) = delete(obj, IndexLens((lastindex(obj),)))
insert(obj, ::typeof(first), val) = insert(obj, IndexLens((firstindex(obj),)), val)
insert(obj, ::typeof(last), val) = insert(obj, IndexLens((lastindex(obj) + 1,)), val)

set(obj, o::Base.Fix2{typeof(first)}, val) = @set obj[firstindex(obj):(firstindex(obj) + o.x - 1)] = val
set(obj, o::Base.Fix2{typeof(last)}, val) = @set obj[(lastindex(obj) - o.x + 1):lastindex(obj)] = val
delete(obj, o::Base.Fix2{typeof(first)}) = @delete obj[firstindex(obj):(firstindex(obj) + o.x - 1)]
delete(obj, o::Base.Fix2{typeof(last)}) = @delete obj[(lastindex(obj) - o.x + 1):lastindex(obj)]
insert(obj, o::Base.Fix2{typeof(first)}, val) = @insert obj[firstindex(obj):(firstindex(obj) + o.x - 1)] = val
insert(obj, o::Base.Fix2{typeof(last)}, val) = @insert obj[(lastindex(obj) + 1):(lastindex(obj) + o.x)] = val

# first and last on ranges
# they don't support delete() with arbitrary index, so special casing is needed
delete(obj::AbstractRange, ::typeof(first)) = obj[begin+1:end]
delete(obj::AbstractRange, ::typeof(last)) = obj[begin:end-1]
delete(obj::AbstractRange, o::Base.Fix2{typeof(first)}) = obj[begin+o.x:end]
delete(obj::AbstractRange, o::Base.Fix2{typeof(last)}) = obj[begin:end-o.x]


set(obj::Tuple, ::typeof(Base.front), val::Tuple) = (val..., last(obj))
set(obj::Tuple, ::typeof(Base.tail), val::Tuple) = (first(obj), val...)

function set(obj, ::typeof(only), val)
    only(obj) # error check
    set(obj, first, val)
end

function set(x::TX, f::Base.Fix1{typeof(convert)}, v) where {TX}
    v isa f.x || throw(ArgumentError("convert($(f.x), _) cannot have type $(typeof(v))"))
    convert(TX, v)
end

set(obj::Tuple, ::Type{Tuple}, val::Tuple) = val
set(obj::NamedTuple{KS}, ::Type{Tuple}, val::Tuple) where {KS} = NamedTuple{KS}(val)
set(obj::CartesianIndex, ::Type{Tuple}, val::Tuple) = CartesianIndex(val)
set(obj::AbstractVector, ::Type{Tuple}, val::Tuple) = similar(obj, eltype(val)) .= val

set(obj, ::Type{NamedTuple{KS}}, val::NamedTuple) where {KS} = set(obj, Tuple, values(NamedTuple{KS}(val)))
function set(obj::NamedTuple, ::Type{NamedTuple{KS}}, val::NamedTuple) where {KS}
    length(KS) == length(val) || throw(ArgumentError("Cannot assign NamedTuple with keys $(keys(val)) to NamedTuple with keys $KS"))
    setproperties(obj, NamedTuple{KS}(val))
end

set(obj, ::typeof(Base.splat(=>)), val::Pair) = @set Tuple(obj) = Tuple(val)

set(obj, ::typeof(getproperties), val::NamedTuple) = setproperties(obj, val)

set(x::Union{Tuple,NamedTuple}, ::typeof(propertynames), names) = set(x, propertynames, Tuple(names))
function set(x::Union{Tuple,NamedTuple}, ::typeof(propertynames), names::Tuple)
    length(names) == length(x) || throw(ArgumentError("Got $(length(names)) for $(length(x)) properties"))
    if eltype(names) === Symbol
        NamedTuple{names}(Tuple(x))
    elseif eltype(names) <: Integer && names == ntuple(identity, length(names))
        Tuple(x)
    else
        throw(ArgumentError("invalid property names: $names"))
    end
end

################################################################################
##### eltype
################################################################################
set(obj::Array, ::typeof(eltype), T::Type) = collect(T, obj)
set(obj::Number, ::typeof(eltype), T::Type) = T(obj)
set(obj::Type{<:Number}, ::typeof(eltype), ::Type{T}) where {T} = T
set(obj::Type{<:Array{<:Any,N}}, ::typeof(eltype), ::Type{T}) where {N,T} = Array{T,N}
set(obj::Type{<:Dict}, ::typeof(eltype), ::Type{Pair{K,V}}) where {K,V} = Dict{K,V}
set(obj::Dict, ::typeof(eltype), ::Type{T}) where {T} = set(typeof(obj), eltype, T)(obj)

set(obj::Dict, lens::Union{typeof(keytype),typeof(valtype)}, T::Type) =
    set(typeof(obj), lens, T)(obj)
set(obj::Type{<:Dict{<:Any,V}}, lens::typeof(keytype), ::Type{K}) where {K,V} = Dict{K,V}
set(obj::Type{<:Dict{K}}, lens::typeof(valtype), ::Type{V}) where {K,V} = Dict{K,V}

################################################################################
##### arrays
################################################################################
set(obj, ::typeof(size), v::Tuple) = reshape(obj, v)

# set vec(): keep array shape and type, change its values
function set(x::AbstractArray, ::typeof(vec), v::AbstractVector)
    res = similar(x, eltype(v))
    vec(res) .= v
    res
end

# set reverse(): keep collection type, change its values
set(::Tuple, ::typeof(reverse), v) = reverse(Tuple(v))
set(x::NamedTuple, ::typeof(reverse), v) = @set reverse(Tuple(x)) = v
function set(x::AbstractVector, ::typeof(reverse), v)
    res = similar(x, eltype(v))
    res .= v
    reverse!(res)
    res
end


set(obj, o::Base.Fix1{typeof(map)}, val) = map((ob, v) -> set(ob, o.x, v), obj, val)

set(obj, o::Base.BroadcastFunction, val) = set.(obj, Ref(o.f), val)
set(obj, o::Base.Fix1{<:Base.BroadcastFunction}, val) = set.(obj, Base.Fix1.(Ref(o.f.f), o.x), val)
set(obj, o::Base.Fix2{<:Base.BroadcastFunction}, val) = set.(obj, Base.Fix2.(Ref(o.f.f), o.x), val)

set(obj, o::Base.Fix1{typeof(filter)}, val) = @set obj[findall(o.x, obj)] = val
modify(f, obj, o::Base.Fix1{typeof(filter)}) = @modify(f, obj[findall(o.x, obj)])
delete(obj, o::Base.Fix1{typeof(filter)}) = filter(!o.x, obj)

set(obj, o::typeof(skipmissing), val) = @set obj |> filter(!ismissing, _) = collect(val)
modify(f, obj, o::typeof(skipmissing)) = @modify(f, obj |> filter(!ismissing, _))

set(obj, ::typeof(sort), val) = @set obj[sortperm(obj)] = val
modify(f, obj, ::typeof(sort)) = @modify(f, obj[sortperm(obj)])

################################################################################
##### os
################################################################################
set(path, ::typeof(splitext), (stem, ext))     = string(stem, ext)
set(path, ::typeof(splitdir), (dir, last))     = joinpath(dir, last)
set(path, ::typeof(splitdrive), (drive, rest)) = joinpath(drive, rest)
set(path, ::typeof(splitpath), pieces)         = joinpath(pieces...)
set(path, ::typeof(dirname), new_name)         = @set splitdir(path)[1] = new_name
set(path, ::typeof(basename), new_name)        = @set splitdir(path)[2] = new_name
delete(path, ::typeof(basename)) = dirname(path)
delete(path, ::typeof(dirname)) = basename(path)

################################################################################
##### math
################################################################################
set(x::T,  ::typeof(real), y) where {T} = T === real(T) ? y : y + im*imag(x)
set(x,     ::typeof(imag), y) = real(x) + im*y
set(x,    ::typeof(angle), y) = abs(x) * cis(y)
function set(x, ::typeof(abs), y)
    y >= zero(y) || throw(DomainError(y, "cannot set abs($x) to $y"))
    s = sign(x)
    iszero(s) ? y * one(x) : y * s
end
set(x, ::typeof(abs2), y) = set(x, abs, √y)

set(x, ::typeof(mod2pi), y) = set(x, @optic(mod(_, 2π)), y)
set(x, f::Base.Fix2{typeof(fld)}, y) = set(x, @optic(first(fldmod(_, f.x))), y)
set(x, f::Base.Fix2{typeof(mod)}, y) = set(x, @optic(last(fldmod(_, f.x))), y)
set(x, f::Base.Fix2{typeof(div)}, y) = set(x, @optic(first(divrem(_, f.x))), y)
set(x, f::Base.Fix2{typeof(rem)}, y) = set(x, @optic(last(divrem(_, f.x))), y)
set(x, f::Base.Fix2{typeof(mod),<:AbstractUnitRange}, y) = @set mod($x - first(f.x), length(f.x)) + first(f.x) = y

set(x::AbstractString, f::Base.Fix1{typeof(parse), Type{T}}, y::T) where {T} = string(y)

set(f, ::typeof(inverse), invf) = setinverse(f, invf)

set(obj, ::typeof(Base.splat(atan)), val) = @set Tuple(obj) = hypot(obj...) .* sincos(val)
function set(obj, ::typeof(Base.splat(hypot)), val)
    omul = iszero(val) ? oneunit(hypot(obj...)) : hypot(obj...)
    map(Base.Fix2(*, val / omul), obj)
end

################################################################################
##### strings
################################################################################

function set(s::AbstractString, o::Base.Fix2{typeof(first)}, v::AbstractString)
    length(v) == o.x || throw(DimensionMismatch("tried to assign $(length(v)) elements to $(o.x) destinations"))
    v * chop(s; head=o.x, tail=0)
end

function set(s::AbstractString, o::Base.Fix2{typeof(last)}, v::AbstractString)
    length(v) == o.x || throw(DimensionMismatch("tried to assign $(length(v)) elements to $(o.x) destinations"))
    chop(s; head=0, tail=o.x) * v
end

delete(s::AbstractString, o::typeof(first)) = chop(s; head=1, tail=0)
delete(s::AbstractString, o::typeof(last)) = chop(s; head=0, tail=1)
delete(s::AbstractString, o::Base.Fix2{typeof(first)}) = chop(s; head=o.x, tail=0)
delete(s::AbstractString, o::Base.Fix2{typeof(last)}) = chop(s; head=0, tail=o.x)

set(s::AbstractString, o::typeof(chomp), v) = endswith(s, '\n') ? v * '\n' : v
set(s::AbstractString, o::Base.Fix2{typeof(chopsuffix), <:AbstractString}, v) = endswith(s, o.x) ? v * o.x : v
set(s::AbstractString, o::Base.Fix2{typeof(chopprefix), <:AbstractString}, v) = startswith(s, o.x) ? o.x * v : v

set(s::AbstractString, ::typeof(strip), v) = @set lstrip(rstrip(s)) = v
set(s::AbstractString, ::typeof(lstrip), v) = @set s |> lstrip(isspace, _) = v
set(s::AbstractString, ::typeof(rstrip), v) = @set s |> rstrip(isspace, _) = v

set(s::AbstractString, o::Base.Fix1{typeof(strip)}, v) = @set s |> lstrip(o.x, rstrip(o.x, _)) = v
function set(s::AbstractString, o::Base.Fix1{typeof(lstrip)}, v)
    ix = findfirst(!o.x, s)
    isnothing(ix) && (ix = nextind(s, lastindex(s)))
    s[1:prevind(s, ix)] * v
end
function set(s::AbstractString, o::Base.Fix1{typeof(rstrip)}, v)
    ix = findlast(!o.x, s)
    isnothing(ix) && (ix = prevind(s, firstindex(s)))
    v * s[nextind(s, ix):end]
end

function set(s::AbstractString, o::Base.Fix2{typeof(split), <:Union{AbstractChar,AbstractString}}, v)
    any(c -> occursin(o.x, c), v) && throw(ArgumentError("split components cannot contain the delimiter $(repr(o.x))"))
    join(v, o.x)
end

if isdefined(Base, :AnnotatedString)
    # 1.11+
    using Base: AnnotatedString, AnnotatedChar, annotations

    set(s::AbstractString, ::typeof(annotations), anns) = AnnotatedString(s, anns)
    set(s::AnnotatedString, ::typeof(annotations), anns) = AnnotatedString(s.string, anns)
    delete(s::AnnotatedString, ::typeof(annotations)) = s.string
    insert(s::AbstractString, ::typeof(annotations), anns) = AnnotatedString(s, anns)

    set(s::AbstractChar, ::typeof(annotations), anns) = AnnotatedChar(s, anns)
    set(s::AnnotatedChar, ::typeof(annotations), anns) = AnnotatedChar(s.char, anns)
    delete(s::AnnotatedChar, ::typeof(annotations)) = s.char
    insert(s::AbstractChar, ::typeof(annotations), anns) = AnnotatedChar(s, anns)
end
