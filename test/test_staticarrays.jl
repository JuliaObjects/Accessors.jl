using StaticArrays

obj = StaticArrays.@SMatrix [1 2; 3 4]
l = @lens _[2,1]
@test get(l, obj) == 3
@test_broken set(l, obj, 5) == StaticArrays.@SMatrix [1 2; 5 4]
@test_broken setindex(obj, 5, 2, 1) == StaticArrays.@SMatrix [1 2; 5 4]
