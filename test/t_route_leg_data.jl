########################################################
# This (towards the end) tests on the public api level (route_leg_data)
# and also on a level beneath the public api level.
#
# It also extends the exported plot definition 
# `plot_elevation_and_slope_vs_progression` 
# to add more details. 
########################################################
using Test
using RouteSlopeDistance
using RouteSlopeDistance: patched_post_beta_vegnett_rute, 
    extract_prefixed_vegsystemreferanse,
    extract_length,
    extract_multi_linestrings,
    fartsgrense_from_prefixed_vegsystemreferanse,
    speed_nested_in_intervals, 
    modify_fartsgrense_with_speedbumps!,
    link_split_key,
    progression_and_radii_of_curvature_from_multiline_string,
    smooth_slope_from_multiline_string
using JSON3: pretty
using Plots
# Define M (example locations matrix) and plotting 
include("common.jl")

rw = 8
na1, ea1, no1 = M[rw, :]
na2, ea2, no2 = M[rw + 1 , :]
println(lpad("$rw $(rw + 1)", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
easting1, northing1, easting2, northing2 = ea1, no1, ea2, no2

# Lookups are quite slow; we need to store results. 
# See `delete_memoization_file`. New entries are added after 
# successful calls to `route_leg_data`.
#
# After deleting memoization file:
# 0.277185 seconds (3.64 k allocations: 305.041 KiB, 2 lock conflicts)
@time q = patched_post_beta_vegnett_rute(easting1, northing1, easting2, northing2);

#  0.000185 seconds (455 allocations: 52.797 KiB)
@time refs, revs = extract_prefixed_vegsystemreferanse(q);

#  0.000119 seconds (139 allocations: 26.203 KiB)
@assert ! startswith(refs[1], "Error") refs[1];

#  0.000110 seconds (138 allocations: 26.141 KiB)
@time lengths = extract_length(q);

#   0.000010 seconds (3 allocations: 352 bytes)
progression_at_ends = append!([0.0], cumsum(lengths))

# 0.000389 seconds (608 allocations: 76.211 KiB)
@time mls, vrev = extract_multi_linestrings(q);
@assert vrev == revs

@test length(progression_at_ends) == length(mls) + 1

# 0.000280 seconds (1.96 k allocations: 181.469 KiB)
@time  progression, radius_of_curvature  = progression_and_radii_of_curvature_from_multiline_string(mls, progression_at_ends)

@test issorted(progression)
@test length(radius_of_curvature) == length(progression)
# 0.000126 seconds (177 allocations: 33.203 KiB)
@time slope = smooth_slope_from_multiline_string(mls, progression);
@test length(slope)  == length(progression)


# 1.374210 seconds (32.42 k allocations: 2.356 MiB, 13 lock conflicts)
@time fartsgrense_tuples = fartsgrense_from_prefixed_vegsystemreferanse.(refs, revs);
@assert fartsgrense_tuples isa Vector{Tuple{Float64, Int64, Int64}}

if isnan(fartsgrense_tuples[1][1])
    fartsgrense_tuples[1] = (1.0, 50, 50)
end

#  0.000038 seconds (121 allocations: 13.375 KiB)
@time speed_lims_in_intervals = speed_nested_in_intervals(fartsgrense_tuples, mls);

#  2.128427 seconds (1.65 k allocations: 144.828 KiB)
#  0.707068 seconds (1.65 k allocations: 144.828 KiB)
@time modify_fartsgrense_with_speedbumps!(speed_lims_in_intervals, refs, mls);


# Unpack nested speed limitations. Apply at first coordinate of each interval (there is one more coordinate than intervals)
speed_limitation = vcat(speed_lims_in_intervals..., speed_lims_in_intervals[end][end])
@test length(progression) == length(speed_limitation) 

##########################
# Finally, top level test.
##########################
# Potentially affected by stored data, do `delete_memoization_file()`!
# Test 'overlapping' speed limit segments where we exit or enter a road:

ea1 = 38751
no1 = 6946371
no2 = 6946328
ea2 = 38786
d = route_leg_data(ea1, no1, ea2, no2)
@test d[:speed_limitation] == [40.0, 40.0, 40.0, 40.0, 40.0, 40.0, 40.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0]



# The below takes 1-2 minutes, and serializes these request for faster run 
# (0.1 second next time).
# Call `delete_memoization_file` to start over.
rws = 1:(size(M)[1])
@time for (start, stop) in zip(rws[1: (end - 1)], rws[2:end])
    na1, ea1, no1 = M[start, :]
    na2, ea2, no2 = M[stop, :]
    print("\n", lpad("$start $stop", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
    println(link_split_key(ea1, no1, ea2, no2))
    d = route_leg_data(ea1, no1, ea2, no2)
    println("   Progression end: ", d[:progression][end])
end 

#############
# Spot checks
#############

start, stop = 17, 18
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
title = rpad("$start", 3) * na1 * " til " * na2
print(lpad("$start $stop", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
println(link_split_key(ea1, no1, ea2, no2))
d = route_leg_data(ea1, no1, ea2, no2)
pl = plot_elevation_slope_speed_vs_progression(d, na1, na2)
title!(pl[1], title)

# 
start, stop = 45, 44
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
title = rpad("$start", 3) * na1 * " til " * na2
print(lpad("$start $stop", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
println(link_split_key(ea1, no1, ea2, no2))
d = route_leg_data(ea1, no1, ea2, no2)
pl = plot_elevation_slope_speed_vs_progression(d, na1, na2)
title!(pl[1], title)


# 
start, stop = 25, 26
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
title = rpad("$start", 3) * na1 * " til " * na2
print(lpad("$start $stop", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
println(link_split_key(ea1, no1, ea2, no2))
d = route_leg_data(ea1, no1, ea2, no2)
pl = plot_elevation_slope_speed_vs_progression(d, na1, na2)
title!(pl[1], title)

# Very short part of geometry
start, stop = 14, 13
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
title = rpad("$start", 3) * na1 * " til " * na2
print(lpad("$start $stop", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
println(link_split_key(ea1, no1, ea2, no2))
d = route_leg_data(ea1, no1, ea2, no2)
pl = plot_elevation_slope_speed_vs_progression(d, na1, na2)
title!(pl[1], title)

# Very short (<1m) segment
start, stop = 31, 30
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
title = rpad("$start", 3) * na1 * " til " * na2
print(lpad("$start $stop", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
println(link_split_key(ea1, no1, ea2, no2))
d = route_leg_data(ea1, no1, ea2, no2)
pl = plot_elevation_slope_speed_vs_progression(d, na1, na2)
title!(pl[1], title)


# Large internal gap in geometry
na1 = "Eika"
ea1 = 28130
no1 = 6934881
na2 = "Nær midt tunnell"
ea2 = 27804
no2 = 6932152
title = rpad("$start", 3) * na1 * " til " * na2
print(lpad("", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
println(link_split_key(ea1, no1, ea2, no2))
d = route_leg_data(ea1, no1, ea2, no2)
pl = plot_elevation_slope_speed_vs_progression(d, na1, na2)
title!(pl[1], title)

# Zoom in on hilltop
na1 = "Dragsund vest"
ea1 = 25183
no1 = 6939251
na2 = "Dragsund aust"
ea2 = 25589
no2 = 6939427
title = rpad("$start", 3) * na1 * " til " * na2
print(lpad("", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
println(link_split_key(ea1, no1, ea2, no2))
d = route_leg_data(ea1, no1, ea2, no2)
pl = plot_elevation_slope_speed_vs_progression(d, na1, na2)
title!(pl[1], title)



na2 = "Dragsund vest"
ea2 = 25183
no2 = 6939251
na1 = "Dragsund aust"
ea1 = 25589
no1 = 6939427
title = rpad("$start", 3) * na1 * " til " * na2
print(lpad("", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
println(link_split_key(ea1, no1, ea2, no2))
d = route_leg_data(ea1, no1, ea2, no2)
pl = plot_elevation_slope_speed_vs_progression(d, na1, na2)
title!(pl[1], title)




# Test a ferry journey. 
# Koparneset ferjekai  Årvika ferjekai (13869 6928277)-(13742 6930773)
na1 = "Koparneset ferjekai"
ea1 = 13869
no1 = 6928277
na2 = "Årvika ferjekai"
ea2 = 13742
no2 = 6930773
title = rpad("$start", 3) * na1 * " til " * na2
d = route_leg_data(ea1, no1, ea2, no2)
@test d[:progression_at_ends] == [0.0, 8.515020331079693, 21.515020331079693, 1614.8920203310797, 2795.55202033108, 2809.63002033108, 2819.8839485898657]
pl = plot_elevation_slope_speed_vs_progression(d, na1, na2);
title!(pl[1], title)
