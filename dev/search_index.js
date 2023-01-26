var documenterSearchIndex = {"docs":
[{"location":"examples/custom_macros/","page":"Custom Macros","title":"Custom Macros","text":"EditURL = \"https://github.com/JuliaObjects/Accessors.jl/blob/master/examples/custom_macros.jl\"","category":"page"},{"location":"examples/custom_macros/#Extending-@set-and-@optic","page":"Custom Macros","title":"Extending @set and @optic","text":"","category":"section"},{"location":"examples/custom_macros/","page":"Custom Macros","title":"Custom Macros","text":"This code demonstrates how to extend the @set and @optic mechanism with custom lenses. As a demo, we want to implement @mylens! and @myreset, which work much like @optic and @set, but mutate objects instead of returning modified copies.","category":"page"},{"location":"examples/custom_macros/","page":"Custom Macros","title":"Custom Macros","text":"using Accessors\nusing Accessors: IndexLens, PropertyLens, ComposedOptic\n\nstruct Lens!{L}\n    pure::L\nend\n\n(l::Lens!)(o) = l.pure(o)\nfunction Accessors.set(o, l::Lens!{<: ComposedOptic}, val)\n    o_inner = l.pure.inner(o)\n    set(o_inner, Lens!(l.pure.outer), val)\nend\nfunction Accessors.set(o, l::Lens!{PropertyLens{prop}}, val) where {prop}\n    setproperty!(o, prop, val)\n    o\nend\nfunction Accessors.set(o, l::Lens!{<:IndexLens}, val)\n    o[l.pure.indices...] = val\n    o\nend","category":"page"},{"location":"examples/custom_macros/","page":"Custom Macros","title":"Custom Macros","text":"Now this implements the kind of lens the new macros should use. Of course there are more variants like Lens!(<:DynamicIndexLens), for which we might want to overload set, but lets ignore that. Instead we want to check, that everything works so far:","category":"page"},{"location":"examples/custom_macros/","page":"Custom Macros","title":"Custom Macros","text":"using Test\nmutable struct M\n    a\n    b\nend\n\no = M(1,2)\nl = Lens!(@optic _.b)\nset(o, l, 20)\n@test o.b == 20\n\nl = Lens!(@optic _.foo[1])\no = (foo=[1,2,3], bar=:bar)\nset(o, l, 100)\n@test o == (foo=[100,2,3], bar=:bar)","category":"page"},{"location":"examples/custom_macros/","page":"Custom Macros","title":"Custom Macros","text":"Now we can implement the syntax macros","category":"page"},{"location":"examples/custom_macros/","page":"Custom Macros","title":"Custom Macros","text":"using Accessors: setmacro, opticmacro, modifymacro\n\nmacro myreset(ex)\n    setmacro(Lens!, ex)\nend\n\nmacro mylens!(ex)\n    opticmacro(Lens!, ex)\nend\n\nmacro mymodify!(f, ex)\n    modifymacro(Lens!, f, ex)\nend\n\no = M(1,2)\n@myreset o.a = :hi\n@myreset o.b += 98\n@test o.a == :hi\n@test o.b == 100\n\no = M(1,3)\n@mymodify!(x -> x+1, o.a)\n@test o.a === 2\n@test o.b === 3\n\ndeep = [[[[1]]]]\n@myreset deep[1][1][1][1] = 2\n@test deep[1][1][1][1] === 2\n\nl = @mylens! _.foo[1]\no = (foo=[1,2,3], bar=:bar)\nset(o, l, 100)\n@test o == (foo=[100,2,3], bar=:bar)","category":"page"},{"location":"examples/custom_macros/","page":"Custom Macros","title":"Custom Macros","text":"Everything works, we can do arbitrary nesting and also use += syntax etc.","category":"page"},{"location":"examples/custom_macros/","page":"Custom Macros","title":"Custom Macros","text":"","category":"page"},{"location":"examples/custom_macros/","page":"Custom Macros","title":"Custom Macros","text":"This page was generated using Literate.jl.","category":"page"},{"location":"examples/custom_optics/","page":"Custom Optics","title":"Custom Optics","text":"EditURL = \"https://github.com/JuliaObjects/Accessors.jl/blob/master/examples/custom_optics.jl\"","category":"page"},{"location":"examples/custom_optics/#Custom-optics","page":"Custom Optics","title":"Custom optics","text":"","category":"section"},{"location":"examples/custom_optics/","page":"Custom Optics","title":"Custom Optics","text":"This guide demonstrates how to implement new kinds of optics. There are multiple possibilities, the most straight forward one is function lenses","category":"page"},{"location":"examples/custom_optics/#Function-lenses","page":"Custom Optics","title":"Function lenses","text":"","category":"section"},{"location":"examples/custom_optics/","page":"Custom Optics","title":"Custom Optics","text":"Say we are dealing with points in the plane and polar coordinates are of interest:","category":"page"},{"location":"examples/custom_optics/","page":"Custom Optics","title":"Custom Optics","text":"struct Point\n    x::Float64\n    y::Float64\nend\n\nfunction Base.isapprox(pt1::Point, pt2::Point; kw...)\n    return isapprox([pt1.x,pt1.y], [pt2.x, pt2.y]; kw...)\nend\n\nfunction polar(pt::Point)\n    r = sqrt(pt.x^2 + pt.y^2)\n    θ = atan(pt.y,pt.x)\n    return (r=r, θ=θ)\nend\n\nfunction Point_from_polar(rθ)\n    r, θ = rθ\n    x = cos(θ)*r\n    y = sin(θ)*r\n    return Point(x,y)\nend","category":"page"},{"location":"examples/custom_optics/","page":"Custom Optics","title":"Custom Optics","text":"It would certainly be ergonomic to do things like @set polar(pt) = ... @set polar(pt).θ = ... @set polar(pt).r = 1 To enable this, a function lens can be implemented:","category":"page"},{"location":"examples/custom_optics/","page":"Custom Optics","title":"Custom Optics","text":"using Accessors\nusing Test\nAccessors.set(pt, ::typeof(polar), rθ) = Point_from_polar(rθ)","category":"page"},{"location":"examples/custom_optics/","page":"Custom Optics","title":"Custom Optics","text":"And now it is possible to do","category":"page"},{"location":"examples/custom_optics/","page":"Custom Optics","title":"Custom Optics","text":"pt = Point(2,0)\npt2 = @set polar(pt).r = 5\n@test pt2 ≈ Point(5,0)\n\npt3 = @set polar(pt).θ = π/2\n@test pt3 ≈ Point(0, 2)","category":"page"},{"location":"examples/custom_optics/#Modify-based-optics","page":"Custom Optics","title":"Modify based optics","text":"","category":"section"},{"location":"examples/custom_optics/","page":"Custom Optics","title":"Custom Optics","text":"Say we have a Dict and we want to update all of its keys. This can be done as follows:","category":"page"},{"location":"examples/custom_optics/","page":"Custom Optics","title":"Custom Optics","text":"function mapkeys(f, d::Dict)\n    return Dict(f(k) => v for (k,v) in pairs(d))\nend","category":"page"},{"location":"examples/custom_optics/","page":"Custom Optics","title":"Custom Optics","text":"Lets make this more ergonomic by defining an optic for it","category":"page"},{"location":"examples/custom_optics/","page":"Custom Optics","title":"Custom Optics","text":"using Accessors\nstruct Keys end\nAccessors.OpticStyle(::Type{Keys}) = ModifyBased()\nAccessors.modify(f, obj, ::Keys) = mapkeys(f, obj)","category":"page"},{"location":"examples/custom_optics/","page":"Custom Optics","title":"Custom Optics","text":"It can be used as follows:","category":"page"},{"location":"examples/custom_optics/","page":"Custom Optics","title":"Custom Optics","text":"obj = Dict(\"A\" =>1, \"B\" => 2, \"C\" => 3)\nobj2 = @modify(lowercase, obj |> Keys())\n@test obj2 == Dict(\"a\" =>1, \"b\" => 2, \"c\" => 3)","category":"page"},{"location":"examples/custom_optics/","page":"Custom Optics","title":"Custom Optics","text":"","category":"page"},{"location":"examples/custom_optics/","page":"Custom Optics","title":"Custom Optics","text":"This page was generated using Literate.jl.","category":"page"},{"location":"lenses/#Lenses","page":"Lenses","title":"Lenses","text":"","category":"section"},{"location":"lenses/","page":"Lenses","title":"Lenses","text":"Accessors.jl is build around so called lenses. A Lens allows to access or replace deeply nested parts of complicated objects.","category":"page"},{"location":"lenses/#Example","page":"Lenses","title":"Example","text":"","category":"section"},{"location":"lenses/","page":"Lenses","title":"Lenses","text":"julia> using Accessors\n\njulia> struct T;a;b; end\n\njulia> obj = T(\"AA\", \"BB\");\n\njulia> lens = @optic _.a\n(@optic _.a)\n\njulia> lens(obj)\n\"AA\"\n\njulia> set(obj, lens, 2)\nT(2, \"BB\")\n\njulia> obj # the object was not mutated, instead an updated copy was created\nT(\"AA\", \"BB\")\n\njulia> modify(lowercase, obj, lens)\nT(\"aa\", \"BB\")","category":"page"},{"location":"lenses/","page":"Lenses","title":"Lenses","text":"Lenses can also be constructed directly and composed with opcompose, ⨟, or ∘ (note reverse order).","category":"page"},{"location":"lenses/","page":"Lenses","title":"Lenses","text":"julia> using Accessors\n\njulia> v = (a = 1:3, )\n(a = 1:3,)\n\njulia> l = opcompose(PropertyLens(:a), IndexLens(1))\n(@optic _.a[1])\n\njulia> l ≡ @optic _.a[1]   # equivalent to macro form\ntrue\n\njulia> l(v)\n1\n\njulia> set(v, l, 3)\n(a = [3, 2, 3],)","category":"page"},{"location":"lenses/#Interface","page":"Lenses","title":"Interface","text":"","category":"section"},{"location":"lenses/","page":"Lenses","title":"Lenses","text":"Implementing lenses is straight forward. They can be of any type and just need to implement the following interface:","category":"page"},{"location":"lenses/","page":"Lenses","title":"Lenses","text":"Accessors.set(obj, lens, val)\nlens(obj)","category":"page"},{"location":"lenses/","page":"Lenses","title":"Lenses","text":"These must be pure functions, that satisfy the three lens laws:","category":"page"},{"location":"lenses/","page":"Lenses","title":"Lenses","text":"@assert lens(set(obj, lens, val)) ≅ val\n        # You get what you set.\n@assert set(obj, lens, lens(obj)) ≅ obj\n        # Setting what was already there changes nothing.\n@assert set(set(obj, lens, val1), lens, val2) ≅ set(obj, lens, val2)\n        # The last set wins.","category":"page"},{"location":"lenses/","page":"Lenses","title":"Lenses","text":"Here ≅ is an appropriate notion of equality or an approximation of it. In most contexts this is simply ==. But in some contexts it might be ===, ≈, isequal or something else instead. For instance == does not work in Float64 context, because get(set(obj, lens, NaN), lens) == NaN can never hold. Instead isequal or ≅(x::Float64, y::Float64) = isequal(x,y) | x ≈ y are possible alternatives.","category":"page"},{"location":"lenses/","page":"Lenses","title":"Lenses","text":"See also @optic, set, modify.","category":"page"},{"location":"getting_started/#Getting-started","page":"Getting started","title":"Getting started","text":"","category":"section"},{"location":"getting_started/","page":"Getting started","title":"Getting started","text":"Say you have a NamedTuple and you want to update it:","category":"page"},{"location":"getting_started/","page":"Getting started","title":"Getting started","text":"julia> x = (greeting=\"Hello\", name=\"World\")\n(greeting = \"Hello\", name = \"World\")\n\njulia> x.greeting = \"Hi\"\nERROR: setfield!: immutable struct of type NamedTuple cannot be changed\n[...]","category":"page"},{"location":"getting_started/","page":"Getting started","title":"Getting started","text":"This fails, because named tuples are immutable. Instead you can use Accessors to carry out the update:","category":"page"},{"location":"getting_started/","page":"Getting started","title":"Getting started","text":"julia> using Accessors\n\njulia> @set x.greeting = \"Hi\"\n(greeting = \"Hi\", name = \"World\")\n\njulia> x # still the same. Accessors did not overwrite x, it just created an updated copy\n(greeting = \"Hello\", name = \"World\")\n\njulia> x_new = @set x.greeting = \"Hi\" # typically you will assign a name to the updated copy\n(greeting = \"Hi\", name = \"World\")","category":"page"},{"location":"getting_started/","page":"Getting started","title":"Getting started","text":"Accessors.jl does not only support NamedTuple, but arbitrary structs and nested updates.","category":"page"},{"location":"getting_started/","page":"Getting started","title":"Getting started","text":"julia> struct HelloWorld\n           greeting::String\n           name::String\n       end\n\njulia> x = HelloWorld(\"hi\", \"World\")\nHelloWorld(\"hi\", \"World\")\n\njulia> @set x.name = \"Accessors\" # update a struct\nHelloWorld(\"hi\", \"Accessors\")\n\njulia> x = (a=1, b=(c=3, d=4))\n(a = 1, b = (c = 3, d = 4))\n\njulia> @set x.b.c = 10 # nested update\n(a = 1, b = (c = 10, d = 4))","category":"page"},{"location":"getting_started/","page":"Getting started","title":"Getting started","text":"Accessors.jl does not only support updates of properties, but also index updates.","category":"page"},{"location":"getting_started/","page":"Getting started","title":"Getting started","text":"julia> x = (10,20,21)\n(10, 20, 21)\n\njulia> @set x[3] = 30\n(10, 20, 30)","category":"page"},{"location":"getting_started/","page":"Getting started","title":"Getting started","text":"In fact Accessors.jl supports many more notions of update:","category":"page"},{"location":"getting_started/","page":"Getting started","title":"Getting started","text":"julia> x = [1,2,3];\n\njulia> x_new = @set eltype(x) = UInt8;\n\njulia> @show x_new;\nx_new = UInt8[0x01, 0x02, 0x03]","category":"page"},{"location":"getting_started/","page":"Getting started","title":"Getting started","text":"Accessors.jl is very composable, which means different updates can be nested and combined.","category":"page"},{"location":"getting_started/","page":"Getting started","title":"Getting started","text":"julia> data = (a = (b = (1,2),), c=3)\n(a = (b = (1, 2),), c = 3)\n\njulia> @set data.a.b[end] = 20\n(a = (b = (1, 20),), c = 3)\n\njulia> @set splitext(\"some_file.py\")[2] = \".jl\"\n\"some_file.jl\"","category":"page"},{"location":"examples/specter/","page":"Traversal","title":"Traversal","text":"EditURL = \"https://github.com/JuliaObjects/Accessors.jl/blob/master/examples/specter.jl\"","category":"page"},{"location":"examples/specter/#Traversal","page":"Traversal","title":"Traversal","text":"","category":"section"},{"location":"examples/specter/","page":"Traversal","title":"Traversal","text":"This code demonstrates how to use and extend advanced optics. The examples are taken from the README.md of the specter clojure library. Many of the features here are experimental, please consult the docstrings of the involved optics.","category":"page"},{"location":"examples/specter/","page":"Traversal","title":"Traversal","text":"using Test\nusing Accessors\n\nimport Accessors: modify, OpticStyle\nusing Accessors: ModifyBased, SetBased, setindex","category":"page"},{"location":"examples/specter/#Increment-all-even-numbers","page":"Traversal","title":"Increment all even numbers","text":"","category":"section"},{"location":"examples/specter/","page":"Traversal","title":"Traversal","text":"We have the following data and the goal is to increment all nested even numbers.","category":"page"},{"location":"examples/specter/","page":"Traversal","title":"Traversal","text":"data = (a = [(aa=1, bb=2), (cc=3,)], b = [(dd=4,)])","category":"page"},{"location":"examples/specter/","page":"Traversal","title":"Traversal","text":"To acomplish this, we define a new optic Vals.","category":"page"},{"location":"examples/specter/","page":"Traversal","title":"Traversal","text":"function mapvals(f, d)\n    Dict(k => f(v) for (k,v) in pairs(d))\nend\n\nmapvals(f, nt::NamedTuple) = map(f, nt)\n\nstruct Vals end\nOpticStyle(::Type{Vals}) = ModifyBased()\nmodify(f, obj, ::Vals) = mapvals(f, obj)","category":"page"},{"location":"examples/specter/","page":"Traversal","title":"Traversal","text":"Now we can increment as follows:","category":"page"},{"location":"examples/specter/","page":"Traversal","title":"Traversal","text":"out = @set data |> Vals() |> Elements() |> Vals() |> If(iseven) += 1\n\n@test out == (a = [(aa = 1, bb = 3), (cc = 3,)], b = [(dd = 5,)])\n\nstruct Filter{F}\n    keep_condition::F\nend\nOpticStyle(::Type{<:Filter}) = ModifyBased()\n(o::Filter)(x) = filter(o.keep_condition, x)\nfunction modify(f, obj, optic::Filter)\n    I = eltype(eachindex(obj))\n    inds = I[]\n    for i in eachindex(obj)\n        x = obj[i]\n        if optic.keep_condition(x)\n            push!(inds, i)\n        end\n    end\n    vals = f(obj[inds])\n    setindex(obj, vals, inds)\nend","category":"page"},{"location":"examples/specter/#Append-to-nested-vector","page":"Traversal","title":"Append to nested vector","text":"","category":"section"},{"location":"examples/specter/","page":"Traversal","title":"Traversal","text":"data = (a = 1:3,)\nout = @modify(v -> vcat(v, [4,5]), data.a)\n\n@test out == (a = [1,2,3,4,5],)","category":"page"},{"location":"examples/specter/#Increment-last-odd-number-in-a-sequence","page":"Traversal","title":"Increment last odd number in a sequence","text":"","category":"section"},{"location":"examples/specter/","page":"Traversal","title":"Traversal","text":"data = 1:4\nout = @set data |> Filter(isodd) |> last += 1\n@test out == [1,2,4,4]\n\n### Map over a sequence\n\ndata = 1:3\nout = @set data |> Elements() += 1\n@test out == [2,3,4]","category":"page"},{"location":"examples/specter/#Increment-all-values-in-a-nested-Dict","page":"Traversal","title":"Increment all values in a nested Dict","text":"","category":"section"},{"location":"examples/specter/","page":"Traversal","title":"Traversal","text":"data = Dict(:a => Dict(:aa =>1), :b => Dict(:ba => -1, :bb => 2))\nout = @set data |> Vals() |> Vals() += 1\n@test out == Dict(:a => Dict(:aa => 2),:b => Dict(:bb => 3,:ba => 0))","category":"page"},{"location":"examples/specter/#Increment-all-the-even-values-for-:a-keys-in-a-sequence-of-maps","page":"Traversal","title":"Increment all the even values for :a keys in a sequence of maps","text":"","category":"section"},{"location":"examples/specter/","page":"Traversal","title":"Traversal","text":"data = [Dict(:a => 1), Dict(:a => 2), Dict(:a => 4), Dict(:a => 3)]\nout = @set data |> Elements() |> _[:a] += 1\n@test out == [Dict(:a => 2), Dict(:a => 3), Dict(:a => 5), Dict(:a => 4)]","category":"page"},{"location":"examples/specter/#Retrieve-every-number-divisible-by-3-out-of-a-sequence-of-sequences","page":"Traversal","title":"Retrieve every number divisible by 3 out of a sequence of sequences","text":"","category":"section"},{"location":"examples/specter/","page":"Traversal","title":"Traversal","text":"function getall(obj, optic)\n    out = Any[]\n    modify(obj, optic) do val\n        push!(out, val)\n    end\n    out\nend\n\ndata = [[1,2,3,4],[], [5,3,2,18],[2,4,6], [12]]\noptic = @optic _ |> Elements() |> Elements() |> If(x -> mod(x, 3) == 0)\nout = getall(data, optic)\n@test out == [3, 3, 18, 6, 12]\n@test_broken eltype(out) == Int","category":"page"},{"location":"examples/specter/#Increment-the-last-odd-number-in-a-sequence","page":"Traversal","title":"Increment the last odd number in a sequence","text":"","category":"section"},{"location":"examples/specter/","page":"Traversal","title":"Traversal","text":"data = [2, 1, 3, 6, 9, 4, 8]\nout = @set data |> Filter(isodd) |> _[end] += 1\n@test out == [2, 1, 3, 6, 10, 4, 8]\n@test eltype(out) == Int","category":"page"},{"location":"examples/specter/#Remove-nils-from-a-nested-sequence","page":"Traversal","title":"Remove nils from a nested sequence","text":"","category":"section"},{"location":"examples/specter/","page":"Traversal","title":"Traversal","text":"data = (a = [1,2,missing, 3, missing],)\noptic = @optic _.a |> Filter(!ismissing)\nout = optic(data)\n@test out == [1,2,3]","category":"page"},{"location":"examples/specter/","page":"Traversal","title":"Traversal","text":"","category":"page"},{"location":"examples/specter/","page":"Traversal","title":"Traversal","text":"This page was generated using Literate.jl.","category":"page"},{"location":"examples/molecules/","page":"Molecules","title":"Molecules","text":"EditURL = \"https://github.com/JuliaObjects/Accessors.jl/blob/master/examples/molecules.jl\"","category":"page"},{"location":"examples/molecules/#Molecules","page":"Molecules","title":"Molecules","text":"","category":"section"},{"location":"examples/molecules/","page":"Molecules","title":"Molecules","text":"inspired by https://hackage.haskell.org/package/lens-tutorial-1.0.3/docs/Control-Lens-Tutorial.html","category":"page"},{"location":"examples/molecules/","page":"Molecules","title":"Molecules","text":"using Accessors\nusing Test\n\nmolecule = (\n    name=\"water\",\n    atoms=[\n        (name=\"H\", position=(x=0,y=1)), # in reality the angle is about 104deg\n        (name=\"O\", position=(x=0,y=0)),\n        (name=\"H\", position=(x=1,y=0)),\n    ]\n)\n\noc = @optic _.atoms |> Elements() |> _.position.x\nres_modify = modify(x->x+1, molecule, oc)\n\nres_macro = @set molecule.atoms |> Elements() |> _.position.x += 1\n@test res_macro == res_modify\n\nres_expected = (\n    name=\"water\",\n    atoms=[\n        (name=\"H\", position=(x=1,y=1)),\n        (name=\"O\", position=(x=1,y=0)),\n        (name=\"H\", position=(x=2,y=0)),\n    ]\n)\n\n@test res_expected == res_macro\n\nres_set = set(molecule, oc, 4.0)\nres_macro = @set molecule.atoms |> Elements() |> _.position.x = 4.0\n@test res_macro == res_set\n\nres_expected = (\n    name=\"water\",\n    atoms=[\n        (name=\"H\", position=(x=4.0,y=1)),\n        (name=\"O\", position=(x=4.0,y=0)),\n        (name=\"H\", position=(x=4.0,y=0)),\n    ]\n)\n@test res_expected == res_set","category":"page"},{"location":"examples/molecules/","page":"Molecules","title":"Molecules","text":"","category":"page"},{"location":"examples/molecules/","page":"Molecules","title":"Molecules","text":"This page was generated using Literate.jl.","category":"page"},{"location":"#Accessors","page":"Home","title":"Accessors","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"(Image: DocStable) (Image: DocDev) (Image: CI)","category":"page"},{"location":"","page":"Home","title":"Home","text":"The goal of Accessors.jl is to make updating immutable data simple. It is the successor of Setfield.jl.","category":"page"},{"location":"#Usage","page":"Home","title":"Usage","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Updating immutable data was never easier:","category":"page"},{"location":"","page":"Home","title":"Home","text":"using Accessors\n@set obj.a.b.c = d","category":"page"},{"location":"","page":"Home","title":"Home","text":"To get started, see this tutorial and/or watch this video:","category":"page"},{"location":"","page":"Home","title":"Home","text":"(Image: JuliaCon2020 Changing the immutable)","category":"page"},{"location":"#Featured-extensions","page":"Home","title":"Featured extensions","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"AccessorsExtra.jl [docs] implements setters for types from other packages and includes additional optics","category":"page"},{"location":"internals/#Internals","page":"Internals","title":"Internals","text":"","category":"section"},{"location":"internals/","page":"Internals","title":"Internals","text":"Modules = [Accessors]\nPublic = false","category":"page"},{"location":"internals/#Accessors.insertmacro-Tuple{Any, Expr}","page":"Internals","title":"Accessors.insertmacro","text":"insertmacro(optictransform, ex::Expr; overwrite::Bool=false)\n\nThis function can be used to create a customized variant of @insert. It works by applying optictransform to the optic that is used in the customized @insert macro at runtime.\n\nExample\n\nfunction mytransform(optic::Lens)::Lens\n    ...\nend\nmacro myinsert(ex)\n    insertmacro(mytransform, ex)\nend\n\nSee also opticmacro,  setmacro.\n\n\n\n\n\n","category":"method"},{"location":"internals/#Accessors.mapproperties-Tuple{Any, Any}","page":"Internals","title":"Accessors.mapproperties","text":"mapproperties(f, obj)\n\nConstruct a copy of obj, with each property replaced by the result of applying f to it.\n\njulia> using Accessors\n\njulia> obj = (a=1, b=2);\n\njulia> Accessors.mapproperties(x -> x+1, obj)\n(a = 2, b = 3)\n\nImplementation\n\nThis function should not be overloaded directly. Instead both of\n\nConstructionBase.getproperties\nConstructionBase.setproperties\n\nshould be overloaded. This function/method/type is experimental. It can be changed or deleted at any point without warning\n\n\n\n\n\n","category":"method"},{"location":"internals/#Accessors.opticcompose-Tuple{}","page":"Internals","title":"Accessors.opticcompose","text":"opticcompose([optic₁, [optic₂, [optic₃, ...]]])\n\nCompose optic₁, optic₂ etc. There is one subtle point here: While the two composition orders (optic₁ ⨟ optic₂) ⨟ optic₃ and optic₁ ⨟ (optic₂ ⨟ optic₃) have equivalent semantics, their performance may not be the same.\n\nThe opticcompose function tries to use a composition order, that the compiler likes. The composition order is therefore not part of the stable API.\n\n\n\n\n\n","category":"method"},{"location":"internals/#Accessors.opticmacro-Tuple{Any, Any}","page":"Internals","title":"Accessors.opticmacro","text":"opticmacro(optictransform, ex::Expr)\n\nThis function can be used to create a customized variant of @optic. It works by applying optictransform to the created optic at runtime.\n\n# new_optic = mytransform(optic)\nmacro myoptic(ex)\n    opticmacro(mytransform, ex)\nend\n\nSee also setmacro.\n\n\n\n\n\n","category":"method"},{"location":"internals/#Accessors.setmacro-Tuple{Any, Expr}","page":"Internals","title":"Accessors.setmacro","text":"setmacro(optictransform, ex::Expr; overwrite::Bool=false)\n\nThis function can be used to create a customized variant of @set. It works by applying optictransform to the optic that is used in the customized @set macro at runtime.\n\nExample\n\nfunction mytransform(optic::Lens)::Lens\n    ...\nend\nmacro myset(ex)\n    setmacro(mytransform, ex)\nend\n\nSee also opticmacro.\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#Docstrings","page":"Docstrings","title":"Docstrings","text":"","category":"section"},{"location":"docstrings/","page":"Docstrings","title":"Docstrings","text":"Modules = [Accessors]\nPrivate = false","category":"page"},{"location":"docstrings/#Accessors.Elements","page":"Docstrings","title":"Accessors.Elements","text":"Elements\n\nAccess all elements of a collection that implements map.\n\njulia> using Accessors\n\njulia> obj = (1,2,3);\n\njulia> set(obj, Elements(), 0)\n(0, 0, 0)\n\njulia> modify(x -> 2x, obj, Elements())\n(2, 4, 6)\n\nThis function/method/type is experimental. It can be changed or deleted at any point without warning\n\n\n\n\n\n","category":"type"},{"location":"docstrings/#Accessors.If","page":"Docstrings","title":"Accessors.If","text":"If(modify_condition)\n\nRestric access to locations for which modify_condition holds.\n\njulia> using Accessors\n\njulia> obj = (1,2,3,4,5,6);\n\njulia> @set obj |> Elements() |> If(iseven) *= 10\n(1, 20, 3, 40, 5, 60)\n\nThis function/method/type is experimental. It can be changed or deleted at any point without warning\n\n\n\n\n\n","category":"type"},{"location":"docstrings/#Accessors.IndexLens-Tuple{Vararg{Integer}}","page":"Docstrings","title":"Accessors.IndexLens","text":"IndexLens(indices::Tuple)\nIndexLens(indices::Integer...)\n\nConstruct a lens for accessing an element of an object at indices via [].\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#Accessors.Properties","page":"Docstrings","title":"Accessors.Properties","text":"Properties()\n\nAccess all properties of an objects.\n\njulia> using Accessors\n\njulia> obj = (a=1, b=2, c=3)\n(a = 1, b = 2, c = 3)\n\njulia> set(obj, Properties(), \"hi\")\n(a = \"hi\", b = \"hi\", c = \"hi\")\n\njulia> modify(x -> 2x, obj, Properties())\n(a = 2, b = 4, c = 6)\n\nBased on mapproperties.\n\nThis function/method/type is experimental. It can be changed or deleted at any point without warning\n\n\n\n\n\n","category":"type"},{"location":"docstrings/#Accessors.PropertyLens-Tuple{Any}","page":"Docstrings","title":"Accessors.PropertyLens","text":"PropertyLens{fieldname}()\nPropertyLens(fieldname)\n\nConstruct a lens for accessing a property fieldname of an object.\n\nThe second constructor may not be type stable when fieldname is not a constant.\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#Accessors.Recursive","page":"Docstrings","title":"Accessors.Recursive","text":"Recursive(descent_condition, optic)\n\nApply optic recursively as long as descent_condition holds.\n\njulia> using Accessors\n\njulia> obj = (a=missing, b=1, c=(d=missing, e=(f=missing, g=2)))\n(a = missing, b = 1, c = (d = missing, e = (f = missing, g = 2)))\n\njulia> set(obj, Recursive(!ismissing, Properties()), 100)\n(a = 100, b = 1, c = (d = 100, e = (f = 100, g = 2)))\n\njulia> obj = (1,2,(3,(4,5),6))\n(1, 2, (3, (4, 5), 6))\n\njulia> modify(x -> 100x, obj, Recursive(x -> (x isa Tuple), Elements()))\n(100, 200, (300, (400, 500), 600))\n\n\n\n\n\n","category":"type"},{"location":"docstrings/#Accessors.delete","page":"Docstrings","title":"Accessors.delete","text":"delete(obj, optic)\n\nDelete a part according to optic of obj.\n\njulia> using Accessors\n\njulia> obj = (a=1, b=2); lens=@optic _.a;\n\njulia> delete(obj, lens)\n(b = 2,)\n\n\n\n\n\n","category":"function"},{"location":"docstrings/#Accessors.getall","page":"Docstrings","title":"Accessors.getall","text":"getall(obj, optic)\n\nExtract all parts of obj that are selected by optic. Returns a flat Tuple of values, or an AbstractVector if the selected parts contain arrays.\n\nThis function is experimental and we might change the precise output container in the future.\n\nSee also setall.\n\njulia> using Accessors\n\njulia> obj = (a=1, b=(2, 3));\n\njulia> getall(obj, @optic _.a)\n(1,)\n\njulia> getall(obj, @optic _ |> Elements() |> last)\n(1, 3)\n\n\n\n\n\n","category":"function"},{"location":"docstrings/#Accessors.insert","page":"Docstrings","title":"Accessors.insert","text":"insert(obj, optic, val)\n\nInsert a part according to optic into obj with the value val.\n\njulia> using Accessors\n\njulia> obj = (a=1, b=2); lens=@optic _.c; val = 100;\n\njulia> insert(obj, lens, val)\n(a = 1, b = 2, c = 100)\n\nSee also set.\n\n\n\n\n\n","category":"function"},{"location":"docstrings/#Accessors.modify","page":"Docstrings","title":"Accessors.modify","text":"modify(f, obj, optic)\n\nReplace a part x of obj by f(x). The optic argument selects which part to replace.\n\njulia> using Accessors\n\njulia> obj = (a=1, b=2); optic=@optic _.a; f = x -> \"hello $x\";\n\njulia> modify(f, obj, optic)\n(a = \"hello 1\", b = 2)\n\nSee also set.\n\n\n\n\n\n","category":"function"},{"location":"docstrings/#Accessors.set","page":"Docstrings","title":"Accessors.set","text":"set(obj, optic, val)\n\nReplace a part according to optic of obj by val.\n\njulia> using Accessors\n\njulia> obj = (a=1, b=2); lens=@optic _.a; val = 100;\n\njulia> set(obj, lens, val)\n(a = 100, b = 2)\n\nSee also modify.\n\n\n\n\n\n","category":"function"},{"location":"docstrings/#Accessors.setall","page":"Docstrings","title":"Accessors.setall","text":"setall(obj, optic, values)\n\nReplace a part of obj that is selected by optic with values. The values collection should have the same number of elements as selected by optic.\n\nThis function is experimental and might change in the future.\n\nSee also getall, set. The former is dual to setall:\n\njulia> using Accessors\n\njulia> obj = (a=1, b=(2, 3));\n\njulia> optic = @optic _ |> Elements() |> last;\n\njulia> getall(obj, optic)\n(1, 3)\n\njulia> setall(obj, optic, (4, 5))\n(a = 4, b = (2, 5))\n\n\n\n\n\n","category":"function"},{"location":"docstrings/#CompositionsBase.opcompose","page":"Docstrings","title":"CompositionsBase.opcompose","text":"optic₁ ⨟ optic₂\n\nCompose optics optic₁, optic₂, ..., opticₙ to access nested objects.\n\nExample\n\njulia> using Accessors\n\njulia> obj = (a = (b = (c = 1,),),);\n\njulia> la = @optic _.a\n       lb = @optic _.b\n       lc = @optic _.c\n       lens = la ⨟ lb ⨟ lc\n(@optic _.c) ∘ (@optic _.a.b)\n\njulia> lens(obj)\n1\n\n\n\n\n\n","category":"function"},{"location":"docstrings/#Accessors.@delete-Tuple{Any}","page":"Docstrings","title":"Accessors.@delete","text":"@delete obj_optic\n\nDefine an optic and call delete on it.\n\njulia> using Accessors\n\njulia> xs = (1,2,3);\n\njulia> ys = @delete xs[2]\n(1, 3)\n\nSupports the same syntax as @optic. See also @set.\n\n\n\n\n\n","category":"macro"},{"location":"docstrings/#Accessors.@insert-Tuple{Any}","page":"Docstrings","title":"Accessors.@insert","text":"@insert assignment\n\nReturn a modified copy of deeply nested objects.\n\nExample\n\njulia> using Accessors\n\njulia> t = (a=1, b=2);\n\njulia> @insert t.c = 5\n(a = 1, b = 2, c = 5)\n\njulia> t\n(a = 1, b = 2)\n\nSupports the same syntax as @optic. See also @set.\n\n\n\n\n\n","category":"macro"},{"location":"docstrings/#Accessors.@modify-Tuple{Any, Any}","page":"Docstrings","title":"Accessors.@modify","text":"@modify(f, obj_optic)\n\nDefine an optic and call modify on it.\n\njulia> using Accessors\n\njulia> xs = (1,2,3);\n\njulia> ys = @modify(xs |> Elements() |> If(isodd)) do x\n           x + 1\n       end\n(2, 2, 4)\n\nSupports the same syntax as @optic. See also @set.\n\n\n\n\n\n","category":"macro"},{"location":"docstrings/#Accessors.@optic-Tuple{Any}","page":"Docstrings","title":"Accessors.@optic","text":"@optic\n\nConstruct an optic from property access and similar.\n\nExample\n\njulia> using Accessors\n\njulia> struct T;a;b;end\n\njulia> t = T(\"A1\", T(T(\"A3\", \"B3\"), \"B2\"))\nT(\"A1\", T(T(\"A3\", \"B3\"), \"B2\"))\n\njulia> l = @optic _.b.a.b\n(@optic _.b.a.b)\n\njulia> l(t)\n\"B3\"\n\njulia> set(t, l, 100)\nT(\"A1\", T(T(\"A3\", 100), \"B2\"))\n\njulia> t = (\"one\", \"two\")\n(\"one\", \"two\")\n\njulia> set(t, (@optic _[1]), \"1\")\n(\"1\", \"two\")\n\nSee also @set.\n\n\n\n\n\n","category":"macro"},{"location":"docstrings/#Accessors.@reset-Tuple{Any}","page":"Docstrings","title":"Accessors.@reset","text":"@reset assignment\n\nShortcut for obj = @set obj....\n\nExample\n\njulia> using Accessors\n\njulia> t = (a=1,)\n(a = 1,)\n\njulia> @reset t.a=2\n(a = 2,)\n\njulia> t\n(a = 2,)\n\nSupports the same syntax as @optic. See also @set.\n\n\n\n\n\n","category":"macro"},{"location":"docstrings/#Accessors.@set-Tuple{Any}","page":"Docstrings","title":"Accessors.@set","text":"@set assignment\n\nReturn a modified copy of deeply nested objects.\n\nExample\n\njulia> using Accessors\n\njulia> struct T;a;b end\n\njulia> t = T(1,2)\nT(1, 2)\n\njulia> @set t.a = 5\nT(5, 2)\n\njulia> t\nT(1, 2)\n\njulia> t = @set t.a = T(2,2)\nT(T(2, 2), 2)\n\njulia> @set t.a.b = 3\nT(T(2, 3), 2)\n\nSupports the same syntax as @optic. See also @reset.\n\n\n\n\n\n","category":"macro"}]
}
