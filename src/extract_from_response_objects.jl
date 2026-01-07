# Extract things we need from json3 objects we get from the API.

#
# Internal functions which don't change order of route segments.
#

function parse_multilinestring_values_and_structure(wkt::String)
    @assert startswith(wkt, "LINESTRING Z (")
    sco = wkt[15:end-1]
    map(split(sco, ',')) do v
        NTuple{3, Float64}(tryparse.(Float64, split(strip(v), ' ')))
    end
end
function parse_multilinestring_values_and_structure(o::JSON3.Object)
    @assert o.type == "Rute"
    @assert ! isempty(o.vegnettsrutesegmenter) # Consider returning an empty thing
    @assert hasproperty(o, :vegnettsrutesegmenter)
    # This adds another nesting level.
    map(o.vegnettsrutesegmenter) do oseg
        parse_multilinestring_values_and_structure(oseg.geometri.wkt)
    end
end
function parse_multilinestring_values_and_structure(q::Quilt)
    deepnested = parse_multilinestring_values_and_structure.(q.patches)
    # We don't want to another nesting level. That's because the Quilt type
    # is just a way to find the correct route, we simply use it to 
    # insert intermediate waypoints.
    T =  Vector{Vector{Tuple{Float64, Float64, Float64}}}
    @assert first(deepnested) isa T
    nv = T()
    for i in eachindex(deepnested)
        append!(nv, deepnested[i])
    end
    nv
end


"""
    extract_prefixed_vegsystemreferanse(q::Quilt; tol = 1.0)
    extract_prefixed_vegsystemreferanse(o, ea1, no1, ea2, no2; tol = 1.0)
    --> Vector{String}, Vector{Bool}
    --> refs, reversed

This function provides more feedback on errors, for ease of making [link split]
and [coordinates replacement] entries in the .ini file.

Output is ordered from `(ea1, no1)`. For an explanation, see `extract_multi_linestrings`.

# Arguments

- `q` contains the other arguments. 


# Example output

["1516 KV1123 S1D1 m504-531",  "1516 KV1123 S1D1 m478-504"], [true, true]


"""
function extract_prefixed_vegsystemreferanse(o, ea1, no1, ea2, no2; tol = 1.0)
    @assert !isempty(o)
    @assert o.type == "Rute"
    # Extract just what we want. There may be much more.
    if isempty(o.vegnettsrutesegmenter)
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
    # In API v4, we don't trust the returned order at all.
    mls = parse_multilinestring_values_and_structure(o)
    # Consider TODO: Detect if the API returns mls consistent with
    # direction of naming...
    # order: Necessary permutations to unordered 'mls'.
    # rev: Necessary flipping of unordered mls segments.
    order, reversed_unordered_indexing = segments_sortorder_and_reversed(mls, ea1, no1; tol)
    vref = map(eachindex(o.vegnettsrutesegmenter)) do i
        ordered_index = order[i]
        s = o.vegnettsrutesegmenter[ordered_index]
        r = s.vegsystemreferanse
        @assert r.vegsystem.fase == "V" # Existing. If not, improve the query.
        sref = r.kortform
        scorr = correct_to_increasing_distance(sref)
        k = s.kommune
        "$k $scorr"
    end
    # Which segments (in the wanted order) were flipped.
    # The info is needed to identify locations that are given
    # in the original internal coordinates of a segment, like
    # speed bumps and signs. 
    reversed = reversed_unordered_indexing[order]
    vref, reversed
end
function extract_prefixed_vegsystemreferanse(q::Quilt; tol = 1.0)
    refs = String[]
    reversed = Bool[]
    for (o, fromto) in zip(q.patches, q.fromtos)
        @assert hasproperty(o, :type)
        @assert o.type =="Rute"
        vref, vrev = extract_prefixed_vegsystemreferanse(o, fromto...; tol)
        append!(refs, vref)
        append!(reversed, vrev)
    end
    refs, reversed
end

"""
    extract_length(o, ea1, no1; tol = 1.0)
    extract_length(q::Quilt; tol = 1.0)
    --> Vector{Float64}

Length of each segment, ordered from position (ea1, no1). Sum is checked against metadata. 
"""
function extract_length(o, ea1, no1; tol = 1.0)
    @assert o.type == "Rute"
    @assert hasproperty(o, :vegnettsrutesegmenter)
    if isempty(o.vegnettsrutesegmenter)
        return [NaN]
    end
    order, _ = segments_sortorder_and_reversed(o, ea1, no1; tol)
    Δl = map(o.vegnettsrutesegmenter) do s
        s.lengde
    end
    total = Float64(o.metadata.lengde)
    su = sum(Δl)
    @assert isapprox(su, total, atol = 0.1) "su =$su ≈ total = $total"
    Δl[order]
end
function extract_length(q::Quilt; tol = 1.0)
    Δl = Float64[]
    for (o, fromto) in zip(q.patches, q.fromtos)
        @assert hasproperty(o, :type)
        @assert o.type == "Rute"
        ea1, no1 = fromto[1:2]
        append!(Δl, extract_length(o, ea1, no1; tol))
    end
    Δl
end


"""
    extract_multi_linestrings(q::Quilt; tol = 1.0)
    extract_multi_linestrings(o::JSON3.Object, ea, no; tol = 1.0)
    --> Vector{Vector{Tuple{Float64, Float64, Float64}}}, Vector{Bool}
    --> `(nv, reversed)`

"Wanted order" is defined by utm point '(ea, no)'. That point  has a distance to both physical 
ends of the unordered multi-linestring from API v4. The closer end indicates which should be first 
after reordering.

Output `nv` is ordered on both nesting levels, segments and points.

- 'reversed' indicates which segments (in the new segment order) were flipped for the wanted point order. 

Each resulting nested vector's start and end points coincide with its neighbors.
"""
function extract_multi_linestrings(o::JSON3.Object, ea, no; tol = 1.0)
    @assert o.type == "Rute"
    mls_unordered = parse_multilinestring_values_and_structure(o)
    @assert ! isempty(mls_unordered)
    # Find the permutations necessary for the wanted order
    # path starting at (ea, no)
    order, reversed_unordered_indexing = segments_sortorder_and_reversed(mls_unordered, ea, no; tol)
    # Flip the order of segments and points if necessary for continuity. 
    nv = map(zip(mls_unordered[order], reversed_unordered_indexing)) do (v, rev)
        rev ? reverse(v) : v
    end
    check_continuity_of_multi_linestring(nv)
    # Which segments (in the wanted order) were flipped.
    reversed = reversed_unordered_indexing[order]
    nv, reversed
end
function extract_multi_linestrings(q::Quilt; tol = 1.0)
    # The Quilt type is a way to find the correct route, 
    # by splitting a requested route.
    # We don't want to add another nesting level to the output,
    # we append results from such splits insted. 
    T =  Vector{Vector{Tuple{Float64, Float64, Float64}}}
    nv = T()
    reversed = Bool[]
    for (o, fromto) in zip(q.patches, q.fromtos)
        @assert hasproperty(o, :vegnettsrutesegmenter)
        @assert hasproperty(o, :type)
        @assert o.type == "Rute"
        ea1, no1, _, __ = fromto
        patchml, vrev = extract_multi_linestrings(o, ea1, no1; tol)
        append!(nv, patchml)
        append!(reversed, vrev)
    end
    nv, reversed
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



"""
    extract_prefixed_vegsystemreferanse(o)

Works on objects like retrieved with
o = get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, ""; kommune = "1515,1516", inkluder = "vegsegmenter")
"""
function extract_prefixed_vegsystemreferanse(o; tol = 1.0)
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