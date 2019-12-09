Base.@propagate_inbounds function setindex(args...)
    Base.setindex(args...)
end

for T in [:Array, :Dict]
    @eval begin
        Base.@propagate_inbounds function setindex(o::$T, args...)
            new = copy(o)
            setindex!(new, args...)
            new
        end
    end
end
