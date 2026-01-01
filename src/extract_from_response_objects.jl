# Extract things we need from json3 objects we get from the API.
"""
    extract_prefixed_vegsystemreferanse(o, ea1, no1, ea2, no2)
    --> Vector{String}

Call this before extracting other route data,
since this replaces references with an extended 
error message.
"""
function extract_prefixed_vegsystemreferanse(o, ea1, no1, ea2, no2)
    @assert !isempty(o)
    # Extract just what we want. There may be much more.
    if iszero(o.metadata.antall)
        if o.metadata.status == 4040 
            msg = "Error: $(o.metadata.status)  $(o.metadata.status_tekst) \n"
            msg *= "\t$(coordinate_key(false, ea1, no1)):\n\t\t"
            msg *=  get_posisjon(ea1, no1)
            msg *= "\n\t"
            msg *= "$(coordinate_key(true, ea2, no2)):\n\t\t"
            msg *= get_posisjon(ea2, no2)
            msg *= "\n\t"
            msg *= "$(link_split_key(ea1, no1, ea2, no2))     (for .ini file)"
            msg *= "\n\t"
            msg *= " $ea1,$no1   $ea2,$no2    (for https://nvdb-vegdata.github.io/nvdb-visrute/ATM/ ) \n\t\t"
            return [msg]
        elseif o.metadata.status == 4041
            msg = "Error: $(o.metadata.status)  $(o.metadata.status_tekst) \n"
            msg *= "$(coordinate_key(false, ea1, no1)):\n\t"
            msg *=  get_posisjon(ea1, no1)
            return [msg]
        elseif o.metadata.status == 4042
            msg = "Error: $(o.metadata.status)  $(o.metadata.status_tekst) \n"
            msg *= "\n\t"
            msg *= "$(coordinate_key(true, ea2, no2)):\n\t"
            msg *= get_posisjon(ea2, no2)
            return [msg]
        else
            throw("unknown error code")
        end
    end
    map(o.vegnettsrutesegmenter) do s
        r = s.vegsystemreferanse
        @assert r.vegsystem.fase == "V" # Existing. If not, improve the query.
        sref = r.kortform
        scorr = correct_to_increasing_distance(sref)
        k = s.kommune
        "$k $scorr"
    end
end
function extract_prefixed_vegsystemreferanse(q::Quilt)
    refs = String[]
    for (o, fromto) in zip(q.patches, q.fromtos)
        append!(refs, extract_prefixed_vegsystemreferanse(o, fromto...))
    end
    refs
end

"""
    extract_prefixed_vegsystemreferanse(o)

Works on objects like retrieved with
o = get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, ""; kommune = "1515,1516", inkluder = "vegsegmenter")
"""
function extract_prefixed_vegsystemreferanse(o)
    map(o.objekter) do obj
        @assert hasproperty(obj, :vegsegmenter)
        @assert length(obj.vegsegmenter) == 1
        vegsegment = obj.vegsegmenter[1]
        @assert hasproperty(vegsegment, :vegsystemreferanse)
        r = vegsegment.vegsystemreferanse
        @assert hasproperty(r, :vegsystem)
        @assert r.vegsystem.fase == "V" # Existing. If not, improve the query.
        @assert hasproperty(r, :kortform)
        sref = r.kortform
        k = vegsegment.kommune
        "$k $sref"
    end
end






"""
    extract_length(o)
    extract_length(q::Quilt)
    --> Vector{Float64}

Length of each segments from dabase. Sum is checked against metadata. 

# Example
```
julia> o
JSON3.Object{Base.CodeUnits{UInt8, String}, Vector{UInt64}} with 2 entries:
  :vegnettsrutesegmenter => Object[{…
  :metadata              => {…

julia> println(extract_length(o))
[13.654, 7.517, 9.066, 12.945, 154.225, 95.455, 80.824, 34.79, 74.79, 9.331, 24.277, 96.441, 24.006]

julia> println(refs)
["1517 FV61 S3D1 m3533-3547", "1517 FV61 S3D1 m3547-3555", "1517 FV61 S3D1 m3555-3564", "1517 FV61 S3D1 m3564-3577", "1517 FV61 S3D1 m3577-3731", "1517 FV61 S3D1 m3731-3826", "1517 FV61 S3D1 m3826-3907", "1517 FV61 S3D1 m3907-3942", "1517 FV61 S3D1 m3942-4017", "1517 FV61 S3D1 m4017-4026", "1517 FV61 S3D1 m4026-4050", "1517 FV61 S3D1 m4050-4147", "1517 FV61 S3D1 m4147-4171"]
```
"""
function extract_length(o)
    @assert hasproperty(o, :vegnettsrutesegmenter)
    if o.metadata.antall == 0
        return [NaN]
    end
    Δl = map(o.vegnettsrutesegmenter) do s
        s.lengde
    end
    total = Float64(o.metadata.lengde)
    su = sum(Δl)
    @assert isapprox(su, total, atol = 0.1) "su =$su ≈ total = $total"
    Δl
end
function extract_length(q::Quilt)
    Δl = Float64[]
    for o in q.patches
        append!(Δl, extract_length(o))
    end
    Δl
end

"""
    extract_multi_linestrings(o, ea, no)
    --> Vector{Vector{Tuple{Float64, Float64, Float64}}}, Vector{Bool}

The starting point coordinates are given as input, so that
we can reverse the linestrings returned from API where needed.

The second returned vector indicates if a segment was reversed or not.
Reversion might be applicable to related data.

Each vector contains a linestring.
Start and end points of each coincide.
"""
function extract_multi_linestrings(o, ea, no)
    multi_linestring = map(o.vegnettsrutesegmenter) do s
        # Api v3 -> v4: An additional space starting the linestring.
        ls = map(split(s.geometri.wkt[15:end-1], ',')) do v
            NTuple{3, Float64}(tryparse.(Float64, split(strip(v), ' ')))
        end
    end
    @assert ! isempty(multi_linestring)
    # Flip the order of points if necessary for continuity. 
    reversed = reverse_linestrings_where_needed!(multi_linestring, ea, no)
    @assert ! isempty(multi_linestring)
    check_continuity_of_multi_linestring(multi_linestring)
    @assert ! isempty(multi_linestring)
    multi_linestring, reversed
end
function extract_multi_linestrings(q::Quilt)
    mls = Vector{Vector{Tuple{Float64, Float64, Float64}}}()
    reversed = Vector{Bool}()
    for (o, fromto) in zip(q.patches, q.fromtos)
        ea1, no1, _, __ = fromto
        patchml, rev = extract_multi_linestrings(o, ea1, no1)
        append!(mls, patchml)
        append!(reversed, rev)
    end
    mls, reversed
end

"""
    extract_split_fartsgrense(o, ref, is_reversed)
    --> () fractional_distance_of_ref, fartsgrense_start, fartsgrense_end

Returns (NaN, 0, 0) when no interpretation is found.
    
Called with `o` from request made within `fartsgrense_from_prefixed_vegsystemreferanse`

ref is prefixed vegsystemreferanse for the request.

`is_reversed` is true if the output is to be applied to a reversed linestring. See calling context.
"""
function extract_split_fartsgrense(o, ref, is_reversed)
    ref_from, ref_to = extract_from_to_meter(ref)
    @assert hasproperty(o, :metadata) ref
    @assert hasproperty(o, :objekter) ref
    # v3: antall v4: returnert
    @assert o.metadata.returnert == length(o.objekter) ref
    indices = collect(1:o.metadata.returnert)
    # Keep top-level indices which has relevant segments
    relevant_indices = filter(indices) do i
        objekt = o.objekter[i]
        @assert hasproperty(objekt, :vegsegmenter) ref
        vegsegmenter = objekt.vegsegmenter
        relevant_segments = filter(vegsegmenter) do s
            is_segment_relevant(ref, s)
        end
        length(relevant_segments) > 0
    end
    objekter = o.objekter[relevant_indices]
    fartsgrense_objekter = map(objekter) do ob
        es = filter(ob.egenskaper) do e
            @assert hasproperty(e, :navn)
            e.navn == "Fartsgrense"
        end
        @assert length(es) == 1
        es[1]
    end
    fartsgrenser = map(fartsgrense_objekter) do fa
        @assert hasproperty(fa, :enhet)
        enhet = fa.enhet
        @assert hasproperty(enhet, :kortnavn)
        @assert enhet.kortnavn == "km/h"
        fa.verdi
    end
    strekninger = map(objekter) do ob
        @assert hasproperty(ob, :vegsegmenter) ref
        vegsegmenter = filter(ob.vegsegmenter) do s
            is_segment_relevant(ref, s)
        end
        if length(vegsegmenter) !== 1 
            @warn "Expected just one vegsegmenter in object $ref, got $(length(vegsegmenter))"
            @warn "     Maybe is_segment_relevant(ref, s) is too liberal?"
            for s in vegsegmenter
                @warn "    Is this actually relevant?" s
                is_segment_relevant(ref, s)
            end
        end
        @assert hasproperty(vegsegmenter[1], :vegsystemreferanse) ref
        vsr = vegsegmenter[1].vegsystemreferanse
        @assert hasproperty(vsr, :strekning) ref
        if hasproperty(vsr.strekning, :fra_meter)
            vsr.strekning
        elseif hasproperty(vsr, :kryssystem)
            vsr.kryssystem
        elseif hasproperty(vsr, :sideanlegg)
            vsr.sideanlegg
        else
            throw("unknown error, we should have filtered out this. $ref")
        end
    end
    fra_meters = map(strekninger) do s
        @assert hasproperty(s, :fra_meter) 
        s.fra_meter
    end
    til_meters = map(strekninger) do s
        @assert hasproperty(s, :til_meter) 
        s.til_meter
    end
    permutation = sortperm(fra_meters)
    fra_m_s = fra_meters[permutation]
    til_m_s = til_meters[permutation] # Could be used for double checking continuity
    fartsgrenser_s = fartsgrenser[permutation]
    _extract_split_fartsgrense(fra_m_s, til_m_s, fartsgrenser_s, ref_to, ref_from, is_reversed)
end
function _extract_split_fartsgrense(fra_m_s, til_m_s, fartsgrenser_s, ref_to, ref_from, is_reversed)
    if length(fartsgrenser_s) == 0
        return (NaN, 0, 0)
    elseif length(fartsgrenser_s) == 1 || length(unique(fartsgrenser_s)) == 1
        return 1.0, fartsgrenser_s[1], fartsgrenser_s[1]
    elseif length(fartsgrenser_s) == 2
        if fartsgrenser_s[1] == fartsgrenser_s[2]
            return 1.0, fartsgrenser_s[1], fartsgrenser_s[1]
        else
            if is_reversed
                split_after_ref_from = til_m_s[1] - ref_from
                fractional_distance_of_ref = 1 - split_after_ref_from / (ref_to - ref_from)
                return fractional_distance_of_ref, fartsgrenser_s[2], fartsgrenser_s[1]
            else
                split_after_ref_from = til_m_s[1] - ref_from
                fractional_distance_of_ref = split_after_ref_from / (ref_to - ref_from)
                return fractional_distance_of_ref, fartsgrenser_s[1], fartsgrenser_s[2]
            end
        end
    elseif length(fartsgrenser_s) == 3
        if fartsgrenser_s[1] == fartsgrenser_s[2] ||
            fartsgrenser_s[2] == fartsgrenser_s[3] ||
            fartsgrenser_s[1] == fartsgrenser_s[3]
            #
            # Two of three are equal, which we deal with below.
        else
            # We currently have three different values.
            # We can't handle that generally, so compromise!
            #
            # E.g. fartsgrenser = [60, 80, 40], where 60 and 80 are partly overlapping.
            # This could be a transitional zone, roughly 160 meters of overlapping
            # in one direction. Be careful!
            if fartsgrenser_s == [60, 80, 40]
                # For our purpose, lower is conservative.
                fartsgrenser_s[2] = 60
            else
                throw("This is quite rare, perhaps overlapping transitional zone. $fartsgrenser_s  $ref_from $ref_to")
            end
        end
        if fartsgrenser_s[1] == fartsgrenser_s[2]
            if is_reversed
                split_after_ref_from = til_m_s[2] - ref_from
                fractional_distance_of_ref = 1 - split_after_ref_from / (ref_to - ref_from)
                return fractional_distance_of_ref, fartsgrenser_s[2], fartsgrenser_s[1]
            else
                split_after_ref_from = til_m_s[2]- ref_from
                fractional_distance_of_ref = split_after_ref_from / (ref_to - ref_from)
                return fractional_distance_of_ref, fartsgrenser_s[1], fartsgrenser_s[3]
            end
        else
            if is_reversed
                split_after_ref_from = til_m_s[1] - ref_from
                fractional_distance_of_ref = 1 -split_after_ref_from / (ref_to - ref_from)
                return fractional_distance_of_ref, fartsgrenser_s[2], fartsgrenser_s[1]
            else
                split_after_ref_from = til_m_s[1] - ref_from
                fractional_distance_of_ref = split_after_ref_from / (ref_to - ref_from)
                return fractional_distance_of_ref, fartsgrenser_s[1], fartsgrenser_s[2]
            end
        end
    else
        throw("Unexpected length(fartsgrenser_s) = $(length(fartsgrenser_s)). fartsgrenser_s = $fartsgrenser_s \n\tref_from, ref_to = $ref_from , $ref_to")
    end
end


