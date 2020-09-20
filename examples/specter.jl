# # Traversal
# These examples are taken from the README.md of the specter clojure library.
# Many of the features here are experimental, please consult the docstrings of the
# involved optics.

using Test
using Accessors

import Accessors: modify, OpticStyle
using Accessors: ModifyBased, SetBased, setindex
"""
    mapvals(f, d)

Apply `f` to all values of and `AbstractDict`.
```jldoctest
julia> using Accessors: mapvals

julia> mapvals(x -> 2x, Dict(:a => 1, :b => 2)) == Dict(:a => 2, :b => 4)
true
```
"""
function mapvals(f, d)
    Dict(k => f(v) for (k,v) in pairs(d))
end

mapvals(f, nt::NamedTuple) = map(f, nt)
"""
    mapkeys(f, d)

Apply `f` to all keys of and `AbstractDict`.
```jldoctest
julia> using Accessors: mapkeys

julia> mapkeys(string, Dict(:a => 1, :b => 2)) == Dict("a" => 1, "b" => 2)
true
```
"""
function mapkeys(f, d)
    Dict(f(k) => v for (k,v) in pairs(d))
end

function mapkeys(f, nt::NamedTuple)
    kw = map(pairs(nt)) do (key, val)
        f(key) => val
    end
    (;kw...)
end

struct Keys end
OpticStyle(::Type{Keys}) = ModifyBased()
modify(f, obj, ::Keys) = mapkeys(f, obj)

struct Vals end
OpticStyle(::Type{Vals}) = ModifyBased()
modify(f, obj, ::Vals) = mapvals(f, obj)

struct Filter{F}
    keep_condition::F
end
OpticStyle(::Type{<:Filter}) = ModifyBased()
(o::Filter)(x) = filter(o.keep_condition, x)
function modify(f, obj, optic::Filter)
    I = eltype(eachindex(obj))
    inds = I[]
    for i in eachindex(obj)
        x = obj[i]
        if optic.keep_condition(x)
            push!(inds, i)
        end
    end
    vals = f(obj[inds])
    setindex(obj, vals, inds)
end


# ### Increment all even numbers
data = (a = [(aa=1, bb=2), (cc=3,)], b = [(dd=4,)])

out = @set data |> Vals() |> Elements() |> Vals() |> With(iseven) += 1

@test out == (a = [(aa = 1, bb = 3), (cc = 3,)], b = [(dd = 5,)])

# ### Append to nested vector
data = (a = 1:3,)

optic = @lens _.a
out = modify(v -> vcat(v, [4,5]), data, optic)

@test out == (a = [1,2,3,4,5],)

# ### Increment last odd number in a sequence

data = 1:4
out = @set data |> Filter(isodd) |> last += 1
@test out == [1,2,4,4]

### Map over a sequence

data = 1:3
out = @set data |> Elements() += 1
@test out == [2,3,4]

# ### Increment all values in a nested Dict

data = Dict(:a => Dict(:aa =>1), :b => Dict(:ba => -1, :bb => 2))
out = @set data |> Vals() |> Vals() += 1
@test out == Dict(:a => Dict(:aa => 2),:b => Dict(:bb => 3,:ba => 0))

# ### Increment all the even values for :a keys in a sequence of maps

data = [Dict(:a => 1), Dict(:a => 2), Dict(:a => 4), Dict(:a => 3)]
out = @set data |> Elements() |> _[:a] += 1
@test out == [Dict(:a => 2), Dict(:a => 3), Dict(:a => 5), Dict(:a => 4)]

# ### Retrieve every number divisible by 3 out of a sequence of sequences

function getall(obj, optic)
    out = Any[]
    modify(obj, optic) do val
        push!(out, val)
    end
    out
end

data = [[1,2,3,4],[], [5,3,2,18],[2,4,6], [12]]
optic = @lens _ |> Elements() |> Elements() |> With(x -> mod(x, 3) == 0)
out = getall(data, optic)
@test out == [3, 3, 18, 6, 12]
@test_broken eltype(out) == Int

# ### Increment the last odd number in a sequence

data = [2, 1, 3, 6, 9, 4, 8]
out = @set data |> Filter(isodd) |> _[end] += 1
@test out == [2, 1, 3, 6, 10, 4, 8]
@test_broken eltype(out) == Int

# ### Remove nils from a nested sequence

data = (a = [1,2,missing, 3, missing],)
optic = @lens _.a |> Filter(!ismissing)
out = optic(data)
@test out == [1,2,3]
