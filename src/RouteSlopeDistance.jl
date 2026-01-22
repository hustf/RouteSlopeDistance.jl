module RouteSlopeDistance
using HTTP, IniFile, JSON3, UUIDs, Dates
import BSplines
using BSplines: BSplineBasis, Spline, Derivative, Function
import Smoothers
using Smoothers: hma
using Serialization
import Interpolations
using Interpolations: extrapolate, interpolate, Gridded, Linear, Line, Cubic, OnGrid, BSpline, scale, gradient
import Printf
using Printf: Format
using Plots
import LinearAlgebra
using LinearAlgebra: norm
import Base
import Base.length
using PrecompileTools
export route_leg_data, delete_memoization_file, nvdb_request, unique_unnested_coordinates_of_multiline_string,
    plot_elevation_and_slope_vs_progression, plot_elevation_slope_speed_vs_progression,
    link_split_key, coordinate_key


"""
struct Quilt
    fromtos::Vector{Vector{Int64}}
    patches::Vector{JSON3.Object}
end

- `fromtos`: Splits a user from-to request, based on manual fixes stored in RouteSlopeDistance.ini
- `patches`: Unmodified web api returns. Same number of patches as in `fromtos`
"""
struct Quilt
    fromtos::Vector{Vector{Int64}}
    patches::Vector{JSON3.Object}
end
# We don't offer an external constructor with values, see `build_fromtos!`.
Quilt() = Quilt(Vector{Vector{Int64}}(), Vector{JSON3.Object}())
length(q::Quilt) = length(q.fromtos)

include("ini_file.jl")
include("nvdb_utils.jl")
include("request_nvdb.jl")
include("reorder_flip_rute_segments.jl")
include("extract_from_response_objects.jl")
include("endpoints.jl")
include("exported.jl")
include("patch_links_and_coordinates.jl")
include("utils.jl")
include("distance_and_progression.jl")
include("vegdata_from_vegsystemreferanse.jl")
include("curvature_bsplines.jl")
include("memoization_file.jl")
include("plot.jl")


# PrecompileTools
@setup_workload begin
    # Putting some things in `@setup_workload` instead of `@compile_workload` can reduce the size of the
    # precompile file and potentially make loading faster.
    # (too much work for me)
    @compile_workload begin
        # all calls in this block will be precompiled, regardless of whether
        # they belong to your package or not (on Julia 1.8 and higher)
        #
        na2 = "Dragsund vest"
        ea2 = 25183
        no2 = 6939251
        na1 = "Dragsund aust"
        ea1 = 25589
        no1 = 6939427
        title = na1 * " til " * na2
        d = route_leg_data(ea1, no1, ea2, no2)
        pl = plot_elevation_slope_speed_vs_progression(d, na1, na2)
        title!(pl[1], title)
        plot_elevation_and_slope_vs_progression(d, na1, na2)
        nothing
    end
end

end