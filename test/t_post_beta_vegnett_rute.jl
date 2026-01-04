# `post_beta_vegnett_rute` is a lower abstraction level.
#  'patched_post_beta_vegnett_rute` uses this internally.

using Test
using RouteSlopeDistance
using RouteSlopeDistance: post_beta_vegnett_rute
using RouteSlopeDistance: extract_prefixed_vegsystemreferanse, extract_length, extract_multi_linestrings
# Define M (example locations matrix) and plotting 
include("common.jl")

# This route should be easy
start = 5
stop = 6
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
o = post_beta_vegnett_rute(ea1, no1, ea2, no2)
refs = extract_prefixed_vegsystemreferanse(o, ea1, no1, ea2, no2)
@test refs[1] == "1517 FV61 S3D1 m2231-2236"
Δls = extract_length(o, ea1, no1)
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
@test_throws AssertionError extract_prefixed_vegsystemreferanse(o, ea1, no1, ea2, no2)
# Previous functionality - might be relied on downstream?
#@test length(refs) == 1
#@test startswith(refs[1], "Error: 4041")

# Test status 4042. This also triggers Http error 404. We don't suppress that mistake.
start = 54
stop = 55
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
o = post_beta_vegnett_rute(ea1, no1, ea2, no2)
@test_throws AssertionError extract_prefixed_vegsystemreferanse(o, ea1, no1, ea2, no2)
# Previous functionality - might be relied on downstream?
#@test length(refs) == 1
#@test startswith(refs[1], "Error: 4042")

# Test status 4040
start = 39
stop = 40
na1, ea1, no1 = M[start, :]
na2, ea2, no2 = M[stop, :]
o = post_beta_vegnett_rute(ea1, no1, ea2, no2)
refs = extract_prefixed_vegsystemreferanse(o, ea1, no1, ea2, no2)
@test length(refs) == 1
@test startswith(refs[1], "Error: 4040")


#=
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

=#