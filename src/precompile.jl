
using PrecompileTools

@setup_workload let
    @compile_workload begin
        setmacro(identity, :(a.x = 1), overwrite=false)
        setmacro(identity, :(a.x = 1), overwrite=true)
        insertmacro(identity, :(a.x = 1), overwrite=false)
    end
end