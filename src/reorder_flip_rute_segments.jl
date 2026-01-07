# Bottom up code

function is_connected(p::T, q::T, tol) where T<:Tuple{Float64, Float64}
    norm(p .- q) <= tol
end
function is_connected(p::Tuple{Float64, Float64}, vq::T, tol) where T<:Tuple{Tuple{Float64, Float64}, Tuple{Float64, Float64}}
    is_connected(p, vq[1], tol) || is_connected(p, vq[2], tol)
end



# We arbitrarly limit this to 2d.
function distance_combinations(twopoints::T, twootherpoints::T) where T<:Tuple{Tuple{Float64, Float64}, Tuple{Float64, Float64}}
    @assert length(twopoints) == 2
    @assert length(twootherpoints) == 2
    [norm(p .- q) for p in twopoints, q in twootherpoints]
end

function connected_ends(twopoints, twootherpoints)
    mat = distance_combinations(twopoints, twootherpoints)
    minimum(mat[:, 1]), minimum(mat[:, 2])
end





function complete_permute_vector!(permute_vector, adj)
    # This function could probably be used more generally, 
    # but for now we're checking that the context is as intended.
    @assert length(permute_vector) == 1 
    prev_segind = permute_vector[1]
    segind = first(adj[prev_segind])
    push!(permute_vector, segind)
    count = 0
    while true
        neighbors = adj[segind]
        @assert neighbors isa Vector{Int}
        if length(neighbors) == 2
            if first(neighbors) == prev_segind
                prev_segind = segind
                segind = last(neighbors)
            else
                prev_segind = segind
                segind = first(neighbors)
            end
            push!(permute_vector, segind)
        else
            break
        end
        count += 1
        if count > length(adj) 
            @show count adj permute_vector prev_segind segind
            throw(ArgumentError("adj incorrect"))
        end
    end
    permute_vector
end

function needs_reversing(endpoints_of_ordered_segments, tol)
    # We have two tuples or points for every element of nested vector nv:
    vn = endpoints_of_ordered_segments
    # 
    nseg = length(vn)
    # Start by assuming every segment is sorted ok.
    reversed = falses(nseg)
    # First segment
    if is_connected(vn[1][1], vn[2], tol)
        reversed[1] = true
    end
    # The rest
    for i in 2:nseg
        last_segment_reversed = reversed[i - 1]
        last_connection_index = last_segment_reversed ? 1 : 2
        last_point = vn[i-1][last_connection_index]
        this_first_point = vn[i][1]
        if ! is_connected(last_point, this_first_point, tol)
            reversed[i] = true
        end
    end
    reversed
end

"""
segments_sortorder_and_reversed(o::JSON3.Object, ea1, no1; tol = 1.0)
segments_sortorder_and_reversed(segments::Vector{Vector{Tuple{Float64,Float64,Float64}}}, 
    ea1, no1; tol = 1.0)
  --> Vector{Int}, Vector{Bool} 

Returns ('order', 'reversed').

`o` and `segments` contain unordered segments. Each segment is sorted, but may be flipped.

"Wanted order" is defined by Utm point '(ea1, no1)'. That point  has a distance to both ends of 'o' and 'segments'. 
The closer end indicates which should be first after reordering.

- 'order' is the permutations necessary to segments for the wanted order.
- 'reversed' indicates which segments (in the original order) needs to be reversed for the wanted point order. 
"""
function segments_sortorder_and_reversed(segments::Vector{Vector{Tuple{Float64,Float64,Float64}}}, ea1, no1;
                        tol = 1.0)
    n = length(segments)
    n == 0 && return Int[], Bool[]
    n == 1 && return Int[1], [false]
    #######################################
    # Identify which segments are connected
    #######################################
    # Extract (x,y) endpoints: Vector of (start, stop)
    endpoints = [(seg[1][1:2], seg[end][1:2]) for seg in segments]
    # Build adjacency list. We don't know in advance which segment is first and last,
    # but we'll identify the end segments in a multiple-segment route by
    # finding those with an adjaceny list of 1.
    adj = [Int[] for _ in 1:n]
    # Loop over upper right half of segment adjacency list.
    for i in 1:n, j in (i+1):n
        # Least distance between endpoints of these two segments
        min_d = minimum(distance_combinations(endpoints[i], endpoints[j]))
        if min_d <= tol
            # The list just contains the connections.
            # Just note that these two segments are connected.
            # If a segment has 
            push!(adj[i], j)
            push!(adj[j], i)
        end
    end
    ##############################################
    # Classify segments from number of connections
    ##############################################
    # The number of connections for each segment
    degrees = length.(adj)
    endsegments = findall(==(1), degrees)
    if length(endsegments) < 2
        throw(ErrorException("not a simple chain (no two degree-1 nodes)."))
    end
    junctionsegments = findall(>(2), degrees)
    if length(junctionsegments) > 0
        @warn "Found junctions in route. Hint: reduce `tol`" tol
        @show junctionsegments 
        @show endpoints[junctionsegments] 
    end
    ###############################
    # Identify the segment at start
    ###############################
    # ea1, no1 identifies which of the two ends should be first.
    @assert length(endsegments) == 2
    pt_firstend = endpoints[endsegments[1]][1]
    pt_secondend = endpoints[endsegments[2]][2]
    @assert pt_firstend isa Tuple{Float64, Float64}
    dist_firstend = norm(pt_firstend .- (ea1, no1))
    dist_secondend =  norm(pt_secondend  .- (ea1, no1))
    start_segment_no = dist_firstend < dist_secondend ? endsegments[1] : endsegments[2]
    #######################################################
    # Follow the connections to build a chain from segments
    #######################################################
    # The first element in permute_vector
    permute_vector = [start_segment_no]
    complete_permute_vector!(permute_vector, adj)
    ###############################################
    # Which segments in the permuted segments order
    # needs to be reversed
    ###############################################
    reversed = needs_reversing(endpoints[permute_vector], tol)
    @assert length(permute_vector) == length(reversed)
    permute_vector, reversed
end
function segments_sortorder_and_reversed(o::JSON3.Object, ea1, no1; tol = 1.0)
    mls = parse_multilinestring_values_and_structure(o)
    segments_sortorder_and_reversed(mls, ea1, no1; tol)
end