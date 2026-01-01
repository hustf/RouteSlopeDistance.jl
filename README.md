# RouteSlopeDistance.jl

## What does it do?
This package fetches and processes data for calculating minimum travel times and energy usage for (heavy) vehicles on Norwegian roads. 

Processed data is available through `route_leg_data(A, B)`, where `A` and `B` are UTM33 coordinates. It is presented as a dictionary with rich details including 
- centreline 3d coordinates
- curvature and slope based on centreline
- speed limit
- progression
- database references

There's also a plot definition for checking, `plot_elevation_and_slope_vs_progression`, which uses `Plots.jl`.

You can fetch other data, e.g. traffic counts, road class or surface, by adapting functions from `endpoints.jl`.

<img src="resource/plot.svg" alt = "plot" style="display: inline-block; margin: 0 auto; max-width: 640px">

## Data source
Raw data from [Norsk Vegdatabase](https://nvdb.atlas.vegvesen.no/). Data can be used under [public license](https://data.norge.no/nlod/no/1.0). 

Expert web interface: [vegkart.no/](https://vegkart.atlas.vegvesen.no/#kartlag:geodata/@79705,6949088,7)

Expert route patching (see below): [nvdb-vegdata.github.io/nvdb-visrute/ATM/](https://nvdb-vegdata.github.io/nvdb-visrute/ATM/)

## Processed data
Horizontal road curvature is found with the aid of Bsplines, and expressed as signed radius of curvature (negative values is right turn). Use this to estimate acceptable velocity from acceptable centripetal acceleration (`a = v² / r`).

Slope is also found with the aid of Bsplines and filtering designed to overcome stairstepping from low resolution data, and continuity at joints.

The effect of speed bumps is included as a 15 km/h local reduction in speed limit. The reduction is considered generally relevant to heavy vehicles, as the speed bump profile is often not available.

## Local patching and memoization

Patching includes defining additional points along certain routes (splitting or subdividing), as well as replacing requested points. Replacing points may correct errors in other data sources, or distinguish between ingoing and outgoing roads. Patches are stored in `RouteSlopeDistance.ini` and can be edited.

To reduce the number of web API calls, the package stores results locally. Such memoization saves to `RouteSlopeDistance.jls`, which is not human readable.

After patching, you may need to delete memoized routes. Like this:

```
julia> RouteSlopeDistance.delete_memoized_pair("(44874 6957827)-(45365 6957803)")
Route data (44874 6957827)-(45365 6957803) removed from C:\Users\f\RouteSlopeDistance.jls
Nothing removed from C:\Users\f\RouteSlopeDistance.jls : Unknown key (45365 6957803)-(44874 6957827).

julia> #  Delete the initialization file to restore factory settings:
       #  RouteSlopeDistance.delete_init_file()

julia> # If you suspect road changes or have seriously messed up:
       # RouteSlopeDistance.delete_memoization_file()

```


## Additional terminology

NVDB terms have clear definitions. Additionaly, this may be used in a public transportation context with a hierarchy:

`journey` or `route` > `leg` > `segment` > `point`

## How to use

```
pkg> registry add https://github.com/hustf/M8

pkg> add RouteSlopeDistance

julia> using RouteSlopeDistance

julia> begin # Integer UTM coordinates - one unit is 1m.
        ea1 = 25183
        no1 = 6939251
        ea2 = 25589
        no2 = 6939427
      end;

julia> d = route_leg_data(ea1, no1, ea2, no2)
Dict{Symbol, Any} with 9 entries:
  :radius_of_curvature         => [NaN, NaN, NaN, -103.936, -139.494, 1061.2, -325.072, NaN, NaN, NaN  …
  :multi_linestring            => [[(25182.9, 6.93925e6, 8.134), (25188.4, 6.93925e6, 8.53)], [(25188.4…
  :fartsgrense_tuples          => [(1.0, 80, 80), (0.891306, 80, 60), (1.0, 60, 60), (1.0, 60, 60), (1.…
  :prefixed_vegsystemreferanse => ["1515 FV61 S5D1 m1589-1596", "1515 FV61 S5D1 m1527-1589", "1515 FV61…
  :key                         => "(25183 6939251)-(25589 6939427)"
  :progression                 => [0.0, 6.632, 14.7193, 22.7688, 30.1352, 37.2072, 50.8257, 60.9213, 68…
  :speed_limitation            => [80.0, 80.0, 80.0, 80.0, 80.0, 80.0, 80.0, 62.4747, 60.0, 60.0  …  60…
  :slope                       => [0.0497983, 0.0516643, 0.05899, 0.0717922, 0.0850832, 0.0902067, 0.07…
  :progression_at_ends         => [0.0, 6.632, 68.609, 184.079, 194.451, 314.436, 322.708, 443.825]

julia> plot_elevation_and_slope_vs_progression(d, "A", "B")
```

## Suggested use
Routes between `A` and `B` can also be corrected by inserting additional points in the .ini file. When a route can't be found, further hints are printed.

Leg data may be used for calculating travel times and energy consumption with different vehicle models.

A good model would include available power curves, vehicle mass, gear shift times and air resistance. An advanced vehicle model would 
also include power train inertia, gear ratios, torque curves, and air temperature. 

For more conservative travel times, traffic count and light signal data can be fetched. 