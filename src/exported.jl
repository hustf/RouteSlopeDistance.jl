"""
    route_leg_data(easting1::T, northing1::T, easting2::T, northing2::T; default_fartsgrense = 50) where T <: Int
    route_leg_data(easting1::T, northing1::T, easting2::T, northing2::T; default_fartsgrense = 50) where T <: Float64
    route_leg_data(;start = "", slutt = ""; default_fartsgrense = 50)
    route_leg_data(s::String; default_fartsgrense = 50)

    --> Dict{Any}

Arguments are start and end points given in UTM33 coordinates. Arguments are converted to integers.

Results are memoized and stored to disk. Results are stored after rounding 
input arguments to whole numbers, i.e. at a resolution of 1 m.

For easy copy / paste from map applications, 's' can be any string containing url-style arguments
'start' and 'slutt'.

`default_fartsgrense` is used in case the starting point has no defined speed limit, e.g. in bus terminals.


# Output notes

`slope` is vertical / horizontal progression. Positive is uphill.
'radius of curvature' is signed. The vertical component of curves are ignored, but may slightly affect the result. See test example.
`speed limitation` include a reduction from speed humps of 15 km/t at those points.
'key' is included for backward reference, and can be reused as input argument.



# Example

Three calls, same result:
```
julia> s = "https://nvdbapiles-v3.atlas.vegvesen.no/beta/vegnett/rute?start=23593.713839066448,6942485.5900078565&slutt=23771.052968726202,6942714.9388697725&ma......etc"

julia route_leg_data(s);

julia> s = "(23594 6942486)-(23771 6942715)"

julia> route_leg_data(s);

julia> route_leg_data(;start = "23593.713839066448,6942485.5900078565", slutt = "23771.052968726202,6942714.9388697725");

julia> route_leg_data(23594,6942486, 23771,6942715);
Curvature limited velocity: 32.46935208780521 km/h at 109.79520214324043 m due to radius 67.78927629898796
    Route data (23594 6942486)-(23771 6942715) stored in C:\\Users\\f\\RouteSlopeDistance.jls
Dict{Symbol, Any} with 7 entries:
  :radius_of_curvature         => [NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN  …  170.586, 145.066, 131.182, 123.6, 119.802, 118.416, 120.765, 120.486, NaN, NaN] 
  :multi_linestring            => [[(23594.2, 6.94249e6, 10.483), (23594.1, 6.94249e6, 10.507), (23593.1, 6.9425e6, 10.657), (23592.9, 6.9425e6, 10.667), (23591.7, 6.9…
  :prefixed_vegsystemreferanse => ["1516 FV5884 S1D1 m6860-7196"]
  :key                         => "(23594 6942486)-(23771 6942715)"
  :progression                 => [0.0, 1.1945, 13.1443, 16.6898, 28.4362, 32.7958, 44.4848, 49.8823, 63.0743, 68.2845  …  282.645, 290.253, 299.265, 302.855, 309.522,…
  :speed_limitation            => [80.0, 80.0, 80.0, 80.0, 80.0, 80.0, 80.0, 80.0, 80.0, 80.0  …  80.0, 80.0, 80.0, 80.0, 80.0, 80.0, 80.0, 80.0, 80.0, 80.0]
  :slope                       => [0.0094845, 0.0094845, 0.00677416, 0.00667992, 0.00712934, 0.00740014, 0.00844093, 0.00884124, 0.0103206, 0.0105568  …  -0.0116806, -…

```
"""
function route_leg_data(easting1::T, northing1::T, easting2::T, northing2::T; default_fartsgrense = 50) where T <: Int
    # Use stored data if available.
    key = link_split_key(easting1, northing1, easting2, northing2)
    thisdata = get_memoized_value(key)
    if ! isempty(thisdata) 
        return thisdata
    end
    # Identify the bits of road we're taking from 1 to 2. This retrieves
    # vegsystemreferanser, individual lengths of each ref, and curve
    # geometry for each. All packed in q...
    q = patched_post_beta_vegnett_rute(easting1, northing1, easting2, northing2)
    refs, revs = extract_prefixed_vegsystemreferanse(q)
    @assert ! startswith(refs[1], "Error") refs[1]
    # The length of individual segments 
    lengths = extract_length(q)
    # Progression at start of first segment, start of second ... end of last.
    # This counts from zero at closest road point to (easting1, northing1)
    progression_at_ends = append!([0.0], cumsum(lengths))
    # Was there any progression at all?
    if progression_at_ends == [0.0, 0.0]
        # Sometimes we get a zero-length distance. For example, 
        # a ferry crossing. This happens if ea1 == ea2 && no1 == no2
        # after we ran request modficiations (or even before)
        throw("TODO: examine why. Ferries are now considered (API v4) with points on sea.")
        thisdata = Dict(:key => key,
                        :progression_at_ends => progression_at_ends,
                        )
        # Store results on disk and return early.
        set_memoized_value(key, thisdata)
        return thisdata
    end
    # 3d points, nested. Some were received in the opposite direction of our request,
    # then reversed. 
    mls, reversed = extract_multi_linestrings(q)
    @assert reversed == revs "reversed = $reversed \n\t revs = $revs"
    @assert length(progression_at_ends) == length(mls) + 1
    @assert length(mls) == length(reversed)
    # Use bsplines to find signed radius of curvature.
    # Curve ends and extreme large radii get value NaN (Not A Number)
    # Also match lengths between coordinates with the authoritative
    # progression at start and end of each curve.
    progression, radius_of_curvature = progression_and_radii_of_curvature_from_multiline_string(mls, progression_at_ends)
    @assert issorted(progression)
    @assert length(radius_of_curvature) == length(progression)
    # Finally detail slope also. 
    slope = smooth_slope_from_multiline_string(mls, progression)

    # We have unpacked the useful information from the first request.
    # Now ask for related information, and unpack it.    
    # 
    # The tuples refer to the nominal direction of segments.
    # Robustly testing the exact location of changes in fartsgrense within a selection of segments
    # is hard.
    # This would be easier on long segments, and easier graphically. 
    # The same goes for the exact location of speed bumps. 'metrering'
    # is quite complicated in some places. However, segments with changes may often be short,
    # so this is of no great importance to travel times.
    fartsgrense_tuples = fartsgrense_from_prefixed_vegsystemreferanse.(refs, reversed)
    # End stops may be without defined fartsgrense. However, we need 
    # a start value, so modify if missing:
    @assert fartsgrense_tuples isa Vector{Tuple{Float64, Int64, Int64}} typeof(fartsgrense_tuples)
    if isnan(fartsgrense_tuples[1][1])
        fartsgrense_tuples[1] = (1.0, default_fartsgrense, default_fartsgrense)
    end
    # 
    # Detail fartsgrense on every point of each multi_linestring. We'll 
    # unpack further below.
    speed_lims_in_intervals = speed_nested_in_intervals(fartsgrense_tuples, mls)
    # Practical speed limit is reduced by speedbumps.
    # Make further requests for speedbumps and reduce
    # the speeed limit at each bump's coordinates. In-place function.
    modify_fartsgrense_with_speedbumps!(speed_lims_in_intervals, refs, mls)
    # 
    # Unpack nested speed limitations.
    speed_limitation = vcat(speed_lims_in_intervals..., speed_lims_in_intervals[end][end])
    @assert length(progression) == length(speed_limitation) 

    # Sum up
    thisdata = Dict(:prefixed_vegsystemreferanse => refs,
        :progression => progression,
        :speed_limitation => speed_limitation,
        :slope => slope,
        :multi_linestring => mls,
        :key => key,
        :radius_of_curvature => radius_of_curvature,
        :progression_at_ends => progression_at_ends,
        :fartsgrense_tuples => fartsgrense_tuples)
    # Store results on disk.
    set_memoized_value(key, thisdata)
    return thisdata
end
function route_leg_data(easting1::T, northing1::T, easting2::T, northing2::T; default_fartsgrense = 50) where T <: Float64
    ea1 = Int(round(easting1))
    no1 = Int(round(northing1))
    ea2 = Int(round(easting2))
    no2 = Int(round(northing2))
    route_leg_data(ea1, no1, ea2, no2; default_fartsgrense)
end
function route_leg_data(;start = "", slutt = "", default_fartsgrense = 50)
    stea, stno = split(start, ',')
    slea, slno = split(slutt, ',')
    ea1 = Int(round(tryparse(Float64, stea)))
    no1 = Int(round(tryparse(Float64, stno)))
    ea2 = Int(round(tryparse(Float64, slea)))
    no2 = Int(round(tryparse(Float64, slno)))
    route_leg_data(ea1, no1, ea2, no2; default_fartsgrense)
end
function route_leg_data(s::String; default_fartsgrense = 50)
    if contains(s, '?')
        # url-style
        args = split(split(s, '?')[2], '&')
        @assert startswith(args[1], "start")
        @assert startswith(args[2], "slutt")
        start = split(args[1], '=')[2]
        slutt = split(args[2], '=')[2]
    else
        @assert contains(s, '-')
        # key-style: "(23594 6942486)-(23771 6942715)"
        args = split(s, '-')
        start = replace(strip(args[1], ['(', ')'] ), ' ' => ',')
        slutt = replace(strip(args[2], ['(', ')'] ), ' ' => ',')
    end
    route_leg_data(;start, slutt, default_fartsgrense)
end

"""
    delete_memoization_file()

Start over after results are invalidated.
"""
function delete_memoization_file()
    fna = _get_memoization_filename_but_dont_create_file()
    if isfile(fna) 
        rm(fna)
        println("Removed $fna")
    else
        println("$fna Didn't and doesn't exist.")
    end
end


"""
    unique_unnested_coordinates_of_multiline_string(mls::Vector{ Vector{Tuple{Float64, Float64, Float64}}})
    ---> Vector{Float64}, Vector{Float64}, Vector{Float64}

We're joining curves where two ends are identical.
We don't check that though, so if you take unordered segments in here, it's on you.
"""
function unique_unnested_coordinates_of_multiline_string(mls::Vector{ Vector{Tuple{Float64, Float64, Float64}}})
    vx = Float64[] 
    vy = Float64[] 
    vz = Float64[] 
    for i in 1:length(mls)
        p = mls[i]
        px = map(point -> point[1], p)
        py = map(point -> point[2], p)
        pz = map(point -> point[3], p)
        if i == 1
            append!(vx, px)
            append!(vy, py)
            append!(vz, pz)
        else
            append!(vx, px[2:end])
            append!(vy, py[2:end])
            append!(vz, pz[2:end])
        end
    end
    vx, vy, vz
end

"""
    plot_elevation_and_slope_vs_progression(d::Dict, name1, name2; layout = (1, 1))
    ---> Plots.Plot

# Example
```
julia> plot_elevation_and_slope_vs_progression(d, name1, name2; layout = (2, 1))
```
"""
function plot_elevation_and_slope_vs_progression(d::Dict, name1, name2; layout = (1, 1))
    p = plot(layout = layout, size = (1200, 800), thickness_scaling = 2, framestyle=:origin, 
        legend = false, gridlinewidth = 2, gridstyle = :dash)
    plot_elevation_and_slope_vs_progression!(p[1], d, name1, name2)
end

"""
    plot_elevation_slope_speed_vs_progression(d::Dict, na1, na2)

"""
function plot_elevation_slope_speed_vs_progression(d::Dict, na1, na2)
    p = plot_elevation_and_slope_vs_progression(d, na1, na2; layout = (2, 1))
    plot_speed_limit_vs_progression!(p[2], d)
    p
end

"""
    coordinate_key(ingoing::Bool, ea, no)
    --> String

'no' is northing
'ea' is easting
'ingoing' = true: This point is fit for driving
in to this destination.
'ingoing' = false: Exit the origin here.

Often, the entry point to a route is different than
the exit point, and this matters to finding routes.
E.g. one enters a spot from one road (exits the route),
and exits the spot (enters the route) to another road. 

Prepare or look up entries for coordinate replacements.
This patches for status code 4041 and 4042.

One could make the value (the replacement) manually from
e.g. Norgeskart.
""" 
coordinate_key(ingoing::Bool, ea, no) = (ingoing ? "In to " : "Out of " ) * "$(Int(round(ea))) $(Int(round(no)))"

"""
    link_split_key(ea1, no1, ea2, no2)
    link_split_key(start_pt::T, end_pt::T) where T<:Tuple{Float64, Float64, Float64}
    --> String

'no1' is northing start
'ea1' is easting start
'no2' is northing start
'ea2' is easting start

Prepare or look up entries for link splits.

One could make the value (the replacement) manually from
e.g. Norgeskart.   

# Consider TODO: Use tuple notation, with comma: (a, b)
"""
link_split_key(ea1, no1, ea2, no2) = "($(Int(round(ea1))) $(Int(round(no1))))-($(Int(round(ea2))) $(Int(round(no2))))"
function link_split_key(start_pt::T, end_pt::T) where T<:Tuple{Float64, Float64, Float64}
    ea1, no1, _ = start_pt
    ea2, no2, _ = end_pt
    link_split_key(ea1, no1, ea2, no2)
end