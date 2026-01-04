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
export route_leg_data, delete_memoization_file, nvdb_request, unique_unnested_coordinates_of_multiline_string,
    plot_elevation_and_slope_vs_progression, link_split_key, coordinate_key

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
end