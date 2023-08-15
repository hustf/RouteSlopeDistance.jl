using RouteSlopeDistance
using RouteSlopeDistance: patched_post_beta_vegnett_rute, 
    extract_prefixed_vegsystemreferanse,
    extract_length,
    extract_multi_linestrings,
    extract_multi_linestrings,
    fartsgrense_from_prefixed_vegsystemreferanse
using JSON3: pretty


M = ["Hareid bussterminal" 36975.94566374121 6.947658805705906e6; "Hareid ungdomsskule fv. 61" 36532.55545087671 6.947581886945733e6; "Holstad" 35983.1443116063 6.947673163559002e6; "Grimstad aust" 35464.96463259688 6.947468011095509e6; "Grimstad vest" 34865.66712469625 6.947308159359314e6; "Bjåstad aust" 34417.88533130888 6.94710510180928e6; "Bjåstad vest" 34054.27868455148 6.946887317608121e6; "Bigsetkrysset" 33728.64367864374 6.946682380315655e6; "Byggeli" 33142.22175210371 6.946488830511735e6; "Nybøen" 32851.70907960052 6.946449354497116e6; "Korshaug" 32343.566099463962 6.946360408979714e6; "Rise aust" 31908.81277878303 6.946301439017767e6; "Rise" 31515.075405728596 6.946166435782562e6; "Rise vest" 31166.8812895664 6.946060114423563e6; "Varleitekrysset" 29426.092089441197 6.945334778036252e6; "Ulstein vgs." 28961.357645253593 6.945248138849279e6; "Støylesvingen" 28275.444230089895 6.945288942957118e6; "Holsekerdalen" 27714.179788790876 6.945606747071537e6; "Ulsteinvik skysstasjon" 27262.18078544963 6.945774337512597e6; "Saunes nord" 27457.300948846503 6.945077356432355e6; "Saunes sør" 27557.2207297993 6.944743999927791e6; "Strandabøen" 27810.953292181366 6.944172090808818e6; "Dimnakrysset" 27720.899809156603 6.943086326247893e6; "Botnen" 26807.34408127074 6.941533714193652e6; "Garneskrysset" 26448.894934401556 6.940129956181607e6; "Dragsund sør" 24823.194600016985 6.939041381131042e6; "Myrvåglomma" 23910.869586607092 6.938920557515621e6; "Myrvåg" 23411.547657008457 6.939347655974448e6; "Aurvåg" 22731.993701261526 6.939785509768682e6; "Aspevika" 22119.248180354887 6.939611088769487e6; "Kalveneset" 21507.79140086705 6.939661984886746e6; "Tjørvåg indre" 20670.579345440492 6.939661472948665e6; "Tjørvåg" 20295.777947708208 6.93996120795614e6; "Tjørvågane" 20222.213099840155 6.940343660939465e6; "Tjørvåg nord" 20407.956564288645 6.940731998657505e6; "Rafteset" 20793.75811150472 6.941312130095156e6; "Storneset" 20778.735032497556 6.941911649292342e6; "Stokksund" 20353.192697804363 6.94241189645477e6; "Notøy" 19428.907322990475 6.943496947023508e6; "Røyra øst" 19921.774665450328 6.944582534682405e6; "Røyra vest" 19604.993318945984 6.944607764588606e6; "Frøystadvåg" 19495.16047112737 6.94540013477574e6; "Frøystadkrysset" 19646.29224914976 6.9457027824882725e6; "Nerøykrysset" 18738.6739445625 6.946249249481636e6; "Berge bedehus" 17918.84676897031 6.946488791539114e6; "Elsebøvegen" 17679.55323949206 6.946358107562704e6; "Verket" 17441.2284281507 6.946183037961578e6; "Berge" 17254.861414988118 6.946052685186134e6; "Hjelmeset" 16948.82774523727 6.94588028132061e6; "Demingane" 16575.39314737235 6.945716940684748e6; "Eggesbønes" 16077.868413755263 6.94569855075708e6; "Myklebust" 16016.077339820331 6.945895007681623e6; "Herøy kyrkje" 16156.369994148146 6.946651348835291e6; "Fosnavåg sparebank" 16235.327457943466 6.94727099225032e6; "Fosnavåg terminal" 16063.782613804331 6.947514879242669e6]

rw = 26
na1, ea1, no1 = M[rw, :]
na2, ea2, no2 = M[rw + 1 , :]
println(lpad("$rw $(rw + 1)", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
easting1, northing1, easting2, northing2 = ea1, no1, ea2, no2

# Lookups are quite slow; we need to store results.
#
#  0.499989 seconds (1.30 k allocations: 276.625 KiB)
@time q = patched_post_beta_vegnett_rute(easting1, northing1, easting2, northing2);
#  0.000185 seconds (455 allocations: 52.797 KiB)
@time refs = extract_prefixed_vegsystemreferanse(q);
#  0.000119 seconds (139 allocations: 26.203 KiB)
@assert ! startswith(refs[1], "Error") refs[1];
#  0.000110 seconds (138 allocations: 26.141 KiB)
@time lengths = extract_length(q);
# 0.000389 seconds (608 allocations: 76.211 KiB)
@time mls = extract_multi_linestrings(q);
# length(refs) == 13 in this typical case
# 0.938881 seconds (1.49 k allocations: 158.969 KiB)
@time fartsgrense_from_prefixed_vegsystemreferanse(refs[3])


# This long route represented by M takes roughly 55 * 0.5s = 25s
# to extract if we successfully store fartsgrense in a table
# Fartsgrenser could be stored in a table, but keeping an updated
# table is a lot of work.
# We think it will be better to serialize each call to route_data


# The below takes several minutes.
rws = 1:(size(M)[1])
for (start, stop) in zip(rws[1: (end - 1)], rws[2:end])
    println()
    na1, ea1, no1 = M[start, :]
    na2, ea2, no2 = M[stop, :]
    println(lpad("$start $stop", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
    refs, lengths, mls, fart_mls = route_data(ea1, no1, ea2, no2)
    display(sum(lengths))
    println()
end 