using Test
using RouteSlopeDistance
using RouteSlopeDistance: patched_post_beta_vegnett_rute, coordinate_key, get_config_value
using RouteSlopeDistance: corrected_coordinates, link_split_key
using RouteSlopeDistance: extract_length, extract_multi_linestrings, extract_prefixed_vegsystemreferanse
using RouteSlopeDistance: reverse_linestrings_where_needed!
using RouteSlopeDistance: Quilt, amend_fromtos!
using RouteSlopeDistance: build_fromtos!, correct_coordinates!, build_patches!
M = ["Hareid bussterminal" 36976 6947659; "Hareid ungdomsskule fv. 61" 36533 6947582; "Holstad" 35983 6947673; "Grimstad aust" 35465 6947468; "Grimstad vest" 34866 6947308; "Bjåstad aust" 34418 6947105; "Bjåstad vest" 34054 6946887; "Bigsetkrysset" 33729 6946682; "Byggeli" 33142 6946489; "Nybøen" 32852 6946449; "Korshaug" 32344 6946360; "Rise aust" 31909 6946301; "Rise" 31515 6946166; "Rise vest" 31167 6946060; "Varleitekrysset" 29426 6945335; "Ulstein vgs." 28961 6945248; "Støylesvingen" 28275 6945289; "Holsekerdalen" 27714 6945607; "Ulsteinvik skysstasjon" 27262 6945774; "Saunes nord" 27457 6945077; "Saunes sør" 27557 6944744; "Strandabøen" 27811 6944172; "Dimnakrysset" 27721 6943086; "Botnen" 26807 6941534; "Garneskrysset" 26449 6940130; "Dragsund sør" 24823 6939041; 
"Myrvåglomma" 23911 6938921; "Myrvåg" 23412 6939348; "Aurvåg" 22732 6939786; "Aspevika" 22119 6939611; "Kalveneset" 21508 6939662; "Tjørvåg indre" 20671 6939661; "Tjørvåg" 20296 6939961; "Tjørvågane" 20222 6940344; "Tjørvåg nord" 20408 6940732; "Rafteset" 20794 6941312; "Storneset" 20779 6941912; "Stokksund" 20353 6942412; "Notøy" 19429 6943497; "Røyra øst" 19922 6944583; "Røyra vest" 19605 6944608; "Frøystadvåg" 19495 6945400; "Frøystadkrysset" 19646 6945703; "Nerøykrysset" 18739 6946249; "Berge bedehus" 17919 6946489; "Elsebøvegen" 17680 6946358; "Verket" 17441 6946183; "Berge" 17255 6946053; "Hjelmeset" 16949 6945880; "Demingane" 16575 6945717; "Eggesbønes" 16078 6945699; "Myklebust" 16016 6945895; "Herøy kyrkje" 16156 6946651; "Fosnavåg sparebank" 16235 6947271; "Fosnavåg terminal" 16064 6947515]
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

#= not updated
@test corrected_coordinates(true, ea2, no2) == (ea2, no2)
q = Quilt()
build_fromtos!(q, ea1, no1, ea2, no2)
correct_coordinates!(q)
@test length(q.fromtos) == 1
@test q.fromtos[1] == [cea, cno, ea2, no2]
=#

# Test a non-defined single point replacement
start = 2
na1, ea1, no1 = M[start, :]
@test corrected_coordinates(false, ea1 + 1, no1) == (ea1 + 1, no1)

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
refs = extract_prefixed_vegsystemreferanse(q)
@test refs[1] == "1517 FV61 S3D1 m2231-2236"
Δls = extract_length(q)
@test length(Δls) == 8
# Problematic:
mls, reversed = extract_multi_linestrings(q)
# ERROR: AssertionError: Not matching start point (34516.1, 6.9471438e6, 32.112) and previous end (34602.2, 6.947181e6, 31.413) 
# Check failed for segment i = 5
# The distance between is  93.79519497828024
# For checking with other tools: (34516 6947144)-(34472 6947127)

# Checked in web api:
# https://nvdbapiles.test.atlas.vegvesen.no/beta/vegnett/rute?start=34515.99999999994,6947143.999999999&slutt=34471.99999999965,6947127&maks_avstand=10&omkrets=100&konnekteringslenker=true&detaljerte_lenker=false&behold_trafikantgruppe=false&trafikantgruppe=K&typeveg=enkelBilveg&pretty=true
# {"type":"Rute","vegnettsrutesegmenter":[{"veglenkesekvensid":249554,"href":"https://nvdbapiles.test.atlas.vegvesen.no/vegnett/veglenkesekvenser/segmentert/249554","metadata":{"startdato":"2025-11-20"},"startposisjon":0.25312114,"sluttposisjon":0.2578408,"kortform":"0.25312114-0.2578408@249554","veglenkenummer":29,"segmentnummer":7,"referanse":"249554-29-7","type":"HOVED","detaljnivå":"Vegtrase og kjørebane","typeVeg":"Enkel bilveg","typeVeg_sosi":"enkelBilveg","målemetode":"Metrert","måledato":"1974-01-01","feltoversikt":["1","2"],"geometri":{"wkt":"LINESTRING Z (34516.088 6947143.795 32.112,34512.6 6947142.3 32.212,34507.99 6947140.6 32.212,34503.6 6947138.9 32.312,34499.49 6947137.189 32.312,34479.1 6947129.7 32.512,34472.024 6947126.951 32.652)","srid":5973,"kvalitet":{"målemetode":22,"datafangstmetode":"fot","nøyaktighet":36,"maksimaltAvvik":-1,"synbarhet":99},"datafangstdato":"1992-05-18","kommune":1517,"temakode":7001,"lengde":47.185},"lengde":47.17944168855182,"fylke":15,"kommune":1517,"vegsystemreferanse":{"vegsystem":{"vegkategori":"F","fase":"V","nummer":61},"strekning":{"strekning":3,"delstrekning":1,"arm":false,"adskilte_løp":"Nei","trafikantgruppe":"K","retning":"MED","fra_meter":2617.458129240118,"til_meter":2664.6385606379563},"kortform":"FV61 S3D1 m2617-2665"},"kontraktsområder":[{"id":1018118369,"nummer":1501,"navn":"1501 Søre Sunnmøre 2024-2029"},{"id":1014871196,"nummer":1550,"navn":"E1550 Elektrokontrakt Møre og Romsdal"},{"id":1022020910,"nummer":1547,"navn":"1547 Rekkverkskontrakt 2024-2027"}],"riksvegruter":[],"adresse":{"id":1009330615,"navn":"Hareidsvegen","adressekode":2109}}],"metadata":{"antall":1,"lengde":47.179,"status":2000,"status_tekst":"KOMPLETT"}}
# First thing to to: Check if there's a new parameter we should add to body so as to match the web api.
# Second: is this due to the parameter 'arm' now missing?

# Let's look for visual cues
multi_linestring = [[(34865.865, 6.947308316e6, 31.813), (34860.865, 6.94730604e6, 31.813)], [(34860.865, 6.94730604e6, 31.813), (34855.9, 6.9473035e6, 31.813), (34851.1, 6.9473012e6, 31.713), (34845.2, 6.9472984e6, 31.713), (34839.7, 6.9472957e6, 31.613), (34833.9, 6.9472928e6, 31.613), (34821.4, 6.9472866e6, 31.513), (34814.953, 6.947283594e6, 31.413), (34809.7, 6.947281147e6, 31.413), (34804.4, 6.9472785e6, 31.413), (34799.2, 6.947276e6, 31.313), (34790.902, 6.947272009e6, 31.213)], [(34790.902, 6.947272009e6, 31.213), (34781.253, 6.947267136e6, 31.213), (34775.453, 6.947264389e6, 31.113), (34769.596, 6.947261594e6, 31.113), (34764.043, 6.947258789e6, 31.013), (34756.994, 6.947255341e6, 31.013), (34749.4, 6.9472518e6, 30.913), (34740.1, 6.947247189e6, 30.913), (34730.859, 6.947242741e6, 30.813), (34725.206, 6.947240041e6, 30.813), (34719.753, 6.947237383e6, 30.813), (34714.494, 6.947234824e6, 30.813), (34710.4, 6.947232783e6, 30.813), (34704.706, 6.9472302e6, 30.813), (34699.6, 6.947227636e6, 30.813), (34693.218, 6.947224666e6, 30.813)], [(34693.218, 6.947224666e6, 30.813), (34686.253, 6.947221189e6, 30.813), (34668.653, 6.947212736e6, 31.013), (34654.258, 6.947205731e6, 31.013), (34637.453, 6.947197589e6, 31.113), (34623.7, 6.947191e6, 31.213), (34606.49, 6.947183e6, 31.413), (34602.2, 6.947181e6, 31.413)], [(34516.1, 6.9471438e6, 32.112), (34512.6, 6.9471423e6, 32.212), (34507.99, 6.9471406e6, 32.212), (34503.6, 6.9471389e6, 32.312), (34499.49, 6.947137189e6, 32.312), (34479.1, 6.9471297e6, 32.512), (34471.579, 6.947126778e6, 32.661)], [(34471.579, 6.947126778e6, 32.661), (34464.7, 6.9471243e6, 32.712), (34460.453, 6.947122636e6, 32.812), (34452.416, 6.947119689e6, 32.812), (34444.153, 6.947116541e6, 32.912), (34435.953, 6.947113489e6, 33.012), (34432.2, 6.9471122e6, 33.012), (34427.99, 6.9471107e6, 33.112), (34424.99, 6.9471095e6, 33.212), (34417.6, 6.9471067e6, 33.412), (34417.399, 6.947106625e6, 33.412)], [(34530.6, 6.9471495e6, 32.012), (34534.6, 6.9471511e6, 32.012), (34541.49, 6.947154e6, 31.912), (34548.7, 6.947157e6, 31.812), (34553.2, 6.9471588e6, 31.812), (34556.7, 6.9471604e6, 31.812), (34560.49, 6.947162e6, 31.712), (34564.49, 6.9471637e6, 31.712), (34572.4, 6.947167194e6, 31.612), (34587.49, 6.9471739e6, 31.513), (34598.6, 6.9471792e6, 31.513), (34602.2, 6.947181e6, 31.413)], [(34530.6, 6.9471495e6, 32.012), (34522.99, 6.9471465e6, 32.012), (34516.1, 6.9471438e6, 32.112)]]
vx = Float64[]
vy = Float64[]
for a in multi_linestring
    for tup in a
        x, y, _ = tup
        push!(vx, x)
        push!(vy, y)
        if tup == a[end]
            push!(vx, NaN)
            push!(vy, NaN)
        end
    end
end
using Plots
plotly()
plot(vx, vy, size = (1200, 1000), marker = :cross)
gui()
plot(1:length(vy), vy, size = (1200, 1000), marker = :cross)
gui()
@test length(mls) == 8
@test mls isa Vector{Vector{Tuple{Float64, Float64, Float64}}}
# Ok, it is obvious that the multi_linestring's are not ordered.
# That could be difficult to sort out, so it would be best if we found
# an api argument for ordering....
# No such parameter.
# Secondly, we don



# Request phrased in string. 
# Detecting reversion is hard for 3d, but works when dropping z
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
o = q.patches[1]
ea, no = ea1, no1
multi_linestring = map(o.vegnettsrutesegmenter) do s
  # Api v3 -> v4: An additional space starting the linestring.
  ls = map(split(s.geometri.wkt[15:end-1], ',')) do v
      NTuple{3, Float64}(tryparse.(Float64, split(strip(v), ' ')))
  end
end
reversed = reverse_linestrings_where_needed!(multi_linestring, ea, no)
@test reversed == [true, true, true, true]


# Test a patched segment, Notøy -> Røyra øst
start = 39
stop = 40
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
key = link_split_key(ea1, no1, ea2, no2)
insertpos = get_config_value("link split", key, Tuple{Float64, Float64}, nothing_if_not_found = true)
q = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)
refs = extract_prefixed_vegsystemreferanse(q)
@test refs[1] == "1515 FV654 S3D1 m1065 SD1 m5-7"
Δls = extract_length(q)
@test sum(Δls) > 2000 && sum(Δls) < 2030
@test length(Δls) == 12
mls, reversed = extract_multi_linestrings(q)
@test length(mls) == 12
@test mls isa Vector{Vector{Tuple{Float64, Float64, Float64}}}

# Test a segment with a replaced coordinate, Holsekerdalen -> Ulsteinvik skysstasjon
start = 18
stop = 19
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
key = link_split_key(ea1, no1, ea2, no2)
insertpos = get_config_value("link split", key, Tuple{Float64, Float64}, nothing_if_not_found = true)
@test isnothing(insertpos)
key = coordinate_key(true, ea2, no2)
replaced_pos = get_config_value("coordinates replacement", key, Tuple{Int64, Int64}; nothing_if_not_found = true)
@test ! isnothing(replaced_pos)
@test corrected_coordinates(true, ea2, no2) !== (ea2, no2)
q =  patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)
Δls = extract_length(q)
@test length(Δls) == 16
@test sum(Δls) > 555 && sum(Δls) < 560 

# Test a segment with a patched segment, Botnen -> Garneskrysset and also replaced end coordinate.
start = 24
stop = 25
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
key = link_split_key(ea1, no1, ea2, no2)
insertpos = get_config_value("link split", key, Tuple{Float64, Float64}, nothing_if_not_found = true)
@test ! isnothing(insertpos)
key = coordinate_key(true, ea2, no2)
replaced_pos = get_config_value("coordinates replacement", key, Tuple{Int64, Int64}; nothing_if_not_found = true)
@test ! isnothing(replaced_pos)
@test corrected_coordinates(true, ea2, no2) !== (ea2, no2)
q = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2);
Δls = extract_length(q)
@test length(Δls) == 20
@test sum(Δls) > 2110 && sum(Δls) < 2120

# This uses the layer where we patch errors in finding routes.
rws = 1:(size(M)[1])
for (start, stop) in zip(rws[1: (end - 1)], rws[2:end])
    println()
    na1, ea1, no1 = M[start, :]
    na2, ea2, no2 = M[stop, :]
    print(lpad("$start $stop", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
    q = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)
    refs = extract_prefixed_vegsystemreferanse(q)
    lengths = extract_length(q)
    for (r, l) in zip(refs, lengths)
         print(rpad(r, 35) , "  l = ",  l)
         print("\n", lpad(" ", 72))
    end
    println()
end

# This requires a second pass (at least):
M = [
        "Furene"  34704  6925611
   "Hovdevatnet"  34518  6927170
       "Sørheim"  32452  6930544
   "Eiksundbrua"  27963  6935576
         "Havåg"  27158  6935798
    "Ytre Havåg"  26698  6935841
        "Selvåg"  26436  6935972
    "Haddal sør"  27382  6938074
   "Haddal nord"  27280  6939081
  "Garneskrysset" 26449  6940130
]

# The hardest part is here:
start = 3
stop = 4
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
q = Quilt()
build_fromtos!(q, ea1, no1, ea2, no2)
display(q.fromtos)
correct_coordinates!(q)
build_patches!(q)



rws = 1:(size(M)[1])
for (start, stop) in zip(rws[1: (end - 1)], rws[2:end])
    println()
    na1, ea1, no1 = M[start, :]
    na2, ea2, no2 = M[stop, :]
    print(lpad("$start $stop", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
    q = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)
    refs = extract_prefixed_vegsystemreferanse(q)
    lengths = extract_length(q)
    for (r, l) in zip(refs, lengths)
         print(rpad(r, 35) , "  l = ",  l)
         print("\n", lpad(" ", 72))
    end
    println()
end


