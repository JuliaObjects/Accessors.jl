# # Traversal
#
# This code demonstrates how to use and extend advanced optics.
# The examples are taken from the README.md of the specter clojure library.
# Many of the features here are experimental, please consult the docstrings of the
# involved optics.

using Test
using Accessors

import Accessors: modify, OpticStyle
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
modify(f, obj, ::Vals) = mapvals(f, obj)

# Now we can increment as follows:
out = @set data |> Vals() |> Elements() |> Vals() |> If(iseven) += 1

@test out == (a = [(aa = 1, bb = 3), (cc = 3,)], b = [(dd = 5,)])

# ### Append to nested vector
data = (a = 1:3,)
out = @modify(v -> vcat(v, [4,5]), data.a)

@test out == (a = [1,2,3,4,5],)

# ### Increment last odd number in a sequence

data = 1:4
out = @set data |> filter(isodd, _) |> last += 1
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
data = [[1,2,3,4], Int[], [5,3,2,18], [2,4,6], [12]]
optic = @optic _ |> Elements() |> Elements() |> If(x -> mod(x, 3) == 0)
out = getall(data, optic)
@test out == [3, 3, 18, 6, 12]
@test eltype(out) == Int

# ### Increment the last odd number in a sequence

data = [2, 1, 3, 6, 9, 4, 8]
out = @set data |> filter(isodd, _) |> _[end] += 1
@test out == [2, 1, 3, 6, 10, 4, 8]
@test eltype(out) == Int

# ### Remove nils from a nested sequence

data = (a = [1,2,missing, 3, missing],)
optic = @optic _.a |> filter(!ismissing, _)
out = optic(data)
@test out == [1,2,3]
