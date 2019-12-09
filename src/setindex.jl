Base.@propagate_inbounds function setindex(args...)
    Base.setindex(args...)
end

for T in [:Array, :Dict]
    @eval begin
            Base.@propagate_inbounds setindex(o::$T, args...) =
                setindex!(copy(o), args...)
    end
end
