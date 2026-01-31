######################################################
# This (towards the end) tests on the public api level 
######################################################
using Test
using RouteSlopeDistance
#=
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
=#
using JSON3: pretty
using Plots
# Define M (example locations matrix) and plotting 
include("common.jl")

#############
# Spot checks
#############

start, stop = 17, 18
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
title = rpad("$start", 3) * na1 * " til " * na2
print(lpad("$start $stop", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
println(link_split_key(ea1, no1, ea2, no2))
d1 = route_leg_data(ea1, no1, ea2, no2)
pl = plot_elevation_slope_speed_vs_progression(d1, na1, na2)
title!(pl[1], title)

start, stop = 18, 19
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
title = rpad("$start", 3) * na1 * " til " * na2
print(lpad("$start $stop", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
println(link_split_key(ea1, no1, ea2, no2))
d2 = route_leg_data(ea1, no1, ea2, no2)
pl = plot_elevation_slope_speed_vs_progression(d2, na1, na2)
title!(pl[1], title)


d3 = join_route_data(d1, d2)
na1 = M[17, 1]
na2 = M[19, 1]
title = rpad("$start", 3) * na1 * " til " * na2
pl = plot_elevation_slope_speed_vs_progression(d3, na1, na2)
title!(pl[1], title)

pl = plot_inspect_continuity(d3[:multi_linestring])
title!(pl[1], title)
