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
export route_leg_data, delete_memoization_file, nvdb_request, unique_unnested_coordinates_of_multiline_string,
    plot_elevation_and_slope_vs_progression, link_split_key, coordinate_key
"Contains patched routes"
struct Quilt
    fromtos::Vector{Vector{Int64}}
    patches::Vector{JSON3.Object}
end
Quilt() = Quilt(Vector{Vector{Int64}}(), Vector{JSON3.Object}())

include("ini_file.jl")
include("nvdb_utils.jl")
include("request_nvdb.jl")
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
end