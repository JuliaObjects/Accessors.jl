
using PrecompileTools

@setup_workload let
    struct A x::Int end
    a = A(1)
    @compile_workload begin
        setmacro(identity, :(a.x = 1), overwrite=false)
        setmacro(identity, :(a.x = 1), overwrite=true)
        insertmacro(identity, :(a.x = 1), overwrite=false)
        Accessors.set(a, Accessors.opticcompose(PropertyLens{:x}()), 2)
    end
end
