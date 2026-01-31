using Test
using RouteSlopeDistance
# Note, tests are not in a ready-to run state.
# This is used for finding and fixing stuff manually.
@testset "unit" begin
include("t_unit.jl")
end
@testset "vegsystem id" begin
include("t_retrieve_vegsystem_id_geom.jl")
end
@testset "vegobjekt" begin
include("t_retrieve_vegobjekt.jl")
end
@testset "dictionary" begin
include("t_route_leg_data.jl")
end
@testset "join dictionary" begin
include("t_join_results.jl")
end