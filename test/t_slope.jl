using Test
using RouteSlopeDistance
using RouteSlopeDistance: smooth_slope_from_multiline_string, smooth_slope, unique_unnested_coordinates_of_multiline_string
using RouteSlopeDistance: unique_unnested_coordinates_of_multiline_string, smooth_slope, smooth_coordinate
using RouteSlopeDistance: link_split_key
using Plots


mls = [[(33728.644, 6.946682377e6, 31.277), (33725.9, 6.9466807e6, 31.411), 
    (33722.49, 6.9466785e6, 31.511), (33718.99, 6.9466763e6, 31.611), (33717.1, 6.9466751e6, 31.711)], 
    [(33717.1, 6.9466751e6, 31.711), (33715.99, 6.9466743e6, 31.711), (33713.1, 6.9466726e6, 31.711),
    (33710.81, 6.946671e6, 31.811)], [(33710.81, 6.946671e6, 31.811), (33709.81, 6.9466703e6, 31.911), 
    (33706.31, 6.9466682e6, 32.011), (33703.2, 6.9466661e6, 32.211)], [(33703.2, 6.9466661e6, 32.211), 
    (33699.99, 6.9466641e6, 32.411), (33696.7, 6.946662e6, 32.511), (33693.49, 6.9466597e6, 32.711),
    (33692.4, 6.946659e6, 32.811)], [(33692.4, 6.946659e6, 32.811), (33690.1, 6.9466576e6, 32.911), 
    (33687.81, 6.9466559e6, 33.011), (33685.99, 6.9466546e6, 33.011), (33683.7, 6.9466529e6, 33.111), 
    (33680.6, 6.9466507e6, 33.311), (33677.4, 6.9466486e6, 33.511), (33674.7, 6.9466466e6, 33.511), 
    (33671.49, 6.9466443e6, 33.711), (33668.49, 6.9466419e6, 33.911), (33665.31, 6.9466393e6, 34.011), 
    (33661.99, 6.9466368e6, 34.211), (33658.6, 6.9466342e6, 34.211), (33654.49, 6.946631e6, 34.411),
    (33645.9, 6.9466241e6, 34.711), (33642.9, 6.9466218e6, 34.811), (33640.9, 6.9466201e6, 34.711), 
    (33638.2, 6.9466182e6, 34.711), (33636.1, 6.9466165e6, 34.811), (33633.7, 6.9466146e6, 34.811),
    (33631.7, 6.946613e6, 34.911), (33629.99, 6.9466116e6, 34.911), (33628.1, 6.9466101e6, 34.811), 
    (33624.9, 6.9466077e6, 34.811), (33621.49, 6.946605e6, 34.911), (33618.4, 6.9466027e6, 34.911), 
    (33615.6, 6.9466006e6, 34.911), (33612.31, 6.9465981e6, 34.911), (33608.9, 6.9465958e6, 34.911),
    (33605.2, 6.9465931e6, 34.911), (33602.1, 6.946591e6, 34.911), (33598.81, 6.9465888e6, 34.911), 
    (33595.6, 6.9465866e6, 34.911), (33592.2, 6.9465843e6, 35.011), (33589.4, 6.9465824e6, 35.011), 
    (33585.99, 6.9465803e6, 35.111), (33582.99, 6.9465783e6, 35.111), (33579.6, 6.9465762e6, 35.211),
    (33575.9, 6.9465739e6, 35.211), (33571.7, 6.9465716e6, 35.311), (33568.1, 6.9465694e6, 35.411), 
    (33567.4, 6.9465691e6, 35.511)], [(33567.4, 6.9465691e6, 35.511), (33564.7, 6.9465676e6, 35.511),
    (33561.7, 6.9465659e6, 35.511), (33558.6, 6.946564e6, 35.711), (33554.7, 6.9465619e6, 35.811), 
    (33551.7, 6.9465603e6, 35.911), (33548.1, 6.9465583e6, 36.011), (33544.7, 6.9465564e6, 36.011), 
    (33540.49, 6.9465543e6, 36.211), (33536.6, 6.9465524e6, 36.411), (33532.4, 6.9465502e6, 36.411),
    (33528.31, 6.9465481e6, 36.511), (33524.7, 6.9465463e6, 36.511), (33520.31, 6.9465441e6, 36.611),
    (33516.49, 6.9465423e6, 36.811), (33512.7, 6.9465406e6, 36.911), (33508.6, 6.9465388e6, 36.911), 
    (33504.99, 6.946537e6, 36.911), (33501.1, 6.9465352e6, 37.011), (33497.49, 6.9465336e6, 37.111),
    (33494.2, 6.9465322e6, 37.211), (33490.81, 6.9465308e6, 37.211), (33486.99, 6.9465292e6, 37.311),
    (33483.7, 6.9465277e6, 37.311), (33481.9, 6.946527056e6, 37.211)], 
    [(33481.9, 6.946527056e6, 37.211), (33480.1, 6.9465263e6, 37.211), (33476.49, 6.9465249e6, 37.311),
    (33472.9, 6.9465234e6, 37.411), (33469.1, 6.9465219e6, 37.411), (33464.9, 6.9465203e6, 37.411),
    (33460.99, 6.9465189e6, 37.411), (33457.6, 6.9465178e6, 37.511), (33453.1, 6.9465162e6, 37.511),
    (33449.2, 6.9465148e6, 37.511), (33446.1, 6.9465137e6, 37.511), (33442.4, 6.9465125e6, 37.511), 
    (33439.31, 6.9465115e6, 37.511), (33434.81, 6.9465102e6, 37.511), (33430.4, 6.9465089e6, 37.511),
    (33426.4, 6.9465078e6, 37.611), (33422.9, 6.9465068e6, 37.611), (33418.9, 6.9465059e6, 37.611), 
    (33414.99, 6.9465049e6, 37.611), (33411.31, 6.9465041e6, 37.611), (33407.2, 6.946503e6, 37.611), 
    (33404.95, 6.94650258e6, 37.571)], [(33404.95, 6.94650258e6, 37.571), (33403.4, 6.9465023e6, 37.711),
    (33399.49, 6.9465014e6, 37.711), (33395.31, 6.9465006e6, 37.711), (33391.6, 6.9464999e6, 37.711),
    (33387.2, 6.9464992e6, 37.711), (33383.81, 6.9464984e6, 37.711), (33380.49, 6.946498e6, 37.811), 
    (33377.2, 6.9464975e6, 37.811), (33374.1, 6.946497e6, 37.811), (33370.7, 6.9464967e6, 37.811)],
    [(33370.7, 6.9464967e6, 37.811), (33367.81, 6.9464963e6, 37.911), (33364.9, 6.9464959e6, 37.811),
    (33361.49, 6.9464956e6, 37.811), (33357.9, 6.9464952e6, 37.811), (33354.31, 6.9464949e6, 37.811), 
    (33350.31, 6.9464948e6, 37.81), (33347.31, 6.9464945e6, 37.91), (33343.49, 6.9464941e6, 37.91), 
    (33339.7, 6.9464939e6, 37.81), (33336.6, 6.9464937e6, 37.81), (33333.4, 6.9464935e6, 37.81), 
    (33329.99, 6.9464935e6, 37.71), (33325.99, 6.9464933e6, 37.71), (33322.2, 6.9464931e6, 37.71),
    (33318.7, 6.946493e6, 37.71), (33314.99, 6.946493e6, 37.71), (33310.6, 6.9464928e6, 37.61), 
    (33306.31, 6.9464928e6, 37.51), (33301.2, 6.9464926e6, 37.41), (33296.1, 6.9464925e6, 37.41)], 
    [(33296.1, 6.9464925e6, 37.41), (33290.699, 6.9464925e6, 37.31), (33286.773, 6.946492338e6, 37.31)], 
    [(33286.773, 6.946492338e6, 37.31), (33283.199, 6.9464923e6, 37.21), (33278.9, 6.9464921e6, 37.11), (33274.99, 6.946492e6, 37.01), (33271.1, 6.9464919e6, 36.91), (33266.99, 6.9464917e6, 36.81), (33262.6, 6.9464917e6, 36.81)], 
    [(33262.6, 6.9464917e6, 36.81), (33256.99, 6.9464917e6, 36.71), (33251.811, 6.9464916e6, 36.81), (33246.49, 6.9464914e6, 36.71), (33241.311, 6.9464914e6, 36.71), (33234.4, 6.9464911e6, 36.61), (33229.49, 6.946491e6, 36.61), (33222.199, 6.9464909e6, 36.61), (33217.4, 6.9464907e6, 36.51), (33211.99, 6.9464906e6, 36.51), (33205.99, 6.9464905e6, 36.41), (33201.811, 6.9464905e6, 36.41), (33196.311, 6.9464903e6, 36.41), (33191.6, 6.9464902e6, 36.41), (33187.4, 6.9464901e6, 36.41), (33182.811, 6.9464901e6, 36.41), (33177.6, 6.9464898e6, 36.41), (33171.99, 6.9464897e6, 36.41), (33166.2, 6.9464898e6, 36.51)], 
    [(33166.2, 6.9464898e6, 36.51), (33161.7, 6.9464897e6, 36.61), (33156.1, 6.9464896e6, 36.71), (33151.9, 6.9464896e6, 36.71), (33146.99, 6.9464894e6, 36.81), (33142.31, 6.9464894e6, 36.91), (33142.204, 6.946489398e6, 36.915)]]

progression = [0.0, 3.218618302729048, 7.277878756915406, 11.413030071205382, 13.654, 15.022330364961599, 18.37545861860695, 21.171, 22.395802387133926, 26.478885257418202, 
    30.237000000000002, 34.024361463256334, 37.928731743059515, 41.88273066425843, 43.182, 45.876430838882584, 48.73020945185068, 50.96680748201883, 53.82058609498693, 57.62714822703951,
    61.45989059995222, 64.8199402986283, 68.7739267140015, 72.6209922773685, 76.72980004566699, 80.89060510711079, 85.162840267089, 90.37551147313039, 101.39764327956811, 105.17916630271694,
    107.80594372959031, 111.10744887968761, 113.81114214126495, 116.872178764189, 119.4353723929075, 121.64536593123721, 124.06033298994342, 128.06032129384906, 132.4109522034948,
    136.26296638153778, 139.76295614808822, 143.89502586590416, 148.00817564001534, 152.5885552435776, 156.33287334054683, 160.2906515555568, 164.18218228781222, 168.2882633152723, 
    171.67203828411147, 175.67803455909365, 179.28357529214497, 183.2725609961231, 187.62915243973498, 192.41871044161053, 196.63888767084507, 197.40699999999998, 200.4974102636986, 
    203.94751975115148, 207.59097728674226, 212.02402187909064, 215.42738767343624, 219.54914929659014, 223.44618819290673, 228.15775063360346, 232.49399775319588, 237.23794775940112, 
    241.83921680219393, 245.87533385064907, 250.78949627616467, 255.0194282982379, 259.17675276884995, 263.65697068681925, 267.6930877352744, 271.98291210774084, 275.93506264722964, 
    279.5139400418241, 283.1836943898071, 287.3287557129513, 290.9465831774693, 292.86199999999997, 294.8129759059668, 298.68357259674514, 302.5729579528157, 306.6554943125218, 
    311.14685132241954, 315.2970847464613, 318.8600414368145, 323.63274582219077, 327.77357238476975, 331.060692116614, 334.9477531245871, 338.19330841600816, 342.87410970388987, 
    347.46857385289775, 351.61542519179955, 355.25298239899075, 359.35016905574656, 363.3832515606779, 367.1466201693852, 371.39835697677137, 373.686, 375.2673027274753, 379.2795611831578, 
    383.5354433093233, 387.310917373345, 391.766267572662, 395.2493967499271, 398.59491344887687, 401.9227026723902, 405.06277786623764, 408.476, 411.39525759361396, 414.33431601754955, 
    417.75748001212617, 421.3696879594306, 424.9721935518324, 428.97343524099847, 431.9900496540622, 435.83092705842535, 439.62750981509134, 442.7339483307935, 445.9401856359327, 449.3516445705877, 
    453.356633201223, 457.151898761072, 460.6533198298869, 464.3633121891567, 468.758994208205, 473.0501507134567, 478.16503020751344, 483.266, 488.6677713464813, 492.59700000000004, 
    496.1852205653562, 500.50522557527006, 504.43159147139687, 508.3378999611888, 512.4685056987893, 516.874, 522.4848688900082, 527.6657788093007, 532.9914539307049, 538.1704333427824, 
    545.0886369010168, 549.9996356027539, 557.2912923610696, 562.0954798572877, 567.5063824829091, 573.5080250599128, 577.6870084472595, 583.190621731162, 587.9026642257029, 592.103837832371,
    596.6928195898608, 601.9124272754768, 607.5232961654783, 613.315, 617.8171652093096, 623.4188803843581, 627.6188277101809, 632.5338550801312, 637.2148646268029, 637.321]

_, _, z = unique_unnested_coordinates_of_multiline_string(mls)
@test length(z) == length(progression)
slope = smooth_slope_from_multiline_string(mls, progression)
function simple_int()
    z_c = z[1]
    for i = 2:length(z)
        dx = progression[i] - progression[i - 1]
        z_c += slope[i - 1] * dx
    end
    z_c
end
z_c = simple_int()
@test abs(z_c - z[end]) < 0.15
    
### 
na1 = "Dragsund vest"
ea1 = 25183
no1 = 6939251
na2 = "Dragsund aust"
ea2 = 25589
no2 = 6939427
print(lpad("", 5), "  ", lpad(na1, 30), " -> ", rpad(na2, 30), " ")
println(link_split_key(ea1, no1, ea2, no2))
d = route_data(ea1, no1, ea2, no2)
mls = d[:multi_linestring]
s = d[:progression]
_, _, z = unique_unnested_coordinates_of_multiline_string(mls)
plot_elevation_and_slope_vs_progression(d, na1, na2)