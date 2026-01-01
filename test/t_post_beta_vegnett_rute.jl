using Test
using RouteSlopeDistance
using RouteSlopeDistance: post_beta_vegnett_rute
using RouteSlopeDistance: extract_prefixed_vegsystemreferanse, extract_length, extract_multi_linestrings

M = ["Hareid bussterminal" 36975.94566374121 6.947658805705906e6; "Hareid ungdomsskule fv. 61" 36532.55545087671 6.947581886945733e6; "Holstad" 35983.1443116063 6.947673163559002e6; "Grimstad aust" 35464.96463259688 6.947468011095509e6; "Grimstad vest" 34865.66712469625 6.947308159359314e6; "Bjåstad aust" 34417.88533130888 6.94710510180928e6; "Bjåstad vest" 34054.27868455148 6.946887317608121e6; "Bigsetkrysset" 33728.64367864374 6.946682380315655e6; "Byggeli" 33142.22175210371 6.946488830511735e6; "Nybøen" 32851.70907960052 6.946449354497116e6; "Korshaug" 32343.566099463962 6.946360408979714e6; "Rise aust" 31908.81277878303 6.946301439017767e6; "Rise" 31515.075405728596 6.946166435782562e6; "Rise vest" 31166.8812895664 6.946060114423563e6; "Varleitekrysset" 29426.092089441197 6.945334778036252e6; "Ulstein vgs." 28961.357645253593 6.945248138849279e6; "Støylesvingen" 28275.444230089895 6.945288942957118e6; "Holsekerdalen" 27714.179788790876 6.945606747071537e6; "Ulsteinvik skysstasjon" 27262.18078544963 6.945774337512597e6; "Saunes nord" 27457.300948846503 6.945077356432355e6; "Saunes sør" 27557.2207297993 6.944743999927791e6; "Strandabøen" 27810.953292181366 6.944172090808818e6; "Dimnakrysset" 27720.899809156603 6.943086326247893e6; "Botnen" 26807.34408127074 6.941533714193652e6; "Garneskrysset" 26448.894934401556 6.940129956181607e6; "Dragsund sør" 24823.194600016985 6.939041381131042e6; "Myrvåglomma" 23910.869586607092 6.938920557515621e6; "Myrvåg" 23411.547657008457 6.939347655974448e6; "Aurvåg" 22731.993701261526 6.939785509768682e6; "Aspevika" 22119.248180354887 6.939611088769487e6; "Kalveneset" 21507.79140086705 6.939661984886746e6; "Tjørvåg indre" 20670.579345440492 6.939661472948665e6; "Tjørvåg" 20295.777947708208 6.93996120795614e6; "Tjørvågane" 20222.213099840155 6.940343660939465e6; "Tjørvåg nord" 20407.956564288645 6.940731998657505e6; "Rafteset" 20793.75811150472 6.941312130095156e6; "Storneset" 20778.735032497556 6.941911649292342e6; "Stokksund" 20353.192697804363 6.94241189645477e6; "Notøy" 19428.907322990475 6.943496947023508e6; "Røyra øst" 19921.774665450328 6.944582534682405e6; "Røyra vest" 19604.993318945984 6.944607764588606e6; "Frøystadvåg" 19495.16047112737 6.94540013477574e6; "Frøystadkrysset" 19646.29224914976 6.9457027824882725e6; "Nerøykrysset" 18738.6739445625 6.946249249481636e6; "Berge bedehus" 17918.84676897031 6.946488791539114e6; "Elsebøvegen" 17679.55323949206 6.946358107562704e6; "Verket" 17441.2284281507 6.946183037961578e6; "Berge" 17254.861414988118 6.946052685186134e6; "Hjelmeset" 16948.82774523727 6.94588028132061e6; "Demingane" 16575.39314737235 6.945716940684748e6; "Eggesbønes" 16077.868413755263 6.94569855075708e6; "Myklebust" 16016.077339820331 6.945895007681623e6; "Herøy kyrkje" 16156.369994148146 6.946651348835291e6; "Fosnavåg sparebank" 16235.327457943466 6.94727099225032e6; "Fosnavåg terminal" 16063.782613804331 6.947514879242669e6]

# This route should be easy
start = 5
stop = 6
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
o = post_beta_vegnett_rute(ea1, no1, ea2, no2)
refs = extract_prefixed_vegsystemreferanse(o, ea1, no1, ea2, no2)
@test refs[1] == "1517 FV61 S3D1 m2231-2237"
Δls = extract_length(o)
@test length(Δls) == 8
mls = extract_multi_linestrings(o, ea1, no1)
@test length(mls) == 8
@test mls isa Vector{Vector{Tuple{Float64, Float64, Float64}}}


# Test status 4041. This also triggers Http error 404. We don't suppress that mistake.
start = 1
stop = 2
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
o = post_beta_vegnett_rute(ea1, no1, ea2, no2)
refs = extract_prefixed_vegsystemreferanse(o, ea1, no1, ea2, no2)
@test length(refs) == 1
@test startswith(refs[1], "Error: 4041")

# Test status 4042. This also triggers Http error 404. We don't suppress that mistake.
start = 54
stop = 55
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
o = post_beta_vegnett_rute(ea1, no1, ea2, no2)
refs = extract_prefixed_vegsystemreferanse(o, ea1, no1, ea2, no2)
@test length(refs) == 1
@test startswith(refs[1], "Error: 4042")

# Test status 4040
start = 39
stop = 40
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
o = post_beta_vegnett_rute(ea1, no1, ea2, no2)
refs = extract_prefixed_vegsystemreferanse(o, ea1, no1, ea2, no2)
@test length(refs) == 1
@test startswith(refs[1], "Error: 4040")




# This skips the layer where we patch errors in finding routes.
# We use the output to make patches (in ini-file).
rws = 1:(size(M)[1])
for (start, stop) in zip(rws[1: (end - 1)], rws[2:end])
    println()
    na1, ea1, no1 = M[start, :]
    na2, ea2, no2 = M[stop, :]
    print(lpad("$start $stop", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
    o = post_beta_vegnett_rute(ea1, no1, ea2, no2)
    refs = extract_prefixed_vegsystemreferanse(o, ea1, no1, ea2, no2)
    lengths = extract_length(o)
    for (r, l) in zip(refs, lengths)
         print(rpad(r, 35) , "  l = ",  l)
         print("\n", lpad(" ", 72))
    end
    println()
end


#=
  1 2             Hareid bussterminal -> Hareid ungdomsskule fv. 61          GET https://nvdbapiles.atlas.vegvesen.no/posisjon?nord=6.947658805705906e6&ost=36975.94566374121&maks_avstand=10&trafikantgruppe=K
Error: 4041  IKKE_FUNNET_STARTPUNKT
Out of 36976 6947659:
        Error: Fant ingen veglenkesekvenser i nærheten av søkepunkt: POINT (36975.9457 6947658.8057)
Det er for lang avstand til nærmeste veg  l = NaN


  2 3      Hareid ungdomsskule fv. 61 -> Holstad                        1517 FV61 S3D1 m481-559              l = 77.955
                                                                        1517 FV61 S3D1 m559-632              l = 72.203
                                                                        1517 FV61 S3D1 m632-743              l = 111.43
                                                                        1517 FV61 S3D1 m743-895              l = 151.553
                                                                        1517 FV61 S3D1 m895-946              l = 51.691
                                                                        1517 FV61 S3D1 m946-1012             l = 65.798
                                                                        1517 FV61 S3D1 m1012-1048            l = 35.656


  3 4                         Holstad -> Grimstad aust                  1517 FV61 S3D1 m1048-1125            l = 77.565
                                                                        1517 FV61 S3D1 m1125-1179            l = 53.445
                                                                        1517 FV61 S3D1 m1179-1218            l = 38.815
                                                                        1517 FV61 S3D1 m1218-1307            l = 89.517
                                                                        1517 FV61 S3D1 m1307-1486            l = 179.053
                                                                        1517 FV61 S3D1 m1486-1533            l = 47.068
                                                                        1517 FV61 S3D1 m1533-1557            l = 23.318
                                                                        1517 FV61 S3D1 m1557-1606            l = 49.445


  4 5                   Grimstad aust -> Grimstad vest                  1517 FV61 S3D1 m1606-1609            l = 2.638
                                                                        1517 FV61 S3D1 m1609-1685            l = 75.899
                                                                        1517 FV61 S3D1 m1685-1758            l = 73.708
                                                                        1517 FV61 S3D1 m1758-1766            l = 7.864
                                                                        1517 FV61 S3D1 m1766-1954            l = 187.932
                                                                        1517 FV61 S3D1 m1954-2058            l = 104.452
                                                                        1517 FV61 S3D1 m2058-2132            l = 73.798
                                                                        1517 FV61 S3D1 m2132-2231            l = 99.082


  5 6                   Grimstad vest -> Bjåstad aust                   1517 FV61 S3D1 m2231-2237            l = 5.247
                                                                        1517 FV61 S3D1 m2237-2315            l = 78.415
                                                                        1517 FV61 S3D1 m2315-2423            l = 108.17
                                                                        1517 FV61 S3D1 m2423-2524            l = 100.911
                                                                        1517 FV61 S3D1 m2524-2602            l = 78.216
                                                                        1517 FV61 S3D1 m2602-2618            l = 15.571
                                                                        1517 FV61 S3D1 m2618-2666            l = 47.67
                                                                        1517 FV61 S3D1 m2666-2723            l = 57.935


  6 7                    Bjåstad aust -> Bjåstad vest                   1517 FV61 S3D1 m2723-2744            l = 20.344
                                                                        1517 FV61 S3D1 m2744-2893            l = 149.284
                                                                        1517 FV61 S3D1 m2893-2955            l = 61.845
                                                                        1517 FV61 S3D1 m2955-2987            l = 31.799
                                                                        1517 FV61 S3D1 m2987-3069            l = 81.908
                                                                        1517 FV61 S3D1 m3069-3135            l = 66.366
                                                                        1517 FV61 S3D1 m3135-3148            l = 13.383


  7 8                    Bjåstad vest -> Bigsetkrysset                  1517 FV61 S3D1 m3148-3154            l = 5.882
                                                                        1517 FV61 S3D1 m3154-3190            l = 36.057
                                                                        1517 FV61 S3D1 m3190-3286            l = 96.144
                                                                        1517 FV61 S3D1 m3286-3306            l = 19.398
                                                                        1517 FV61 S3D1 m3306-3338            l = 31.996
                                                                        1517 FV61 S3D1 m3338-3358            l = 20.374
                                                                        1517 FV61 S3D1 m3358-3426            l = 67.696
                                                                        1517 FV61 S3D1 m3426-3455            l = 29.415
                                                                        1517 FV61 S3D1 m3455-3482            l = 26.8
                                                                        1517 FV61 S3D1 m3482-3490            l = 7.448
                                                                        1517 FV61 S3D1 m3490-3533            l = 43.734


  8 9                   Bigsetkrysset -> Byggeli                        1517 FV61 S3D1 m3533-3547            l = 13.654
                                                                        1517 FV61 S3D1 m3547-3555            l = 7.517
                                                                        1517 FV61 S3D1 m3555-3564            l = 9.066
                                                                        1517 FV61 S3D1 m3564-3577            l = 12.945
                                                                        1517 FV61 S3D1 m3577-3731            l = 154.225
                                                                        1517 FV61 S3D1 m3731-3826            l = 95.455
                                                                        1517 FV61 S3D1 m3826-3907            l = 80.824
                                                                        1517 FV61 S3D1 m3907-3942            l = 34.79
                                                                        1517 FV61 S3D1 m3942-4017            l = 74.79
                                                                        1517 FV61 S3D1 m4017-4026            l = 9.331
                                                                        1517 FV61 S3D1 m4026-4050            l = 24.277
                                                                        1517 FV61 S3D1 m4050-4147            l = 96.441
                                                                        1517 FV61 S3D1 m4147-4171            l = 24.006


 9 10                         Byggeli -> Nybøen                         1517 FV61 S3D1 m4171-4304            l = 133.623
                                                                        1517 FV61 S3D1 m4304-4382            l = 77.772
                                                                        1517 FV61 S3D1 m4382-4440            l = 57.78
                                                                        1517 FV61 S3D1 m4440-4465            l = 24.856


10 11                          Nybøen -> Korshaug                       1517 FV61 S3D1 m4465-4490            l = 24.954
                                                                        1517 FV61 S3D1 m4490-4497            l = 7.636
                                                                        1517 FV61 S3D1 m4497-4714            l = 216.416
                                                                        1517 FV61 S3D1 m4714-4716            l = 2.448
                                                                        1517 FV61 S3D1 m4716-4765            l = 49.301
                                                                        1517 FV61 S3D1 m4765-4798            l = 32.586
                                                                        1517 FV61 S3D1 m4798-4953            l = 154.466
                                                                        1517 FV61 S3D1 m4953-4961            l = 8.338
                                                                        1517 FV61 S3D1 m4961-4979            l = 18.489


11 12                        Korshaug -> Rise aust                      1517 FV61 S3D1 m4979-5287            l = 307.256
                                                                        1517 FV61 S3D1 m5287-5314            l = 26.972
                                                                        1517 FV61 S3D1 m5314-5415            l = 100.981
                                                                        1517 FV61 S3D1 m5415-5423            l = 8.576


12 13                       Rise aust -> Rise                           1517 FV61 S3D1 m5423-5520            l = 97.367
                                                                        1517 FV61 S3D1 m5520-5526            l = 5.073
                                                                        1517 FV61 S3D1 m5526-5595            l = 69.465
                                                                        1517 FV61 S3D1 m5595-5786            l = 190.768
                                                                        1517 FV61 S3D1 m5786-5814            l = 27.947
                                                                        1517 FV61 S3D1 m5814-5840            l = 26.202


13 14                            Rise -> Rise vest                      1517 FV61 S3D1 m5840-5853            l = 12.887
                                                                        1517 FV61 S3D1 m5853-6038            l = 185.504
                                                                        1517 FV61 S3D1 m6038-6200            l = 162.083
                                                                        1517 FV61 S3D1 m6200-6205            l = 4.14


14 15                       Rise vest -> Varleitekrysset                1517 FV61 S3D1 m6205-6400            l = 194.967
                                                                        1517 FV61 S3D1 m6400-6759            l = 359.624
                                                                        1517 FV61 S3D1 m6759-7059            l = 299.73
                                                                        1516 FV61 S3D1 m7059-7468            l = 408.987
                                                                        1516 FV61 S3D1 m7468-7954            l = 486.616
                                                                        1516 FV61 S3D1 m7954-8071            l = 117
                                                                        1516 FV61 S3D1 m8071-8081            l = 9.79
                                                                        1516 FV61 S3D1 m8081-8089            l = 8.21
                                                                        1516 FV61 S3D1 m8089-8115            l = 25.179


15 16                 Varleitekrysset -> Ulstein vgs.                   1516 FV61 S3D1 m8115-8350            l = 234.98
                                                                        1516 FV61 S3D1 m8350-8364            l = 14.401
                                                                        1516 FV61 S3D1 m8364-8447            l = 82.954
                                                                        1516 FV61 S3D1 m8447-8452            l = 4.531
                                                                        1516 KV1123 S1D1 m1909-1934          l = 29.013
                                                                        1516 KV1123 S1D1 m1871-1909          l = 38.975
                                                                        1516 KV1123 S1D1 m1860-1871          l = 10.088
                                                                        1516 KV1123 S1D1 m1818-1860          l = 41.973
                                                                        1516 KV1123 S1D1 m1818-1769          l = 49.566


16 17                    Ulstein vgs. -> Støylesvingen                  Error: 4040  IKKE_FUNNET_RUTE 
        Out of 28961 6945248:
                1516 KV1123 S1D1 m1769
        In to 28275 6945289:
                1516 KV1123 S1D1 m994
        (28961 6945248)-(28275 6945289)
                  l = NaN


17 18                   Støylesvingen -> Holsekerdalen                  1516 KV1123 S1D1 m994-990            l = 4.122
                                                                        1516 KV1123 S1D1 m531-990            l = 458.406
                                                                        1516 KV1123 S1D1 m505-531            l = 26.611
                                                                        1516 KV1123 S1D1 m478-505            l = 26.421
                                                                        1516 KV1123 S1D1 m312-478            l = 166.733
                                                                        1516 KV1123 S1D1 m289-312            l = 23.063


18 19                   Holsekerdalen -> Ulsteinvik skysstasjon              GET https://nvdbapiles.atlas.vegvesen.no/posisjon?nord=6.945774337512597e6&ost=27262.18078544963&maks_avstand=10&trafikantgruppe=K
Error: 4042  IKKE_FUNNET_SLUTTPUNKT

        In to 27262 6945774:
        Error: Fant ingen veglenkesekvenser i nærheten av søkepunkt: POINT (27262.1808 6945774.3375)
Det er for lang avstand til nærmeste veg  l = NaN


19 20          Ulsteinvik skysstasjon -> Saunes nord                         GET https://nvdbapiles.atlas.vegvesen.no/posisjon?nord=6.945774337512597e6&ost=27262.18078544963&maks_avstand=10&trafikantgruppe=K
Error: 4041  IKKE_FUNNET_STARTPUNKT
Out of 27262 6945774:
        Error: Fant ingen veglenkesekvenser i nærheten av søkepunkt: POINT (27262.1808 6945774.3375)
Det er for lang avstand til nærmeste veg  l = NaN


20 21                     Saunes nord -> Saunes sør                     1516 FV61 S3D30 m609-611             l = 2.497
                                                                        1516 FV61 S3D30 m569-609             l = 39.929
                                                                        1516 FV61 S3D30 m502-569             l = 67.227
                                                                        1516 FV61 S3D30 m497-502             l = 4.936
                                                                        1516 FV61 S3D30 m405-497             l = 91.453
                                                                        1516 FV61 S3D30 m394-405             l = 11.038
                                                                        1516 FV61 S3D30 m314-394             l = 80.623
                                                                        1516 FV61 S3D30 m260-314             l = 53.874


21 22                      Saunes sør -> Strandabøen                    1516 FV61 S3D30 m258-260             l = 1.825
                                                                        1516 FV61 S3D30 m30-258              l = 228.168
                                                                        1516 FV61 S3D30 m11-30               l = 18.304
                                                                        1516 FV61 S3D30 m4-11                l = 7.405
                                                                        1516 FV61 S3D30 m0-4                 l = 3.956
                                                                        1516 FV61 S3D1 m10639 KD1 m14-19     l = 5
                                                                        1516 FV61 S3D1 m10639 KD1 m19-26     l = 7
                                                                        1516 FV61 S3D1 m10639-10651          l = 13.407
                                                                        1516 FV61 S3D1 m10651-10652          l = 0.431
                                                                        1516 FV61 S3D1 m10652-10653          l = 0.098
                                                                        1516 FV61 S3D1 m10653-10656          l = 5.11
                                                                        1516 FV61 S3D1 m10656-10669          l = 12.559
                                                                        1516 FV61 S3D1 m10669-10723          l = 53.794
                                                                        1516 FV61 S4D1 m0-5                  l = 4.507
                                                                        1516 FV61 S4D1 m5-261                l = 256.08
                                                                        1516 FV61 S4D1 m261-284              l = 23.292


22 23                     Strandabøen -> Dimnakrysset                   1516 FV61 S4D1 m284-319              l = 35.051
                                                                        1516 FV61 S4D1 m319-503              l = 184.229
                                                                        1516 FV61 S4D1 m503-1365             l = 861.461
                                                                        1516 FV61 S4D1 m1365-1370            l = 5.872
                                                                        1516 FV61 S4D1 m1370-1375            l = 4.611
                                                                        1516 FV61 S4D1 m1375-1404            l = 28.893


23 24                    Dimnakrysset -> Botnen                         1516 FV61 S4D1 m1404-2608            l = 1204.166
                                                                        1516 FV61 S4D1 m2608-2659            l = 50.684
                                                                        1516 FV61 S4D1 m2659-3155            l = 495.818
                                                                        1516 FV61 S4D1 m3155-3280            l = 125.172
                                                                        1516 FV61 S4D1 m3280-3363            l = 83.017


24 25                          Botnen -> Garneskrysset                  Error: 4040  IKKE_FUNNET_RUTE 
        Out of 26807 6941534:
                1516 FV61 S4D1 m3363
        In to 26449 6940130:
                1516 FV61 S4D1 m5398 SD1 m141
        (26807 6941534)-(26449 6940130)
                  l = NaN


25 26                   Garneskrysset -> Dragsund sør                   1516 FV61 S4D1 m5398 SD1 m141-173    l = 31.853
                                                                        1516 FV61 S4D1 m5398 SD1 m173-178    l = 5.228
                                                                        1516 FV61 S4D1 m5398 SD1 m178-190    l = 11.532
                                                                        1516 FV61 S4D1 m5398 SD1 m190-208    l = 17.906
                                                                        1516 FV61 S4D1 m5398 SD1 m208-211    l = 3.128
                                                                        1516 FV61 S5D1 m81-168               l = 87.145
                                                                        1516 FV61 S5D1 m168-239              l = 71
                                                                        1516 FV61 S5D1 m239-391              l = 152.229
                                                                        1516 FV61 S5D1 m391-467              l = 75.371
                                                                        1516 FV61 S5D1 m467-564              l = 97.499
                                                                        1516 FV61 S5D1 m564-681              l = 117.189
                                                                        1516 FV61 S5D1 m681-694              l = 13.124
                                                                        1516 FV61 S5D1 m694-848              l = 153.859
                                                                        1516 FV61 S5D1 m848-912              l = 63.473
                                                                        1516 FV61 S5D1 m912-1085             l = 173.375
                                                                        1516 FV61 S5D1 m1085-1273            l = 188.03
                                                                        1516 FV61 S5D1 m1273-1281            l = 8.272
                                                                        1516 FV61 S5D1 m1281-1401            l = 119.985
                                                                        1515 FV61 S5D1 m1401-1412            l = 10.372
                                                                        1515 FV61 S5D1 m1412-1527            l = 115.47
                                                                        1515 FV61 S5D1 m1527-1589            l = 61.977
                                                                        1515 FV61 S5D1 m1589-1879            l = 290.123
                                                                        1515 FV61 S5D1 m1879-1937            l = 57.812
                                                                        1515 FV61 S5D1 m1937-2001            l = 63.738
                                                                        1515 FV61 S5D1 m2001-2004            l = 3.564
                                                                        1515 FV61 S5D1 m2004-2019            l = 14.818


26 27                    Dragsund sør -> Myrvåglomma                    1515 FV61 S5D1 m2019-2389            l = 369.421
                                                                        1515 FV61 S5D1 m2389-2685            l = 295.919
                                                                        1515 FV61 S5D1 m2685-2759            l = 74.329
                                                                        1515 FV61 S5D1 m2759-2765            l = 5.773
                                                                        1515 FV654 S1D1 m0-6                 l = 5.747
                                                                        1515 FV654 S1D1 m6-11                l = 5.648
                                                                        1515 FV654 S1D1 m11-75               l = 63.793
                                                                        1515 FV654 S1D1 m75-172              l = 97.019
                                                                        1515 KV3225 S1D1 m0-3                l = 3.37
                                                                        1515 KV3225 S1D1 m3-30               l = 26.662
                                                                        1515 KV3225 S2D1 m0-23               l = 23.384
                                                                        1515 PV98594 S1D1 m61-72             l = 11.551
                                                                        1515 PV98594 S1D1 m52-61             l = 8.982


27 28                     Myrvåglomma -> Myrvåg                         1515 PV98594 S1D1 m52-61             l = 8.982
                                                                        1515 PV98594 S1D1 m61-72             l = 11.551
                                                                        1515 KV3225 S2D1 m23-72              l = 48.136
                                                                        1515 KV3225 S2D1 m72-191             l = 119.014
                                                                        1515 KV3225 S2D1 m191-196            l = 5.655
                                                                        1515 KV3225 S2D1 m196-408            l = 211.313
                                                                        1515 KV3210 S1D1 m0-31               l = 30.502
                                                                        1515 FV654 S1D1 m591-918             l = 326.685
                                                                        1515 FV654 S1D1 m918-921             l = 2.557


28 29                          Myrvåg -> Aurvåg                         1515 FV654 S1D1 m921-944             l = 23.543
                                                                        1515 FV654 S1D1 m944-1163            l = 219.174
                                                                        1515 FV654 S1D1 m1163-1263           l = 100.079
                                                                        1515 FV654 S1D1 m1263-1276           l = 12.566
                                                                        1515 FV654 S1D1 m1276-1659           l = 383.061
                                                                        1515 FV654 S1D1 m1659-1674           l = 14.731
                                                                        1515 FV654 S1D1 m1674-1759           l = 85.292
                                                                        1515 FV654 S1D1 m1759-1765           l = 6.021
                                                                        1515 FV654 S1D1 m1765-1782           l = 17.02


29 30                          Aurvåg -> Aspevika                       1515 FV654 S1D1 m1782-1852           l = 70.39
                                                                        1515 FV654 S1D1 m1852-2120           l = 267.441
                                                                        1515 FV654 S1D1 m2120-2139           l = 18.622
                                                                        1515 FV654 S1D1 m2139-2291           l = 151.988
                                                                        1515 FV654 S1D1 m2291-2427           l = 136.405


30 31                        Aspevika -> Kalveneset                     1515 FV654 S1D1 m2427-2433           l = 6.332
                                                                        1515 FV654 S1D1 m2433-2449           l = 15.277
                                                                        1515 FV654 S1D1 m2449-2575           l = 126.156
                                                                        1515 FV654 S1D1 m2575-2789           l = 214
                                                                        1515 FV654 S1D1 m2789-2860           l = 71.485
                                                                        1515 FV654 S1D1 m2860-2869           l = 8.515
                                                                        1515 FV654 S1D1 m2869-2892           l = 23.191
                                                                        1515 FV654 S1D1 m2892-2911           l = 19.602
                                                                        1515 FV654 S1D1 m2911-2932           l = 20.207
                                                                        1515 FV654 S1D1 m2932-2961           l = 29.811
                                                                        1515 FV654 S1D1 m2961-3069           l = 107.189
                                                                        1515 FV654 S1D1 m3069-3069           l = 0.7


31 32                      Kalveneset -> Tjørvåg indre                  1515 FV654 S1D1 m3069-3307           l = 237.3
                                                                        1515 FV654 S1D1 m3307-3422           l = 114.925
                                                                        1515 FV654 S1D1 m3422-3724           l = 302.381
                                                                        1515 FV654 S2D1 m0-82                l = 82.297
                                                                        1515 FV654 S2D1 m82-220              l = 137.364


32 33                   Tjørvåg indre -> Tjørvåg                        1515 FV654 S2D1 m220-264             l = 44.457
                                                                        1515 FV654 S2D1 m264-304             l = 39.994
                                                                        1515 FV654 S2D1 m304-400             l = 95.446
                                                                        1515 FV654 S2D1 m400-511             l = 111.834
                                                                        1515 FV654 S2D1 m511-658             l = 147.03
                                                                        1515 FV654 S2D1 m658-688             l = 30.016
                                                                        1515 FV654 S2D1 m688-708             l = 19.122


33 34                         Tjørvåg -> Tjørvågane                     1515 FV654 S2D1 m708-744             l = 36.816
                                                                        1515 FV654 S2D1 m744-877             l = 132.271
                                                                        1515 FV654 S2D1 m877-942             l = 65.401
                                                                        1515 FV654 S2D1 m942-960             l = 18.329
                                                                        1515 FV654 S2D1 m960-1003            l = 42.207
                                                                        1515 FV654 S2D1 m1003-1094           l = 91.813
                                                                        1515 FV654 S2D1 m1094-1108           l = 13.364


34 35                      Tjørvågane -> Tjørvåg nord                   1515 FV654 S2D1 m1108-1189           l = 80.858
                                                                        1515 FV654 S2D1 m1189-1233           l = 43.901
                                                                        1515 FV654 S2D1 m1233-1475           l = 242.609
                                                                        1515 FV654 S2D1 m1475-1564           l = 89.205


35 36                    Tjørvåg nord -> Rafteset                       1515 FV654 S2D1 m1564-1576           l = 11.228
                                                                        1515 FV654 S2D1 m1576-1583           l = 7.67
                                                                        1515 FV654 S2D1 m1583-1630           l = 46.779
                                                                        1515 FV654 S2D1 m1630-1713           l = 83.21
                                                                        1515 FV654 S2D1 m1713-1757           l = 43.944
                                                                        1515 FV654 S2D1 m1757-2079           l = 322.026
                                                                        1515 FV654 S2D1 m2079-2186           l = 107.299
                                                                        1515 FV654 S2D1 m2186-2208           l = 21.721
                                                                        1515 FV654 S2D1 m2208-2277           l = 68.634


36 37                        Rafteset -> Storneset                      1515 FV654 S2D1 m2277-2355           l = 78.572
                                                                        1515 FV654 S2D1 m2355-2648           l = 292.762
                                                                        1515 FV654 S2D1 m2648-2701           l = 52.368
                                                                        1515 FV654 S2D1 m2701-2783           l = 82.395
                                                                        1515 FV654 S2D1 m2783-2836           l = 52.782
                                                                        1515 FV654 S2D1 m2836-2896           l = 60.526
                                                                        1515 FV654 S2D1 m2896-2913           l = 17.196
                                                                        1515 FV654 S2D1 m2913-2915           l = 1.47


37 38                       Storneset -> Stokksund                      1515 FV654 S2D1 m2915-2964           l = 49.229
                                                                        1515 FV654 S2D1 m2964-2967           l = 3.066
                                                                        1515 FV654 S2D1 m2967-3028           l = 60.834
                                                                        1515 FV654 S2D1 m3028-3041           l = 12.8
                                                                        1515 FV654 S2D1 m3041-3118           l = 76.888
                                                                        1515 FV654 S2D1 m3118-3468           l = 350.364
                                                                        1515 FV654 S2D1 m3468-3544           l = 76.32
                                                                        1515 KV3130 S1D1 m457-480            l = 23.796
                                                                        1515 PV3130 S1D1 m37-76              l = 39.642


38 39                       Stokksund -> Notøy                          1515 PV3130 S1D1 m37-76              l = 39.642
                                                                        1515 KV3130 S1D1 m457-480            l = 23.796
                                                                        1515 FV654 S2D1 m3544-3903           l = 358.751
                                                                        1515 FV654 S2D1 m3903-4013           l = 110
                                                                        1515 FV654 S2D1 m4013-4097           l = 83.48
                                                                        1515 FV654 S2D1 m4097-4328           l = 231.004
                                                                        1515 FV654 S2D1 m4328-4346           l = 18.177
                                                                        1515 FV654 S2D1 m4346-4447           l = 100.742
                                                                        1515 FV654 S3D1 m0-246               l = 245.629
                                                                        1515 FV654 S3D1 m246-483             l = 237.569
                                                                        1515 FV654 S3D1 m483-1009            l = 525.683
                                                                        1515 FV654 S3D1 m1009-1038           l = 29.177
                                                                        1515 FV654 S3D1 m1065 SD1 m0-5       l = 5.259


39 40                           Notøy -> Røyra øst                      Error: 4040  IKKE_FUNNET_RUTE 
        Out of 19429 6943497:
                1515 FV654 S3D1 m1065 SD1 m7
        In to 19922 6944583:
                1515 FV654 S3D1 m3060
        (19429 6943497)-(19922 6944583)
                  l = NaN


40 41                       Røyra øst -> Røyra vest                     1515 FV654 S3D1 m3060-3260           l = 200.058
                                                                        1515 FV654 S3D1 m3260-3339           l = 79.319
                                                                        1515 FV654 S3D1 m3339-3384           l = 44.37
                                                                        1515 FV654 S3D1 m3384-3391           l = 7.05


41 42                      Røyra vest -> Frøystadvåg                    Error: 4040  IKKE_FUNNET_RUTE 
        Out of 19605 6944608:
                1515 FV654 S3D1 m3391
        In to 19495 6945400:
                1515 PV99132 S1D1 m48
        (19605 6944608)-(19495 6945400)
                  l = NaN


42 43                     Frøystadvåg -> Frøystadkrysset                Error: 4040  IKKE_FUNNET_RUTE 
        Out of 19495 6945400:
                1515 PV99132 S1D1 m48
        In to 19646 6945703:
                1515 FV654 S3D1 m5114
        (19495 6945400)-(19646 6945703)
                  l = NaN


43 44                 Frøystadkrysset -> Nerøykrysset                   1515 FV654 S3D1 m5114-5221           l = 106.541
                                                                        1515 FV654 S3D1 m5221-5227           l = 5.871
                                                                        1515 FV654 S3D1 m5227-5290           l = 63.454
                                                                        1515 FV654 S3D1 m5290-5296           l = 5.899
                                                                        1515 FV654 S3D1 m5296-5312           l = 16.256
                                                                        1515 FV654 S3D1 m5312-5579           l = 266.742
                                                                        1515 FV654 S3D1 m5579-5644           l = 64.58
                                                                        1515 FV654 S3D1 m5644-6175           l = 531.252
                                                                        1515 FV654 S3D1 m6175-6254           l = 79.504
                                                                        1515 FV654 S3D1 m6254-6258           l = 4.102
                                                                        1515 FV5876 S1D1 m0-5                l = 4.391
                                                                        1515 FV5876 S1D1 m5-32               l = 27.116
                                                                        1515 FV5876 S1D1 m32-38              l = 6.091
                                                                        1515 FV5876 S1D1 m38-53              l = 15.393
                                                                        1515 FV5876 S1D1 m82 SD1 m0-4        l = 3.926
                                                                        1515 FV5876 S1D1 m82 SD1 m4-9        l = 5.077
                                                                        1515 FV5876 S1D1 m82 SD1 m9-29       l = 20.073
                                                                        1515 FV5876 S1D1 m82 SD1 m29-36      l = 6.69


44 45                    Nerøykrysset -> Berge bedehus                  1515 FV5876 S1D1 m82 SD1 m29-36      l = 6.69
                                                                        1515 FV5876 S1D1 m82 SD1 m9-29       l = 20.073
                                                                        1515 FV5876 S1D1 m82 SD1 m4-9        l = 5.077
                                                                        1515 FV5876 S1D1 m82 SD1 m0-4        l = 3.926
                                                                        1515 FV5876 S1D1 m38-53              l = 15.393
                                                                        1515 FV5876 S1D1 m32-38              l = 5.955
                                                                        1515 FV5876 S1D1 m5-32               l = 29.169
                                                                        1515 FV5876 S1D1 m0-5                l = 5.526
                                                                        1515 FV654 S3D1 m6273-6370           l = 97.481
                                                                        1515 FV654 S3D1 m6370-6594           l = 223.323
                                                                        1515 FV654 S3D1 m6594-6662           l = 68.454
                                                                        1515 FV654 S3D1 m6662-6976           l = 313.434
                                                                        1515 FV654 S3D1 m6976-7049           l = 73.291
                                                                        1515 FV654 S3D1 m7049-7066           l = 17.456
                                                                        1515 FV654 S3D1 m7066-7070           l = 3.357
                                                                        1515 FV654 S3D1 m7070-7076           l = 6.289
                                                                        1515 FV654 S3D1 m7076-7080           l = 4.057


45 46                   Berge bedehus -> Elsebøvegen                    1515 FV654 S3D1 m7080-7083           l = 2.705
                                                                        1515 FV654 S3D1 m7083-7198           l = 115.521
                                                                        1515 FV654 S3D1 m7198-7211           l = 13.012
                                                                        1515 FV654 S3D1 m7211-7227           l = 15.563
                                                                        1515 FV654 S3D1 m7227-7314           l = 87.307
                                                                        1515 FV654 S3D1 m7314-7321           l = 7.165
                                                                        1515 FV654 S3D1 m7321-7354           l = 32.359
                                                                        1515 FV654 S3D1 m7354-7354           l = 0.519


46 47                     Elsebøvegen -> Verket                         1515 FV654 S3D1 m7354-7650           l = 295.681


47 48                          Verket -> Berge                          1515 FV654 S3D1 m7650-7666           l = 15.735
                                                                        1515 FV654 S3D1 m7666-7669           l = 3.018
                                                                        1515 FV654 S3D1 m7669-7787           l = 118.571
                                                                        1515 FV654 S3D1 m7787-7874           l = 86.646
                                                                        1515 FV654 S3D1 m7874-7878           l = 3.76


48 49                           Berge -> Hjelmeset                      1515 FV654 S3D1 m7878-7941           l = 63.204
                                                                        1515 FV654 S3D1 m7941-7995           l = 53.953
                                                                        1515 FV654 S3D1 m7995-8034           l = 39.058
                                                                        1515 FV654 S3D1 m8034-8038           l = 8.022
                                                                        1515 FV654 S3D1 m8038 KD1 m0-19      l = 19
                                                                        1515 FV654 S3D1 m8038-8043           l = 7.073
                                                                        1515 FV654 S3D1 m8043-8055           l = 12.928
                                                                        1515 FV654 S3D1 m8055-8089           l = 32.65
                                                                        1515 FV654 S3D1 m8089-8153           l = 64.689
                                                                        1515 FV654 S3D1 m8153-8208           l = 54.784


49 50                       Hjelmeset -> Demingane                      1515 FV654 S3D1 m8208-8219           l = 10.743
                                                                        1515 FV654 S3D1 m8219-8255           l = 35.917
                                                                        1515 FV654 S3D1 m8255-8456           l = 201.347
                                                                        1515 FV654 S3D1 m8456-8559           l = 102.536
                                                                        1515 FV654 S3D1 m8559-8576           l = 16.198
                                                                        1515 FV654 S3D1 m8576-8590           l = 13.312
                                                                        1515 FV654 S3D1 m8590-8599           l = 9.13
                                                                        1515 FV654 S3D1 m8599-8617           l = 18.766


50 51                       Demingane -> Eggesbønes                     1515 FV654 S3D1 m8617-8694           l = 77.097
                                                                        1515 FV654 S3D1 m8694-9071           l = 376.112
                                                                        1515 FV654 S3D1 m9071-9074           l = 3.211
                                                                        1515 FV654 S3D1 m9111 SD1 m0-6       l = 6.023
                                                                        1515 FV654 S3D1 m9111 SD1 m6-65      l = 58.844


51 52                      Eggesbønes -> Myklebust                      1515 FV654 S3D1 m9111 SD1 m65-69     l = 3.829
                                                                        1515 FV654 S3D1 m9111 SD1 m69-76     l = 7.13
                                                                        1515 FV654 S3D1 m9149-9202           l = 53.861
                                                                        1515 FV654 S3D1 m9202-9214           l = 11.24
                                                                        1515 FV654 S3D1 m9214-9218           l = 4.388
                                                                        1515 FV654 S3D1 m9218-9305           l = 86.904
                                                                        1515 FV654 S3D1 m9305-9314           l = 8.868
                                                                        1515 FV654 S3D1 m9314-9320           l = 5.676
                                                                        1515 FV654 S3D1 m9320-9353           l = 33.166


52 53                       Myklebust -> Herøy kyrkje                   1515 FV654 S3D1 m9353-9361           l = 8.136
                                                                        1515 FV654 S3D1 m9361-9457           l = 96
                                                                        1515 FV654 S3D1 m9457-9489           l = 32.456
                                                                        1515 FV654 S3D1 m9489-9608           l = 118.84
                                                                        1515 FV654 S3D1 m9608-9674           l = 65.558
                                                                        1515 FV654 S3D1 m9674-9684           l = 10.492
                                                                        1515 FV654 S3D1 m9684-9698           l = 13.715
                                                                        1515 FV654 S3D1 m9698-9741           l = 42.865
                                                                        1515 FV654 S3D1 m9741-9892           l = 151.193
                                                                        1515 FV654 S3D1 m9892-9936           l = 43.795
                                                                        1515 FV654 S3D1 m9936-10054          l = 117.822
                                                                        1515 FV654 S3D1 m10054-10060         l = 6.272
                                                                        1515 FV654 S3D1 m10060-10066         l = 6.1
                                                                        1515 FV654 S3D1 m10066-10084         l = 18.435
                                                                        1515 FV654 S3D1 m10115 SD1 m0-6      l = 5.866
                                                                        1515 FV654 S3D1 m10115 SD1 m6-13     l = 7.399
                                                                        1515 FV654 S3D1 m10115 SD1 m13-44    l = 30.379


53 54                    Herøy kyrkje -> Fosnavåg sparebank             1515 FV654 S3D1 m10115 SD1 m44-61    l = 17.355
                                                                        1515 FV654 S3D1 m10115 SD1 m61-69    l = 7.586
                                                                        1515 FV654 S3D1 m10147-10185         l = 37.975
                                                                        1515 FV654 S3D1 m10185-10230         l = 44.862
                                                                        1515 FV654 S3D1 m10230-10283         l = 53.053
                                                                        1515 FV654 S3D1 m10283-10445         l = 161.573
                                                                        1515 FV654 S3D1 m10445-10499         l = 54.752
                                                                        1515 FV654 S3D1 m10499-10618         l = 119.07
                                                                        1515 FV654 S3D1 m10618-10702         l = 83.19
                                                                        1515 FV654 S3D1 m10702-10782         l = 80.502
                                                                        1515 FV654 S3D1 m10782-10836         l = 53.601


54 55              Fosnavåg sparebank -> Fosnavåg terminal                   GET https://nvdbapiles.atlas.vegvesen.no/posisjon?nord=6.947514879242669e6&ost=16063.782613804331&maks_avstand=10&trafikantgruppe=K
Error: 4042  IKKE_FUNNET_SLUTTPUNKT

        In to 16064 6947515:
        Error: Fant ingen veglenkesekvenser i nærheten av søkepunkt: POINT (16063.7826 6947514.8792)
Det er for lang avstand til nærmeste veg  l = NaN
=#