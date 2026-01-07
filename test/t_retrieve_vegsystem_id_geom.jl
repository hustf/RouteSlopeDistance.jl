# This simply tries out syntaxes.
using Test
using RouteSlopeDistance
using RouteSlopeDistance: LOGSTATE, interval_progression_pairs, fixed
import HTTP
using JSON3: pretty
# We don't need to print our 
# request to screen as long as it is accepted.
LOGSTATE.authorization = false
LOGSTATE.request_string = false

url_ext = "beta/vegnett/rute"

northing1 = 6.94747e6 # Grimstad aust bus stop in UTM33
easting1 = 35465.0    # Grimstad aust bus stop in UTM33
northing2 = 6.94731e6 # Grimstad vest bus stop in UTM33
easting2 = 34865.7    # Grimstad vest bus stop in UTM33

# v4: Numbers like 6.94731e6 no longer understood
body = Dict([
    :typeveg                => ["Enkel bilveg"]
    :konnekteringslenker    => false
    :start                  => "$(fixed(easting1)) , $(fixed(northing1))"
    :trafikantgruppe        => "K"
    :detaljerte_lenker      => false
    :behold_trafikantgruppe => true
    :slutt                  => "$(fixed(easting2)) , $(fixed(northing2))"
    :tidspunkt              => "2023-07-28"])
o = nvdb_request(url_ext, "POST"; body)[1]
@test ! isempty(o)
l_straight = sqrt((easting2 - easting1)^2 +(northing2 - northing1)^2)
@test o.metadata.lengde > l_straight
# This section is pretty straight
@test abs(l_straight / o.metadata.lengde - 1) < 0.01

# We need to make several requests in order to get e.g. 'fartsgrense'. 
# Let's grab the vegsystemreferanses. 
# For kommunal (K) and fylke (F), the kommunenr and fylkesnr
# together with the vegsystemreferanses form a unique ID.
Δl = map(o.vegnettsrutesegmenter) do s
    s.lengde
end
@test isapprox(sum(Δl), o.metadata.lengde, atol = 0.1)

knr = map(o.vegnettsrutesegmenter) do s
    s.kommune
end

vsrs = map(o.vegnettsrutesegmenter) do s
    r = s.vegsystemreferanse
    @assert r.vegsystem.fase == "V" # Existing
    r.kortform
end
multi_linestring = Vector{Vector{Tuple{Float64, Float64, Float64}}}()
# v3 - v4: An extra space.
# Note this is implemented in `parse_multilinestring_values_and_structure`
# julia> s.geometri.wkt
# "LINESTRING Z (354..."
multi_linestring = map(o.vegnettsrutesegmenter) do s
    @debug s.geometri.wkt
    map(split(s.geometri.wkt[15:end - 1], ',')) do v
        @debug v
        NTuple{3, Float64}(tryparse.(Float64, split(strip(v), ' ')))
    end
end

# Check C0 continuity
previousend = (0.0, 0.0, 0.0)
for (i, ls) in enumerate(multi_linestring)
    global previousend
    thisstart = ls[1]
    thisend = ls[end]
    if i > 1 
        printstyled(rpad("p: $previousend ", 40), color = :green)
        printstyled(rpad("s: $thisstart ", 40), color = :yellow)
        Δ = round.(thisstart .- previousend, digits=1)
        printstyled("s - p: $Δ", color = :blue)
        if Δ !== (0.0, 0.0, 0.0) 
            print("  Section $i failed")
        end
        println()
    end
    previousend = thisend
end
# Look into why section 8 failed. Maybe it's reversed?
multi_linestring[7]
multi_linestring[8]
# No, that's not it. The elevation for 8 is much lower.
# Check online: 
x, y, _ = multi_linestring[8][1]
clipboard(string(Int(round(x)), ", ", Int(round(y))))
x, y, _ = multi_linestring[7][end]
clipboard(string(Int(round(x)), ", ", Int(round(y))))
x, y, _ = multi_linestring[7][1]
clipboard(string(Int(round(x)), ", ", Int(round(y))))

# ??? Look for other explanations.
o.vegnettsrutesegmenter[7]
o.vegnettsrutesegmenter[8]
# The segments simply aren't returned in order of .startposisjon / sluttposisjon... We could sort them before parsing.


function length_of_projected_linestring(ls::Vector{Tuple{Float64, Float64, Float64}})
    l = 0.0
    prevpt = ls[1]
    for pt in ls[2:end]
        Δx = pt[1] - prevpt[1]
        Δy = pt[2] - prevpt[2]
        l += hypot(Δx, Δy)
        prevpt = pt
    end
    l
end


Δl_linestrings = map(length_of_projected_linestring, multi_linestring)

abs.(Δl .- Δl_linestrings)


# FV61 S5D1 m1281-1401 Dragsundbrua aust

northing1 = 6939377.37 
easting1 = 25468    
northing2 = 6939333.54
easting2 = 25363.46

body = Dict([
    :typeveg                => ["Kanalisert veg", "Enkel bilveg", "Rampe", "Rundkjøring", "Gang- og sykkelveg"]
    :konnekteringslenker    => true
    :start                  => "$(fixed(easting1)) , $(fixed(northing1))"
    :trafikantgruppe        => "K"
    :maks_avstand  => 10
    :omkrets => 100
    :detaljerte_lenker      => true
    :behold_trafikantgruppe => true
    :slutt                  => "$(fixed(easting2)) , $(fixed(northing2))"
    :tidspunkt              => "2023-07-28"
    ])
o = nvdb_request(url_ext, "POST"; body)[1]
multi_linestring = map(o.vegnettsrutesegmenter) do s
    # Api v3 -> v4: An additional space starting the linestring.
    map(split(s.geometri.wkt[15:end-1], ',')) do v
        NTuple{3, Float64}(tryparse.(Float64, split(strip(v), ' ')))
    end
end
@test length(multi_linestring) == 1
ls = multi_linestring[1]

xx, yy = interval_progression_pairs(ls)
l3d =  round(yy[end]; digits = 3)
@test l3d == o.metadata.lengde
@test o.vegnettsrutesegmenter[1].geometri.srid == 5973

# Try to get higher precision geometri 
body = Dict([
    :typeveg                => ["Kanalisert veg", "Enkel bilveg", "Rampe", "Rundkjøring", "Gang- og sykkelveg"]
    :konnekteringslenker    => true
    :start                  => "$(fixed(easting1)) , $(fixed(northing1))"
    :trafikantgruppe        => "K"
    :maks_avstand  => 10
    :omkrets => 100
    :detaljerte_lenker      => true
    :behold_trafikantgruppe => true
    :slutt                  => "$(fixed(easting2)) , $(fixed(northing2))"
    :tidspunkt              => "2023-07-28"
    :srid                   => 5972    # Ikke dokumentert for POST-metoden...
    ])
# 4326, wgs84, 5975, 5974
# OK: utm33, 5973
# The precision is not actually affected by srid...
o = nvdb_request(url_ext, "POST"; body)[1]
@test ls[1][1] == 25467.928
