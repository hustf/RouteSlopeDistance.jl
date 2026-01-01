# Intermediate layer between 'endpoints' and 'exported'

"""
    fartsgrense_from_prefixed_vegsystemreferanse(ref, is_reversed)
    --> fractional_distance_of_ref::Float64, fartsgrense1::Int, fartsgrense2::Int

This interface won't work if ref has more than two speed limits.

`is_reversed` is true if the output is to be applied to a reversed linestring. See calling context.

# Example 1 

Constant speed limit

```
julia> fartsgrense_from_prefixed_vegsystemreferanse("1516 FV61 S5D1 m1085-1273", false)
(1.0, 60, 60)
```

# Example 2

Shifting speed limit

```
julia> fractional_distance_of_ref, fartsgrense1, fartsgrense = fartsgrense_from_prefixed_vegsystemreferanse("1515 FV61 S5D1 m1527-1589", false)
(0.1086935483870973, 60, 80)

julia> change_at_meter = 1527 + fractional_distance_of_ref * (1589-1527)
1533.739

julia> fractional_distance_of_ref, fartsgrense1, fartsgrense = fartsgrense_from_prefixed_vegsystemreferanse("1515 FV61 S5D1 m1527-1589", true)
(0.8913064516129027, 80, 60)
```


# Details

```
julia> catalogue["Fartsgrense"][:tilleggsinformasjon]
"Fartsgrense skal være heldekkende, det gjelder også ramper og rundkjøringer."

julia> catalogue["Fartsgrense"][:beskrivelse]
"Høyeste tillatte hastighet på en vegstrekning."
```
"""
function fartsgrense_from_prefixed_vegsystemreferanse(ref, is_reversed)
    ref_from, ref_to = extract_from_to_meter(ref)
    vegobjekttype_id = 105
    if ref_from == ref_to
        # Post-beta-vegnett rute returns references like FV61S3D30m1136-1136
        # But we can't make requests on this format. Instead, the 
        # callee should apply fartsgrense from neighouring segments.
        return (NaN, 0, 0)
    end
    @assert ref_from < ref_to ref # Callee must have failed to call correct_to_increasing_distance first.
    # v3: inkluder = "egenskaper,vegsegmenter"
    # v4: inkluder = ["egenskaper","vegsegmenter"]
    o = get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, ref; 
        inkluder = ["egenskaper","vegsegmenter"])
    extract_split_fartsgrense(o, ref, is_reversed)
end
