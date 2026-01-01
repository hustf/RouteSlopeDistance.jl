using Test
using RouteSlopeDistance
using RouteSlopeDistance: LOGSTATE, correct_to_increasing_distance, is_rpoint_in_ref
import HTTP
using JSON3: pretty
body = Dict([])
method = "POST"
url_ext = "vegnett/api/v4/beta/vegnett/rute"
#
url = "$(RouteSlopeDistance.BASEURL)$url_ext"
idfields = RouteSlopeDistance.get_nvdb_fields(body)
# The body is empty
@test_throws HTTP.Exceptions.StatusError HTTP.request(method, url, idfields, body)
@test isempty(nvdb_request(url_ext, "POST"; body)[1])
#     POST https://nvdbapiles.atlas.vegvesen.no/vegnett/api/v4/beta/vegnett/rute   \{}
#┌ Info: {
#│     "type": "about:blank",
#│     "title": "Bad Request",
#│     "status": 400,
#│     "detail": "Enten `geometri` eller både `start` og `slutt` må være satt",
#│     "instance": "/api/v4/beta/vegnett/rute"
#└ }
#
# Now that the request format is addressed and parsed, we don't need to print our 
# request to screen as long as it is accepted.
LOGSTATE.authorization = false
LOGSTATE.request_string = false
# We add arguments, solving one v3-> v4 issue at a time.
push!(body, :geometri => "LINESTRING Z (226778.2 6564468.6 5, 226747.1 6564470.1 5, 226717.5 6564466.4 5, 226705.9 6564462.7 6.2, 226687.2 6564462.9 6, 226657.7 6564460.7 6, 226628.5 6564459.5 6, 226611.3 6564459.6 6.2)")
push!(body, :trafikantgruppe => "K")
@test !isempty(nvdb_request(url_ext, "POST"; body)[1])
push!(body, :behold_trafikantgruppe => true)
@test !isempty(nvdb_request(url_ext, "POST"; body)[1])
# v4: enkelbilveg => ["Enkel bilveg"].
push!(body, :typeveg => ["Enkel bilveg"]) 
@test !isempty(nvdb_request(url_ext, "POST"; body)[1])
push!(body, :slutt  => "226855.034,6564472.225")
o = nvdb_request(url_ext, "POST"; body)[1]
@test ! isempty(o)
l_straight = sqrt((226761.786 - 226855.034)^2 +(6564469.3787 - 6564472.225)^2)
@test abs(o.metadata.lengde / 167 - 1) < 0.03

# In v3, this was acceptable :start => "226761.786,6564469.3787 eller 0.1@1234"
# 
# Feedback: "Enten `geometri` eller både `start` og `slutt` må være satt"
# ...seems to be misleading. We can set 'omkrets', delete 'geometri' and have a result.
#
push!(body, :omkrets => "1000")
pop!(body, :geometri)
push!(body, :start => "226761.786,6564469.3787")
o1 = nvdb_request(url_ext, "POST"; body)[1]
@test o.metadata.lengde !== o1.metadata.lengde

# 'geometri' could be a bounding box, but 'omkrets' does the work usually.
@test abs(l_straight / o1.metadata.lengde - 1) < 0.01

# Not updated below....


# 226761.786,6564469.3787 is in UTM33, which is used for nation wide data.
# The local zone for Sandefjord is UTM32. Do we have a choice?
push!(body, :srid => "utm32")
push!(body, :start => "570008.7,6555325.74") # Same place, in UTM32
push!(body, :slutt => "570101.23,6555336.94") # Same place, in UTM32
@test isempty(nvdb_request(url_ext, "POST"; body)[1]) # "message": "Expected SRID 5973, but was 5972"
pop!(body, :srid)
o2 = nvdb_request(url_ext, "POST"; body)[1]
@test o2.metadata.status_tekst == "IKKE_FUNNET_STARTPUNKT"
# Conclusion: 'start' and 'slutt' must be in UTM33 (or a higher resolution equivalent)

ref = "1516 KV1123 S1D1 m1818-1860"
@test correct_to_increasing_distance(ref) == ref
ref = "1516 KV1123 S1D1 m1818-1769"
@test correct_to_increasing_distance(ref) == "1516 KV1123 S1D1 m1769-1818"
ref = "KV1123 S1D1 m1818-1860"
@test correct_to_increasing_distance(ref) == ref
ref = "KV1123 S1D1 m1818-1769"
@test correct_to_increasing_distance(ref) == "KV1123 S1D1 m1769-1818"

@test is_rpoint_in_ref("1515 PV3080 S1D1 m56", "1515 PV3080 S1D1 m20-84")
@test ! is_rpoint_in_ref( "1515 PV3080 S1D1 m56", "1515 VW3080 S1D1 m20-84")
@test ! is_rpoint_in_ref( "1515 PV3080 S1D1 m85", "1515 PV3080 S1D1 m20-84")
@test ! is_rpoint_in_ref( "1515 PV3080 S1D1 m15", "1515 PV3080 S1D1 m20-84")