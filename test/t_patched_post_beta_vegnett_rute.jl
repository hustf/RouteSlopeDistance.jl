# This file starts with unit tests for internal types,
# and then the non-exported internal workhorses
# - extract_multi_linestrings
# - extract_prefixed_vegsystemreferanse
# - extract_length
using Test
using RouteSlopeDistance
using RouteSlopeDistance: patched_post_beta_vegnett_rute, coordinate_key, get_config_value
using RouteSlopeDistance: corrected_coordinates, link_split_key
using RouteSlopeDistance: extract_length, extract_multi_linestrings, extract_prefixed_vegsystemreferanse
using RouteSlopeDistance: reverse_linestrings_where_needed!
using RouteSlopeDistance: Quilt, amend_fromtos!
using RouteSlopeDistance: build_fromtos!, correct_coordinates!, build_patches!
# Define M (example locations matrix) and plotting 
include("common.jl")
# Unit test amend_fromtos!
# This relies on pathces defined in init file for testing purpose.
q = Quilt()
push!(q.fromtos, [1, 1, 5, 5]) 
before = copy(q.fromtos)
amend_fromtos!(q, 1)
@test before !== q.fromtos
before = copy(q.fromtos)
amend_fromtos!(q, 1)
@test before == q.fromtos
amend_fromtos!(q, 2)
@test before !== q.fromtos
before = copy(q.fromtos)
amend_fromtos!(q, 3)
@test before !== q.fromtos
before = copy(q.fromtos)
amend_fromtos!(q, 4)
@test before == q.fromtos

# Unit test build_fromtos!
q = Quilt()
build_fromtos!(q, 1, 1, 5, 5)
@test q.fromtos == [[1, 1, 2, 2], [2, 2, 3, 3], [3, 3, 4, 4], [4, 4, 5, 5]]

@test_throws AssertionError patched_post_beta_vegnett_rute(1, 1, 5, 5)

# Test a defined single point replacement
start = 1
na1, ea1, no1 = M[start, :]
key = coordinate_key(false, ea1, no1)
@test ! isnothing(get_config_value("coordinates replacement", key, Tuple{Int64, Int64}; nothing_if_not_found = true))
cea, cno = corrected_coordinates(false, ea1, no1)
@test (cea, cno) !== (ea1, no1)

# Test a non-defined single point replacement
start = 2
na1, ea1, no1 = M[start, :]
@test corrected_coordinates(false, ea1 + 1, no1) == (ea1 + 1, no1)

#######################################
# - extract_prefixed_vegsystemreferanse
# - extract_length
# - extract_multi_linestrings
#######################################

# Test a non-patched or point corrected segment. This also returns just one segment.
start = 5
stop = 6
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
@test build_fromtos!(Quilt(), ea1, no1, ea2, no2).fromtos == [[ea1, no1,ea2, no2]]
q = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2);
#      POST https://nvdbapiles.atlas.vegvesen.no/vegnett/api/v4/beta/vegnett/rute   \{"typeveg":["Kanalisert veg","Enkel bilveg","Rampe","Rundkjøring","Gang- og sykkelveg"],"konnekteringslenker":true,"maks_avstand":10,"behold_trafikantgruppe":true,"slutt":"34418.0 , 6947105.0","tidspunkt":"2023-07-28","start":"34866.0 , 6947308.0","omkrets":100,"trafikantgruppe":"K","detaljerte_lenker":true}
@test length(q.fromtos) == 1
@test length(q.patches) == 1
refs, revs = extract_prefixed_vegsystemreferanse(q)
@test refs == ["1517 FV61 S3D1 m2231-2236", "1517 FV61 S3D1 m2236-2315", "1517 FV61 S3D1 m2315-2423", "1517 FV61 S3D1 m2423-2524", "1517 FV61 S3D1 m2524-2602", "1517 FV61 S3D1 m2602-2617", "1517 FV61 S3D1 m2617-2665", "1517 FV61 S3D1 m2665-2723"]
Δls = extract_length(q)
@test length(Δls) == 8
#= max deviation here is 0.585 m. Nice!
hcat(refs, Δls)
From manual editing, compare both methods for length estimation of segments.
# Max deviation is < 0.8m
 -2231 + 2236 -    5.49074
 -2236 + 2315 -   78.415
 -2315 + 2423 -  108.17
 -2423 + 2524 -  100.911
 -2524 + 2602 -   78.216
 -2602 + 2617 -   15.571
 -2617 + 2665 -   47.67
 -2665 + 2723 -   57.9063
=#
mls, rev = extract_multi_linestrings(q)
@test length(mls) == 8
@test mls isa Vector{Vector{Tuple{Float64, Float64, Float64}}}
# Looks god
plot_inspect_continuity(mls)


# Request phrased in string. 
na1 = "Rise vest"
na2 = "Rise"
s = "(31167 6946060)-(31515 6946166)"
args = split(s, '-')
start = replace(strip(args[1], ['(', ')'] ), ' ' => ',')
slutt = replace(strip(args[2], ['(', ')'] ), ' ' => ',')
stea, stno = split(start, ',')
slea, slno = split(slutt, ',')
ea1 = Int(round(tryparse(Float64, stea)))
no1 = Int(round(tryparse(Float64, stno)))
ea2 = Int(round(tryparse(Float64, slea)))
no2 = Int(round(tryparse(Float64, slno)))
@test ea1 == 31167
@test no1 == 6946060
@test ea2 == 31515 
@test no2 == 6946166
q = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)
@test length(q.patches) == 1
@test length(q.fromtos) == 1
@test q.fromtos[1] == [ea1, no1, ea2, no2]
mls, rev = extract_multi_linestrings(q)
@test length(mls) == 4
tit =  na1 * " til " * na2
pl = plot_inspect_continuity(mls);
title!(pl[2], tit)


# Test a patched segment, Holsekerdalen -> Ulsteinvik skysstasjon.
# This also has a corrected coordinate.
start = 18
stop = 19
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
tit = rpad("$start", 3) * na1 * " til " * na2
key = link_split_key(ea1, no1, ea2, no2)
insertpos = get_config_value("link split", key, Tuple{Float64, Float64}, nothing_if_not_found = true)
q = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)
@test length(q.fromtos) == 2
refs, revs = extract_prefixed_vegsystemreferanse(q)
@test refs[1] == "1516 KV1123 S1D1 m172-288"
Δls = extract_length(q)
@test sum(Δls) > 560 && sum(Δls) < 570
@test length(Δls) == 20
mls, rev = extract_multi_linestrings(q)
@test length(mls) == 20
@test mls isa Vector{Vector{Tuple{Float64, Float64, Float64}}}
pl = plot_inspect_continuity(mls);
title!(pl[2], tit)


# Test a segment with a patched segment, Botnen -> Garneskrysset and also replaced end coordinate.
start = 24
stop = 25
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
tit = rpad("$start", 3) * na1 * " til " * na2
q = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2);
mls, rev = extract_multi_linestrings(q)
pl = plot_inspect_continuity(mls);
title!(pl[2], tit)


# This was problematic for route_leg_data
start = 31
stop = 30
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
tit = rpad("$start", 3) * na1 * " til " * na2
key = link_split_key(ea1, no1, ea2, no2)
insertpos = get_config_value("link split", key, Tuple{Float64, Float64}, nothing_if_not_found = true)
q = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)
@test length(q.fromtos) == 1
refs, revs = extract_prefixed_vegsystemreferanse(q)
@test refs[1] == "1515 FV654 S1D1 m3067"
Δls = extract_length(q)
@test sum(Δls) > 638 && sum(Δls) < 640
@test length(Δls) == 12
mls, rev = extract_multi_linestrings(q)
@test rev == revs
@test length(mls) == 12
@test mls isa Vector{Vector{Tuple{Float64, Float64, Float64}}}
pl = plot_inspect_continuity(mls);
title!(pl[2], tit)
