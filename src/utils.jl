# Small functions used elsewhere

"""
    reverse_linestrings_where_needed!(multi_linestring, easting1, northing1)
    ---> Vector{Bool}

In-place reversing of linestrings point order for continuity. 

Returns a vector where 'true' indicated that this linestring was reversed.
This may be used for reversing associated data.
"""
function reverse_linestrings_where_needed!(multi_linestring, easting1, northing1)
    previous_point_projected = (easting1, northing1)
    reversed = Bool[]
    for i in eachindex(multi_linestring)
        current_first_point_projected = multi_linestring[i][1][1:2]
        current_last_point_projected = multi_linestring[i][end][1:2]
        isrev = is_reversed(previous_point_projected, current_first_point_projected, current_last_point_projected)
        if isrev
            reverse!(multi_linestring[i])
        end
        push!(reversed, isrev)
        previous_point_projected = multi_linestring[i][end]
    end
    reversed
end

function is_reversed(previous_point, current_first_point, current_last_point)
    d_first = distance_between(previous_point, current_first_point)
    d_last = distance_between(previous_point, current_last_point)
    d_last < d_first
end

"""
    check_continuity_of_multi_linestring(multi_linestring)

The last point in a linestring should match with the first point of the next.
We do allow some leeway here, 50 cm.
"""
function check_continuity_of_multi_linestring(multi_linestring)
    # A little bit of checking that the geometry is right
    # Check C0 continuity
    previousend = (0.0, 0.0, 0.0)
    for (i, ls) in enumerate(multi_linestring)
        thisstart = ls[1]
        thisend = ls[end]
        if i > 1 
            if distance_between(thisstart, previousend) > 0.1
                msg = "Not matching start point $thisstart and previous end $previousend \n"
                msg *= "Check failed for segment i = $i\n"
                msg *= "The distance between is  $(distance_between(thisstart, previousend))\n"
                msg *= "For checking with other tools: $(link_split_key(thisstart, thisend)) \n"
                println()
                @show multi_linestring
                throw(AssertionError(msg))
            end
        end
        previousend = thisend
    end
end



# The below 'urlstrings' and 'build_query_strings' may be useful for general web APIs
# when using Julia keywords. The keywords are defined as "" in general, and
# will be excluded in the web API call.
"""
    urlstring

Encodes the arguments as expected in a query string.

Type info is seldom necessary, because the type of arguments
is given by the API endpoint.

Empty argument values => the argument name is considered redundant.
"""
function urlstring(;kwds...)
    isempty(kwds) && return ""
    urlstring(kwds)
end
function urlstring(kwds::Base.Pairs)
    iter = collect(kwds)
    parts = ["$(urlstring(k))=$(urlstring(v))" for (k,v) in iter if v !== "" && v !== 0 && v !== -1]
    join(parts, "&")
end

function urlstring(d::Dict)
    parts = ["$(urlstring(k))=$(urlstring(v))" for (k,v) in d if v !== "" && v !== 0 && v !== -1]
    s = join(parts, "&")
end
function urlstring(v::Vector)
    vs = urlstring.(v)
    join(vs, "%2C")
end
function urlstring(d::DateTime)
    string(d)[1:19] # Whole seconds
end
function urlstring(s)
    "$s"
end


"""
    build_query_string(xs::Vararg{String,N}) where {N}

Includes separators if needed, for urlstrings.
"""
function build_query_string(xs::Vararg{String,N}) where {N}
    sf = first(xs)
    if sf == ""
        throw("The first argument can not be an empty string")
    end
    others = filter( s -> s!== "", xs[2:end])
    if length(others) == 0
        return first(xs)
    end
    if sf[end] == '/' || sf[end] == '='
        sf * join(others, "&")
    else
        first(xs) * "?" * join(others, "&")
    end
end

"""
    extract_from_to_meter(ref::String)
    ---> Tuple{Int, Int}

# Example
```
julia> extract_from_to_meter("1517 FV61 S3D1 m86 KD1 m9-13")
(9, 13)

julia> extract_from_to_meter("1517 FV61 S3D1 m86-143")
(86, 143)

julia> extract_from_to_meter("FV61 S3D1 m86-143")
(86, 143)
```
"""
function extract_from_to_meter(ref::String)
    from_to = split(ref, ' ')[end]
    @assert startswith(from_to, 'm') ref
    Tuple(tryparse.(Int, split(from_to[2:end], '-')))
end

"""
    extract_at_meter(ref::String)
    ---> Float64 (can be Not a Number)

# Example
```
julia> extract_at_meter("1517 FV61 S3D1 m86 KD1 m9-13")
86.0

julia> extract_at_meter("1517 FV61 S3D1 m86-143")
NaN```
"""
function extract_at_meter(ref::String)
    if ! isnumeric(ref[1])
        throw(ArgumentError("Vegsystemreferanse not prefixed with kommune no.: $ref"))
    end
    s = split(ref, ' ')[4]
    @assert s[1] == 'm'
    val = tryparse(Float64, String(s[2:end]))
    if isnothing(val)
        NaN
    else
        val
    end
end


"""
    extract_sideanleggsdel(ref::String)
    ---> Float64 (can be Not a Number)

# Example
```
julia> extract_sideanleggsdel("1516 FV61 S4D1 m5398 SD2 m85-104")
2.0

```
"""
function extract_sideanleggsdel(ref::String)
    if ! isnumeric(ref[1])
        throw(ArgumentError("Vegsystemreferanse not prefixed with kommune no.: $ref"))
    end
    sp = split(ref, ' ')
    if length(sp) < 5
        return NaN
    end
    s = sp[5]
    @assert length(s) >= 3 ref
    @assert s[1:2] == "SD"
    val = tryparse(Float64, String(s[3:end]))
    if isnothing(val)
        NaN
    else
        val
    end
end



"""
    extract_strekning_delstrekning(ref::String)
    ---> String

# Example
```
julia> extract_strekning_delstrekning("1517 FV61 S3D1 m86 KD1 m9-13")
S3D1

julia> extract_sideanleggsdel("1517 FV61 S3D1 m86-143")
NaN
```
"""
function extract_strekning_delstrekning(ref::String)
    if ! isnumeric(ref[1])
        throw(ArgumentError("Vegsystemreferanse not prefixed with kommune no.: $ref"))
    end
    s = split(ref, ' ')[3]
    @assert ! isnumeric(s[1]) ref
    String(s)
end

"""
    extract_kategori_fase_nummer("1517 FV61 S3D1 m86 KD1 m9-13")
    ---> String

# Example
```
julia> extract_kategori_fase_nummer("1517 FV61 S3D1 m86 KD1 m9-13")
FV61
```
"""
function extract_kategori_fase_nummer(ref::String)
    if ! isnumeric(ref[1])
        throw(ArgumentError("Vegsystemreferanse not prefixed with kommune no.: $ref"))
    end
    s = split(ref, ' ')[2]
    @assert ! isnumeric(s[1]) ref
    String(s)
end



"""
    correct_to_increasing_distance(ref::String)

Some requests to post_beta_vegnett_rute return invalid 
vegsystemreferanse. The highest meter value comes first.

This corrects the error by swapping the last two numbers.
"""
function correct_to_increasing_distance(ref::String)
    tup = extract_from_to_meter(ref)
    if length(tup) < 2
        return ref
    end
    ref_from, ref_to = tup
    if ref_from <= ref_to 
        return ref
    else
        v = split(ref, ' ')
        to = Int(round(ref_from))
        from = Int(round(ref_to))
        return join(v[1:(end - 1)], ' ') * " m$from-$to"
    end
end

"""
    is_segment_relevant(ref, vegsegment::JSON3.Object)

Some requests to vegdatabase return segments fully outside
the specified vegsystemreferanse limits. 

This is a way to filter out such results.

NOTE: This is not fully developed with regards to 'sideanlegg'. 
Examine e.g. "1515 FV5876 S1D1 m82 SD1 m29-36".
"""
function is_segment_relevant(ref, vegsegment::JSON3.Object)
    ref_from, ref_to = extract_from_to_meter(ref)
    ref_strekning_delstrekning = extract_strekning_delstrekning(ref)
    ref_kfv = extract_kategori_fase_nummer(ref)
    if ! hasproperty(vegsegment, :vegsystemreferanse)
        throw(ArgumentError("Can't check if vegsegment without vegsystemreferanse is contained in $ref"))
    end
    vsr = vegsegment.vegsystemreferanse
    if ! hasproperty(vsr, :strekning)
        throw(ArgumentError("Can't check if vegsystemreferanse without strekning is contained in $ref"))
    end
    stre = vsr.strekning
    if ! hasproperty(stre, :delstrekning)
        throw(ArgumentError("Can't check if strekning without delstrekning is contained in $ref"))
    end
    if ! hasproperty(stre, :strekning)
        throw(ArgumentError("Can't check if strekning without property strekning is contained in $ref"))
    end
    if ! hasproperty(vsr, :vegsystem)
        throw(ArgumentError("Can't check if vegsystemreferanse without vegsystem is contained in $ref"))
    end
    syst = vsr.vegsystem
    if ! hasproperty(syst, :vegkategori) || ! hasproperty(syst, :fase) || ! hasproperty(syst, :nummer)
        throw(ArgumentError("Can't check if vegsystem without vegkategori, fase or nummer is contained in $ref"))
    end
    strekning_delstrekning = "S$(stre.strekning)D$(stre.delstrekning)"
    if ref_strekning_delstrekning !== strekning_delstrekning
        return false
    end
    kfv = syst.vegkategori * syst.fase * "$(syst.nummer)"
    if ref_kfv !== kfv
        return false
    end
    if hasproperty(stre, :fra_meter) && hasproperty(stre, :til_meter)
        if stre.fra_meter <= ref_to
            if stre.til_meter >= ref_from
                if stre.til_meter - ref_from >= 1
                    if ref_to - stre.fra_meter >= 1
                        return true
                    end
                end
            end
        end
    else
        if ! hasproperty(stre, :meter)
            throw(ArgumentError("Can't check if strekning without properties 'meter', 'fra_meter' or 'til_meter' is contained in $ref"))
        end
        at_meter = extract_at_meter(ref)
        if ! isnan(at_meter)
            if round(stre.meter) == at_meter
                if hasproperty(vsr, :kryssystem)
                    rstre = vsr.kryssystem
                elseif hasproperty(vsr, :sideanlegg)
                    rstre = vsr.sideanlegg
                    if hasproperty(rstre, :sideanleggsdel)
                        sd = rstre.sideanleggsdel
                        ref_sd = Int(extract_sideanleggsdel(ref))
                        if sd !== ref_sd
                            return false
                        end
                    end
                else
                    throw(ArgumentError("Can't check if vegsystemreferanse without properties 'kryssystem' or 'sideanlegg' is contained in $ref"))
                end
                if rstre.fra_meter <= ref_to
                    if rstre.til_meter >= ref_from
                        if rstre.til_meter - ref_from >= 1
                            if ref_to - rstre.fra_meter >= 1
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    false
end 


"""
    is_rpoint_in_ref(rpoint::String, ref::String)

# Example
```
julia> is_rpoint_in_ref("1515 PV3080 S1D1 m56", "1515 PV3080 S1D1 m20-84")
true
```
"""
function is_rpoint_in_ref(rpoint::String, ref::String)
    if extract_kategori_fase_nummer(ref) ==  extract_kategori_fase_nummer( rpoint)
        if extract_strekning_delstrekning(ref) ==  extract_strekning_delstrekning(rpoint)
            enveloping = extract_from_to_meter(ref)
            point = extract_from_to_meter(rpoint)
            @assert length(point) == 1
            if enveloping[1] <= point[1]
                if enveloping[2] >= point[1]
                    return true
                end
            end
        end
    end
    false
end


"""
    speed_nested_in_intervals(fart_tuples, mls)

Applies an (interpolated) fartsgrense at each point in the
nested vector of 3d-points, 'mls', based on 'fart_tuples'.
"""
function speed_nested_in_intervals(fart_tuples, mls)
    v = Vector{Vector{Float64}}()
    @assert length(fart_tuples) == length(mls)
    prev_tupl = fart_tuples[1]
    tupl = fart_tuples[1]
    i = 1
    while i <= length(mls)
        if ! isnan(fart_tuples[i][1])
            tupl = fart_tuples[i]
        else
            tupl = prev_tupl
        end
        ml = mls[i]
        push!(v, speed_in_intervals(tupl, ml))
        i += 1
        prev_tupl = tupl
    end
    v
end 

"""
    speed_in_intervals(tupl, ml)

Applies an (interpolated) fartsgrense for each interval
between points in `ml`, based on `tupl`.

Hence, if `ml` has N points, this returns N-1 speed limits.
"""
function speed_in_intervals(tupl, ml)
    @assert ! isnan(tupl[1])
    # This is where the split happens (in 0..1)
    c = tupl[1]
    # This is the initial fartsgrense
    v_start = tupl[2]
    # This is the fartsgrense we change to
    v_end = tupl[3]
    # Unitless 1-dim positions along multi_linestring:
    s_ul_at_start_of_interval, s_ul_at_end_of_interval = unitless_interval_progression_pairs(ml)
    map(zip(s_ul_at_start_of_interval, s_ul_at_end_of_interval)) do (xs, xe)
        if xe <= c
            Float64(v_start)
        elseif xe > c && xs < c
            frac = (c - xs) / (xe -xs)
            v_start * frac + v_end * (1 - frac)
        else
            Float64(v_end)
        end
    end
end


"""
    modify_fartsgrense_with_speedbumps!(speed_limitations::Vector{Vector{Float64}}, prefixed_refs, mls)

Instead of making a request for pretty rare speedbumps
per small stretch of road, we make one for the kommune and ignore
irrelevant speedbumps.

This modifies speed-limitations in-place by reducing by 15 km/h 
at the location of a speed bump.

Some speedbumps contain detailed info,
but some don't. We will treat all the same.

The reduction is according to section 3.11 in 

'https://www.vegvesen.no/globalassets/fag/handboker/hb-v128-fartsdempende-tiltak.pdf'

for heavy vehicles.
"""
function modify_fartsgrense_with_speedbumps!(speed_limitations::Vector{Vector{Float64}}, prefixed_refs, mls)
    n = length(speed_limitations)
    @assert n == length(prefixed_refs)
    # Find which kommune nos are present if prefixed_refs.
    all_nos = map(prefixed_refs) do r
        split(r, ' ')[1]
    end
    nos = unique(all_nos)
    kommune = join(nos, ',')
    # Some speedbumps contain detailed info,
    # but some don't. We will treat all the same.
    vegobjekttype_id = 103 
    o = get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, ""; kommune, inkluder = "vegsegmenter")
    all_bumps =  extract_prefixed_vegsystemreferanse(o)
    for (i, enveloping_ref) in enumerate(prefixed_refs)
        relevant_bumps = filter(b -> is_rpoint_in_ref(b, enveloping_ref), all_bumps)
        if length(relevant_bumps) > 0
            println("\tFound bumps $relevant_bumps contained by $enveloping_ref")
            for bump in relevant_bumps
                bump_at_meter = extract_from_to_meter(bump)[1]
                ref_start_at_meter = extract_from_to_meter(enveloping_ref)[1]
                ml = mls[i]
                s_at_start_of_interval, _ = interval_progression_pairs(ml)
                for (j, s) in enumerate(s_at_start_of_interval)
                    if s + ref_start_at_meter >= bump_at_meter
                        # Reduce the speed limit at this one point, where
                        # the bump is.
                        speed_limitations[i][j] -= 15
                        break # exit loop placing this bump
                    end
                end
            end
        end
    end
    speed_limitations
end




