# Also see exported.jl. These are callees.

function plot_elevation_and_slope_vs_progression!(p::T, s, z, slope, progression_at_ends, refs, na1, na2) where T <: Union{Plots.Plot, Plots.Subplot}
    pz = plot!(p, s, z, label="Elevation", legend=:topleft, 
        ylabel = "Elevation [m]", xlabel = "Progression [m]")
    ps = twinx(pz)
    plot!(ps, s, slope, color=:red, xticks=:none, label="Slope", legend=:topright, 
        linestyle=:dash, ylabel = "Slope [m / m]")
    hline!(ps, [0], label = "", linestyle = :dash, color = :red)
    t1 = text(na1, 8, :left, :bottom, :green, rotation = -90)
    y = (maximum(z) + minimum(z)) / 2
    annotate!(pz, [(0, y, t1)])
    t2 = text(na2, 8, :left, :top, :green, rotation = -90)
    annotate!(pz, [(s[end], y, t2)])
end
function plot_elevation_and_slope_vs_progression!(p::T, d::Dict, na1, na2)  where T <: Union{Plots.Plot, Plots.Subplot}
    s = d[:progression]
    slope = d[:slope]
    progression_at_ends = d[:progression_at_ends]
    mls = d[  :multi_linestring]
    _, _, z = unique_unnested_coordinates_of_multiline_string(mls)
    refs = d[:prefixed_vegsystemreferanse]
    plot_elevation_and_slope_vs_progression!(p, s, z, slope, progression_at_ends, refs, na1, na2)
end

function plot_speed_limit_vs_progression!(p, s, speed_limitation, progression_at_ends, refs)
    title!(p, "Speed limit [km/h]- Progression [m]")
    plot!(p, s, speed_limitation)
    vline!(p, progression_at_ends, line=(1, :dash, 0.6, [:salmon :green :red]))
    for i in 1:(length(refs) - 1)
        xs = (progression_at_ends[i] + progression_at_ends[i + 1]) / 2
        ref = "$i:" * refs[i][5:end]
        j = findfirst(x -> x > xs, s )
        y = (maximum(speed_limitation) + minimum(speed_limitation)) / 2
        t = text(ref, 6, :center, :top, :blue, rotation = -30)
        annotate!(p, [(xs, y, t)])
    end
    p
end
function plot_speed_limit_vs_progression!(p, d::Dict)
    speed_limitation = d[:speed_limitation]
    s = d[:progression]
    refs = d[:prefixed_vegsystemreferanse]
    progression_at_ends = d[:progression_at_ends]
    plot_speed_limit_vs_progression!(p, s, speed_limitation, progression_at_ends, refs)
end

