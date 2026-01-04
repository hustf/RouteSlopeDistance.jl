# This file tests callees of `extract_multi_linestrings` and similar.
using Test
using RouteSlopeDistance
using RouteSlopeDistance: patched_post_beta_vegnett_rute
using RouteSlopeDistance: Quilt
using RouteSlopeDistance: parse_multilinestring_values_and_structure
using RouteSlopeDistance: segments_sortorder_and_reversed

# Define M (example locations matrix) and plotting 
include("common.jl")

# Test a non-patched or point corrected segment. This also returns just one segment.
start = 5
stop = 6
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
tit = rpad("$start", 3) * na1 * " til " * na2
q = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2);
# This one is simple: No splitting prior to request.
@test length(q.patches) == 1
@test length(q.patches) == 1
o = q.patches[1]
# In Api v4, segments are unordered and still sometimes flipped.
# This is unordered and flipped
mls  = parse_multilinestring_values_and_structure(o)
order, reversed = segments_sortorder_and_reversed(mls, ea1, no1)
@test order == [6, 5, 8, 7, 4, 3, 2, 1]
@test reversed == Bool[1, 1, 1, 1, 1, 1, 1, 1]
# Inspect to verify
plot_inspect_continuity(mls; order, reversed );
title!(pl[2], na1 * " til " * na2)

# Test a more complicated stretch
start = 1
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[start + 1, :]
tit = rpad("$start", 3) * na1 * " til " * na2
q = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)
@test length(q.patches) == 1
mls  = parse_multilinestring_values_and_structure(q)
order, reversed = segments_sortorder_and_reversed(mls, ea1, no1)
@test order == [12, 11, 13, 10, 9, 8, 7, 15, 16, 14, 3, 4, 5, 6, 2, 1]
@test reversed ==  Bool[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1]
pl = plot_inspect_continuity(mls; order, reversed);
title!(pl[2], tit)




# Test a stretch with multiple patches ("waypoints" from config file)
start = 18
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[start + 1, :]
tit = rpad("$start", 3) * na1 * " til " * na2
q = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2);
@test length(q.patches) == 2
mls  = parse_multilinestring_values_and_structure(q)
order, reversed = segments_sortorder_and_reversed(mls, ea1, no1)
minimum([o.lengde for o in q.patches[1].vegnettsrutesegmenter])
minimum([o.lengde for o in q.patches[2].vegnettsrutesegmenter])
@test order == [10, 8, 9, 17, 18, 16, 15, 20, 19, 13, 12, 11, 14, 4, 1, 5, 2, 3, 6, 7]
@test reversed ==  Bool[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0]
pl = plot_inspect_continuity(mls; order, reversed);
title!(pl[2], tit)


for start in 1:(size(M,1) - 1)
    na1, ea1, no1 = M[start, :]
    na2, ea2, no2 = M[start + 1, :]
    tit = rpad("$start", 3) * na1 * " til " * na2
    printstyled("$start: $tit \n", color=:blue)
    q = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2)
    mls  = parse_multilinestring_values_and_structure(q)
    order, reversed = segments_sortorder_and_reversed(mls, ea1, no1)
    pl = plot_inspect_continuity(mls; order, reversed)
    title!(pl[2], tit)
    display(pl)
    if length(q.fromtos) > 1
        @warn "$tit has waypoints"
    end
end

# Test a route that would previously be too much trouble
start = 1
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[end, :]
tit = rpad("$start", 3) * na1 * " til " * na2
q = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2);
@test length(q.patches) == 1
mls  = parse_multilinestring_values_and_structure(q)
order, reversed = segments_sortorder_and_reversed(mls, ea1, no1)
minimum([o.lengde for o in q.patches[1].vegnettsrutesegmenter])
pl = plot_inspect_continuity(mls; order, reversed);
title!(pl[2], tit)


# Test a route that would previously be too much trouble

na2 = "Driveklepp"
ea2, no2 = 40033.11, 6922339.57
tit = rpad("$start", 3) * na1 * " til " * na2
q = patched_post_beta_vegnett_rute(ea1, no1, ea2, no2);
@test length(q.patches) == 1
mls  = parse_multilinestring_values_and_structure(q)
order, reversed = segments_sortorder_and_reversed(mls, ea1, no1)
pl = plot_inspect_continuity(mls; order, reversed);
title!(pl[2], tit)
