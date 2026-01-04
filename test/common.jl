using Test
using RouteSlopeDistance
#using RouteSlopeDistance: patched_post_beta_vegnett_rute, coordinate_key, get_config_value
#using RouteSlopeDistance: corrected_coordinates, link_split_key
#using RouteSlopeDistance: extract_length, extract_multi_linestrings, extract_prefixed_vegsystemreferanse
#using RouteSlopeDistance: reverse_linestrings_where_needed!
#using RouteSlopeDistance: Quilt, amend_fromtos!
#using RouteSlopeDistance: build_fromtos!, correct_coordinates!, build_patches!
using Plots

!@isdefined(M) && begin

const M = ["Hareid bussterminal" 36976 6947659; "Hareid ungdomsskule fv. 61" 36533 6947582; "Holstad" 35983 6947673; "Grimstad aust" 35465 6947468; "Grimstad vest" 34866 6947308; "Bjåstad aust" 34418 6947105; "Bjåstad vest" 34054 6946887; "Bigsetkrysset" 33729 6946682; "Byggeli" 33142 6946489; "Nybøen" 32852 6946449; "Korshaug" 32344 6946360; "Rise aust" 31909 6946301; "Rise" 31515 6946166; "Rise vest" 31167 6946060; "Varleitekrysset" 29426 6945335; "Ulstein vgs." 28961 6945248; "Støylesvingen" 28275 6945289; "Holsekerdalen" 27714 6945607; "Ulsteinvik skysstasjon" 27262 6945774; "Saunes nord" 27457 6945077; "Saunes sør" 27557 6944744; "Strandabøen" 27811 6944172; "Dimnakrysset" 27721 6943086; "Botnen" 26807 6941534; "Garneskrysset" 26449 6940130; "Dragsund sør" 24823 6939041; 
"Myrvåglomma" 23911 6938921; "Myrvåg" 23412 6939348; "Aurvåg" 22732 6939786; "Aspevika" 22119 6939611; "Kalveneset" 21508 6939662; "Tjørvåg indre" 20671 6939661; "Tjørvåg" 20296 6939961; "Tjørvågane" 20222 6940344; "Tjørvåg nord" 20408 6940732; "Rafteset" 20794 6941312; "Storneset" 20779 6941912; "Stokksund" 20353 6942412; "Notøy" 19429 6943497; "Røyra øst" 19922 6944583; "Røyra vest" 19605 6944608; "Frøystadvåg" 19495 6945400; "Frøystadkrysset" 19646 6945703; "Nerøykrysset" 18739 6946249; "Berge bedehus" 17919 6946489; "Elsebøvegen" 17680 6946358; "Verket" 17441 6946183; "Berge" 17255 6946053; "Hjelmeset" 16949 6945880; "Demingane" 16575 6945717; "Eggesbønes" 16078 6945699; "Myklebust" 16016 6945895; "Herøy kyrkje" 16156 6946651; "Fosnavåg sparebank" 16235 6947271; "Fosnavåg terminal" 16064 6947515]

function plot_inspect_continuity!(pl::Plots.Plot{Plots.GRBackend}, mls; continuous = false, kws...)
    vx = Float64[]
    vy = Float64[]
    vz = Float64[]
    for a in mls
        for tup in a
            x, y, z = tup
            push!(vx, x)
            push!(vy, y)
            push!(vz, z)
            if ! continuous
                # Ensure no lines drawn to the following point
                if tup == a[end]
                    push!(vx, NaN)
                    push!(vy, NaN)
                    push!(vz, NaN)
                end
            else
                # For alignment with non-continuous...
                if tup == a[end]
                    push!(vx, x)
                    push!(vy, y)
                    push!(vz, z)
                end
            end
        end
    end
    plot!(pl[1], 1:length(vx), vx, marker = :cross, label = "vx"; kws...)
    plot!(pl[2], 1:length(vy), vy,  label = "vy", marker = :circle; kws...)
    plot!(pl[3], 1:length(vz), vz,  label = "vz", marker = :square; kws...)
    plot!(pl[4], vx, vy,  label = "y-x"; kws...)
    plot!(pl[5], vx, vz,  label = "z-x"; kws...)
    plot!(pl[6], vy, vz,  label = "z-y"; kws...)
    pl
end


function plot_inspect_continuity(mls; order = nothing, reversed = nothing)
    pl = plot( size = (1200, 1000); layout = 6)
    plot_inspect_continuity!(pl, mls)
    if ! isnothing(order) 
        @assert length(order) == length(mls)
        if isnothing(reversed)
            # Also plot the ordered (permuted, sorted) version
            plot_inspect_continuity!(pl, mls[order]; continuous = true, marker =:none)
        else
            @assert length(reversed) == length(mls)
            ordered = mls[order]
            ord_and_rev = map(zip(ordered, reversed)) do (v, rev)
                rev ? reverse(v) : v
            end
            plot_inspect_continuity!(pl, ord_and_rev; continuous = true, marker =:none, label = "ordered")
        end
    end
    # Scale both axes equal for the y-x plot
    Δ =  max(abs(-(ylims(pl[4])...)), abs(-(xlims(pl[4])...))) 
    xcen = +(xlims(pl[4])...) / 2
    ycen = +(ylims(pl[4])...) / 2
    xlims!(pl[4], (xcen - Δ / 2, xcen + Δ / 2))
    ylims!(pl[4], (ycen - Δ / 2, ycen + Δ / 2))
    #
    pl
end

end # @isdefined

nothing