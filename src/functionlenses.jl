set(obj, ::FunctionLens{last}, val) = @set obj[length(obj)] = val
set(obj, ::FunctionLens{first}, val) = @set obj[1] = val
