module SkyCoordsExt
using Accessors
using SkyCoords: ICRSCoords, FK5Coords, GalCoords, lat, lon

Accessors.set(x::ICRSCoords, ::typeof(lon), v) = @set x.ra = v
Accessors.set(x::ICRSCoords, ::typeof(lat), v) = @set x.dec = v
Accessors.set(x::FK5Coords, ::typeof(lon), v) = @set x.ra = v
Accessors.set(x::FK5Coords, ::typeof(lat), v) = @set x.dec = v
Accessors.set(x::GalCoords, ::typeof(lon), v) = @set x.l = v
Accessors.set(x::GalCoords, ::typeof(lat), v) = @set x.b = v
end
