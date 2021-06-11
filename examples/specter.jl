# # Traversal
#
# This code demonstrates how to use and extend advanced optics.
# The examples are taken from the README.md of the specter clojure library.
# Many of the features here are experimental, please consult the docstrings of the
# involved optics.

using Test
using Accessors

import Accessors: modify_stateful, OpticStyle
using Accessors: ModifyBased, SetBased, setindex

# ### Increment all even numbers
# We have the following data and the goal is to increment all nested even numbers.
data = (a = [(aa=1, bb=2), (cc=3,)], b = [(dd=4,)])
# To acomplish this, we define a new optic `Vals`.
function mapvals(f, d)
    Dict(k => f(v) for (k,v) in pairs(d))
end

mapvals(f, nt::NamedTuple) = map(f, nt)

struct Vals end
OpticStyle(::Type{Vals}) = ModifyBased()
function modify_stateful(f, obj_state, ::Vals)
    obj, state = obj_state
    new_obj = mapvals(obj) do val
        new_val, state = f((val, state))
        new_val
    end
    new_obj, state
end

# Now we can increment as follows:
out = @set data |> Vals() |> Elements() |> Vals() |> If(iseven) += 1

@test out == (a = [(aa = 1, bb = 3), (cc = 3,)], b = [(dd = 5,)])

struct Filter{F}
    keep_condition::F
end
OpticStyle(::Type{<:Filter}) = ModifyBased()
(o::Filter)(x) = filter(o.keep_condition, x)
function modify_stateful(f, obj_state, optic::Filter)
    obj, state = obj_state
    I = eltype(eachindex(obj))
    inds = I[]
    for i in eachindex(obj)
        x = obj[i]
        if optic.keep_condition(x)
            push!(inds, i)
        end
    end
    vals,new_state = f((obj[inds],state))
    new_obj = setindex(obj, vals, inds)
    new_obj, new_state
end


# ### Append to nested vector
data = (a = 1:3,)
out = @modify(v -> vcat(v, [4,5]), data.a)

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
optic = @optic _ |> Elements() |> Elements() |> If(x -> mod(x, 3) == 0)
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
optic = @optic _.a |> Filter(!ismissing)
out = optic(data)
@test out == [1,2,3]
