# Also see 'exported.jl'.

function _prepare_init_file_configuration(io)
    # Add a comment at top (IniFile.jl has no functions for comments)
    msg = """
        # Configuration file for 'RouteSlopeDistance'.
        # You can modify and save the values here. To start over from 'factory settings':
        # Delete this file. A new file will be created next time configurations are used.
        #
        # We don't know how general NVDB's API is, hence we put some values for adaption
        # to similar APIs in this init file. Feel free to experiment with other countries
        # or authorities (unless their licences says otherwise).
        #
        # The default base url is the dev environment, which may not always be available.
        # Ref. https://nvdb-docs.atlas.vegvesen.no/category/nvdb-api-les-v4/
        #
        # Use https://nvdb-vegdata.github.io/nvdb-visrute/ATM/ for finding
        # new coorinate replacements or splits. 
        """
    println(io, msg)
    #
    conta = Inifile()
    # Lines in arbitrary order from file
    set(conta, "http fields", "User agent", "RouteSlopeDistance.jl 0.0.1 temp_script")
    set(conta, "api server", "baseurl",  "https://nvdbapiles.atlas.vegvesen.no/")
    set(conta, "http fields", "Accept", "application/vnd.vegvesen.nvdb-v3-rev2+json") # temp
    #

    #############
    # Link splits
    #############
    # Link splits are done in `patched_post_beta_vegnett_rute`. Splits
    # are performed first. After splitting, coordinates are replaced.
    # Hence, refer to the "original / uncorrected" coordinates in keys.
    # The key is from-to coordinates. The value is inserted coordinate.
    # Use https://nvdb-vegdata.github.io/nvdb-visrute/ATM/ for finding
    # new coorinate replacements or splits. 
    # Function call `link_split_key(ea1, no1, ea2, no2)` can be useful.
    #
    # You can edit the init file manually. If you revise here instead,
    # then do:
    #
    # julia> RouteSlopeDistance.delete_init_file()
    # Removed C:\Users\frohu_h4g8g6y\RouteSlopeDistance.ini
    #
    # You may also want to remove a cached leg, e.g.:
    # delete_memoized_pair("(31515 6946166)-(31167 6946060)")
    #
    # For testing purpose
    _add_link_split(conta, "(1 1)-(5 5)", "2 2", "Description1", also_reverse = false)
    _add_link_split(conta, "(2 2)-(5 5)", "3 3", "Description2", also_reverse = false)
    _add_link_split(conta, "(3 3)-(5 5)", "4 4",  "Description3", also_reverse = false)
    # copy-paste template
    #     _add_link_split(conta, "", "",
    # "", also_reverse = true)

    _add_link_split(conta, "(26223 6947530)-(26241 6947561)", "26263 6947547",
        "Skeide Ulstein skule <-> Ulstein skule", also_reverse = true)
    _add_link_split(conta, "(26714 6946197)-(25933 6945968)", "25867 6945942",
        "Ulstein verft - turn in yard at arrival", also_reverse = false)
    _add_link_split(conta, "(26449 6940130)-(27280 6939081)", "26461 6940151",
        "Garneskrysset -> Haddal nord: Force turn going out", also_reverse = false)
    _add_link_split(conta, "(27262 6945774)-(27714 6945607)", "27325 6945576",
        "Ulsteinvik skysstasjon -> Holsekerdalen: Force right side roundabout.", also_reverse = false)
    _add_link_split(conta, "(27714 6945607)-(27262 6945774)", "27426 6945653",
        "Ulsteinvik skysstasjon <- Holsekerdalen: Force right side roundabout.", also_reverse = false)
    _add_link_split(conta, "(28961 6945248)-(27262 6945774)", "27426 6945653",
        "Ulstein vgs -> Ulsteinvik skysstasjon: Force right side roundabout.", also_reverse = false)
    _add_link_split(conta, "(27714 6945607)-(27023 6946081)", "27333 6945601",
        "Holsekerdalen -> Ulstein rådhus", also_reverse = false)
    _add_link_split(conta, "(33196 6941267)-(34455 6946162)", "34636 6944658",
        "Kvammen <-> Kaldhol", also_reverse = true)
    _add_link_split(conta, "(34455 6946162)-(33729 6946682)", "34048 6946883",
        "Kaldhol <-> Bigsetkrysset", also_reverse = true)
    _add_link_split(conta, "(33142 6946489)-(35590 6942991)", "34048 6946883",
        "Byggeli <-> Ulset", also_reverse = true)
    _add_link_split(conta, "(36307 6947475)-(35983 6947673)", "36373 6947595",
        "Hareid ungdomsskule  -> Holstad", also_reverse = false)
    _add_link_split(conta, "(22262 6935850)-(22266 6936088)", "22394 6936132",
        "Leikong <-> Leikong kyrkje", also_reverse = true)
    _add_link_split(conta, "(21152 6935687)-(22262 6935850)", "22394 6936132",
        "Leikong <-> Leikongsætra", also_reverse = true)
    _add_link_split(conta, "(22243 6932325)-(22262 6935850)", "23393 6934807",
        "Voldneset <-> Leikong", also_reverse = true)
    _add_link_split(conta, "(21152 6935687)-(22262 6935850)", "22394 6936132",
        "Leikongsætra <-> Leikong", also_reverse = true)
    _add_link_split(conta, "(21895 6935787)-(22262 6935850)", "22394 6936132",
    "Leikongbakken <-> Leikong", also_reverse = true)
    _add_link_split(conta, "(16245 6947281)-(16074 6947525)", "16182 6947395",
        "Fosnavåg terminal <-> Fosnavåg sparebank", also_reverse = true)
    _add_link_split(conta, "(16064 6947515)-(16258 6947136)", "16111 6947359",
        "Fosnavåg terminal <-> Skarabakken", also_reverse = true)
    _add_link_split(conta, "(35335 6926025)-(36586 6926215)", "36610 6926461",
        "Åsen <-> Ørsta Volda lufthamn", also_reverse = true)
    _add_link_split(conta, "(35643 6922428)-(36193 6922438)", "35774 6922214",
        "Volda rutebilstasjon <-> Volda ungdomsskule", also_reverse = true)
    _add_link_split(conta, "(35249 6922447)-(35643 6922428)", "35653 6922271",
        " Volda ferjekai <-> Volda rutebilstasjon", also_reverse = true)
    _add_link_split(conta, "(36807 6922760)-(36907 6922492)", "35774 6922214",
        "Volda sjukehus <-> Studentheimane", also_reverse = true)
    _add_link_split(conta, "(5826 6914415)-(5863 6915184)", "5851 6915185",
        "Åheim <-> Torvik", also_reverse = true)
    _add_link_split(conta, "(5851 6915185)-(5863 6915184)", "5856 6914567",
        "Åheim <-> Torvik FV61 S12D1 m10700-11004", also_reverse = true)
    _add_link_split(conta, "(36976 6947659)-(36980 6947583)", "36994 6947462",
        "Hareid bussterminal -> Hareid ferjekai", also_reverse = false)
    _add_link_split(conta, "(54938 6956088)-(55100 6953046)", "55032 6956245", 
        "Moa trafikkterminal -> Urdalen", also_reverse = false)
    _add_link_split(conta, "(55100 6953046)-(54938 6956088)", "54978 6956381", 
        "Urdalen -> Moa trafikkterminal", also_reverse = false)
    _add_link_split(conta, "(53067 6956011)-(53608 6956115)", "52971 6956214", 
        "Ålesund sjukehus <-> Åse", also_reverse = true)
    _add_link_split(conta, "(23412 6939348)-(24064 6939043)", "23914 6938877",
        "Myrvåg <-> Møre barne- og ungdomsskule", also_reverse = true)
    _add_link_split(conta, "(23412 6939348)-(23911 6938921)", "23914 6938877",
        "Myrvåg <-> Myrvåglomma", also_reverse = true)
    _add_link_split(conta, "(26714 6946197)-(27714 6945607)", "27325 6945576",
        "Kongsberg Maritime Ulsteinvik -> Holsekerdalen", also_reverse = false)
    _add_link_split(conta, "(36272 6958672)-(46842 6959869)", "40759 6962842",
        "Skjong nordre <-> Juv snuplass")
    _add_link_split(conta, "(38574 6917520)-(36589 6919296)", "36801 6919474",
        "Løvikneset <-> Grevsnes")
    _add_link_split(conta, "(36589 6919296)-(39116 6917180)", "36801 6919474",
        "Grevsnes <-> Humberset")
    _add_link_split(conta, "(33142 6946489)-(35590 6942991)", "34063 6946848",
        "Byggeli <-> Ulset")
    _add_link_split(conta, "(23294 6937470)-(23911 6938921)", "4124 6938709",
        "Djupvika <-> Myrvåglomma")
    #
    #########################
    # Coordinate replacements
    #########################
    # Coordinate replacements are done in `patched_post_beta_vegnett_rute`, after
    # splits of requests.

    _add_coord_replacement(conta, (27262, 6945774) => (27265, 6945717), "Ulsteinvik skysstasjon", alternative_out = (27224, 6945781))
    _add_coord_replacement(conta, (36976, 6947659) => (36943, 6947662), "Hareid bussterminal", alternative_out = (36975, 6947631))
    _add_coord_replacement(conta, (26449, 6940130) => (26453, 6940120),  "Garneskrysset")
    _add_coord_replacement(conta, (16064, 6947515) => (16048, 6947536),  "Fosnavåg terminal", alternative_out = (16075, 6947499))
    _add_coord_replacement(conta, (25885, 6945943) => (25933, 6945968),  "Ulstein verft")
    _add_coord_replacement(conta, (26670, 6946408) => (26677, 6946389),  "Reiten")
    _add_coord_replacement(conta, (22266, 6936088) => (22267, 6936067),  "Leikong kyrkje")
    _add_coord_replacement(conta, (17433, 6933394) => (17437, 6933383),  "Skoge")
    _add_coord_replacement(conta, (15033, 6933457) => (15020, 6933460),  "Gursken oppvekssenter")
    _add_coord_replacement(conta, (11193, 6931632) => (11211, 6931634),  "Grønnevik")
    _add_coord_replacement(conta, (22243, 6932325) => (22257, 6932322),  "Voldnes")
    _add_coord_replacement(conta, (35643, 6922428) => (35653, 6922468),  "Volda rutebilstasjon", alternative_out = (35644, 6922407))
    _add_coord_replacement(conta, (36586, 6926215) => (36652, 6926215),  "Ørsta Volda lufthamn", alternative_out = (36564, 6926161))
    _add_coord_replacement(conta, (54938, 6956088) => (54967, 6956088),  "Moa trafikkterminal", alternative_out = (54923, 6956123))
    _add_coord_replacement(conta, (11193, 6931632) => (11198, 6931667),  "Grønnevik")
    _add_coord_replacement(conta, (36980, 6947583) => (37005, 6947595), "Hareid ferjekai")
    _add_coord_replacement(conta, (44874, 6957827) => (44990, 6957865), "Ålesund rutebilstasjon")
    _add_coord_replacement(conta, (50459, 6952400) => (50432, 6952397), "Simabakken")
    _add_coord_replacement(conta, (46273, 6954707) => (46252, 6954684), "Lerheimskaia")
    _add_coord_replacement(conta, (61552, 6968858) => (61534, 6968855), "Instevågen")
    _add_coord_replacement(conta, (69101, 6961820) => (69073, 6961823), "Vadset")
    _add_coord_replacement(conta, (83370, 6934535) => (83353, 6934536), "Stranda kai")
    _add_coord_replacement(conta, (65186, 6944721) => (65175, 6944723), "Vik nord")
    _add_coord_replacement(conta, (64658, 6942218) => (64651, 6942200), "Riksheim")
    _add_coord_replacement(conta, (28752, 6925847) => (28773, 6925837), "Ulvestad")
    _add_coord_replacement(conta, (49759, 6957942) => (49653, 6957970), "Torvteigen")
    _add_coord_replacement(conta, (56842, 6957522) => (56812, 6957450), "Bingsa")
    _add_coord_replacement(conta, (39947, 6961699) => (39948, 6961715), "Giske kyrkje")
    _add_coord_replacement(conta, (78987, 6954575) => (78979, 6954579), "Sjøholt")

    _add_coord_replacement(conta, (16347, 6954896) => (16344, 6954890),  "Goksøyr snuplass", alternative_out = (16344, 6954890))
    _add_coord_replacement(conta, (16658, 6954386) => (16654, 6954386),  "Goksøyr ytre")
    _add_coord_replacement(conta, (39234, 6959744) => (39222, 6959754),  "Støbakk")
    _add_coord_replacement(conta, (2771,  6933098) => (	2742, 6933101), "Kvamsøya ferjekai")
    _add_coord_replacement(conta, (55770, 6955163) => (55656, 6955157), "Spjelkavik barneskole")
    _add_coord_replacement(conta, (55801, 6955414) => (55810, 6955425), "Spjelkavik ungdomsskole")
    _add_coord_replacement(conta, (31989, 6908085) => (31981, 6908162), "Sandvika")
    _add_coord_replacement(conta, (52071, 6908130) => (52086, 6908129), "Kalvatn E39")
    _add_coord_replacement(conta, (43757, 6925518) => (43759, 6925541), "Follestaddalen")

    # This is a trick - we don't want to merge stops 'Høgskulen i Volda' and 'Vikebygdvegen',
    # but we don't want to lower the threshold too much for this reason, either. 
    # So we move the school stop.
    _add_coord_replacement(conta, (36505, 6922556) => (36530, 6922638), "Høgskulen i Volda")

    # This is a trick - there is no public road between Raudemyrvegen and Brenslene. 
    # We can move the outgoing, because the bus line only travels in one direction.
    _add_coord_replacement(conta, (37168, 6923045) => (37168, 6923045),  "Raudemyrvegen", alternative_out = (37122, 6923051))
    # This is a trick - there is no road across fjords. But it's not sufficent. Out of ferjekai to somewhere on land is also affected.
    #_add_coord_replacement(conta, (13869, 6928277) => (13869, 6928277),  "Koparneset ferjekai", alternative_out = (13742, 6930773))
    #_add_coord_replacement(conta, (13742, 6930773) => (13742, 6930773),  "Årvika ferjekai", alternative_out = (13869, 6928277))
    #=throw("Ouch")

 #    Ulsteinvik skysstasjon
 #   set(conta, "coordinates replacement", "In to 27262 6945774", "27265 6945717")
 #   set(conta, "coordinates replacement", "Out of 27262 6945774", "27224 6945781")
    # Garneskrysset
    set(conta, "coordinates replacement", "In to 26449 6940130", "26453 6940120")
    set(conta, "coordinates replacement", "Out of 26449 6940130", "26453 6940120")
    # Fosnavåg terminal
    set(conta, "coordinates replacement", "In to 16064 6947515", "16048 6947536")
    set(conta, "coordinates replacement", "Out of 16064 6947515", "16075 6947499")
    # Hareid bussterminal
    set(conta, "coordinates replacement", "Out of 36976 6947659",  "36947 6947667")
    set(conta, "coordinates replacement", "In to 36976 6947659", "36943 6947661")
    # Ulstein verft
    set(conta, "coordinates replacement", "Out of 25885 6945943",  "25933 6945968")
    set(conta, "coordinates replacement", "In to 25885 6945943", "25933 6945968")
    # Reiten
    set(conta, "coordinates replacement", "Out of 26670 6946408",  "26677 6946389")
    set(conta, "coordinates replacement", "In to 26670 6946408", "26677 6946389")
    # Leikong
    set(conta, "coordinates replacement", "Out of 22262 6935850",  "22272 6935836")
    # Leikong kyrkje
    set(conta, "coordinates replacement", "Out of 22266 6936088",  "22267 6936067")
    set(conta, "coordinates replacement", "In to 22266 6936088",  "22267 6936067")
    # Skoge
    set(conta, "coordinates replacement", "Out of 17433 6933394",  "17437 6933383")
    set(conta, "coordinates replacement", "In to 17433 6933394",  "17437 6933383")
    # Gursken oppvekssenter
    set(conta, "coordinates replacement", "Out of 15033 6933457",  "15020 6933460")
    set(conta, "coordinates replacement", "In to 15033 6933457",  "15020 6933460")

    # Voldnes
    set(conta, "coordinates replacement", "Out of 22243 6932325",  "22257 6932322")
    set(conta, "coordinates replacement", "In to 22243 6932325",  "22257 6932322")
    # Volda rutebilstasjon
    set(conta, "coordinates replacement", "Out of 35643 6922428",  "35644 6922407")
    set(conta, "coordinates replacement", "In to 35643 6922428",  "35653 6922468")
    # Ørsta Volda lufthamn
    set(conta, "coordinates replacement", "Out of 36586 6926215",  "36564 6926161")
    set(conta, "coordinates replacement", "In to 36586 6926215",  "36652 6926215")
    # Moa trafikkterminal
    set(conta, "coordinates replacement", "Out of 54938 6956088",  "54923 6956123")
    set(conta, "coordinates replacement", "In to 54938 6956088",  "54967 6956088")

    #set()

    #=
    # Leine ytre
    set(conta, "coordinates replacement", "Out of 18365 6948288",  "18357 6948270")
    set(conta, "coordinates replacement", "In to 18365 6948288",  "18357 6948270")
    # Elsebøvegen
    set(conta, "coordinates replacement", "Out of 17690 6946368",  "17685 6946350")
    set(conta, "coordinates replacement", "In to 17690 6946368",  "17685 6946350")
    # Eggesbønes
    set(conta, "coordinates replacement", "Out of 16088 6945709",  "16103 6945675")
    set(conta, "coordinates replacement", "In to 16088 6945709",  "16103 6945675")
    # Herøy kyrkje
    set(conta, "coordinates replacement", "Out of 16166 6946661",  "16145 6946644")
    set(conta, "coordinates replacement", "In to 16166 6946661",  "16145 6946644")
    # Fosnavåg sparebank
    set(conta, "coordinates replacement", "Out of 16245 6947281",  "16231 6947266")
    set(conta, "coordinates replacement", "In to 16245 6947281",  "16231 6947266")
    # Fosnavåg terminal -- 16074 6947525
    set(conta, "coordinates replacement", "In to 16074 6947525", "16045 6947534")
    set(conta, "coordinates replacement", "Out of 16074 6947525", "16074 6947500")
    # Goksøyr ytre
    set(conta, "coordinates replacement", "In to 16668 6954396", "16654 6954386")
    set(conta, "coordinates replacement", "Out of 16668 6954396", "16654 6954386")
    # Goksøyr snuplass
    set(conta, "coordinates replacement", "In to 16357 6954906", "16344 6954890")
    set(conta, "coordinates replacement", "Out of 16357 6954906", "16344 6954890")
    =#
    =#
    # To file..
    println(io, conta)
end


"""
    get_config_value(sect::String, key::String)
    get_config_value(sect, key, type::DataType; nothing_if_not_found = false)

Instead of passing long argument lists, we store configuration in a text file.
"""
function get_config_value(sect::String, key::String; nothing_if_not_found = false)
    fnam = _get_ini_fnam()
    ini = read(Inifile(), fnam)
    if sect ∉ keys(sections(ini))
        msg = """$sect not a section in $fnam.
        The existing are: $(keys(sections(ini))).
        If you delete the .ini file above, a new template will be generated.
        """
        throw(ArgumentError(msg))
    end
    if nothing_if_not_found
        get(ini, sect, key,  nothing)
    else
        s = get(ini, sect, key,  "")
        if s == ""
            throw(ArgumentError("""
                $key not a key with value in section $sect of file $fnam.

                Example:
                [user]                          # section
                user_name     = slartibartfast  # key and value
                perceived_age = 5

                Current file:
                $ini
            """))
        end
        s
    end
end
function get_config_value(sect, key, type::DataType; nothing_if_not_found = false)
    st = get_config_value(sect, key; nothing_if_not_found)
    isnothing(st) && return nothing
    tryparse(type, st)
end

function get_config_value(sect, key, ::Type{Tuple{Float64, Float64}}; nothing_if_not_found = false)
    st = get_config_value(sect, key; nothing_if_not_found)
    isnothing(st) && return nothing
    (tryparse(Float64, split(st, ' ')[1]),     tryparse(Float64, split(st, ' ')[2]))
end
function get_config_value(sect, key, ::Type{Tuple{Int64, Int64}}; nothing_if_not_found = false)
    st = get_config_value(sect, key; nothing_if_not_found)
    isnothing(st) && return nothing
    (tryparse(Int64, split(st, ' ')[1]),     tryparse(Int64, split(st, ' ')[2]))
end



"delete_init_file()"
function delete_init_file()
    fna = _get_fnam_but_dont_create_file()
    if isfile(fna)
        rm(fna)
        println("Removed $fna")
    else
        println("$fna Didn't and doesn't exist.")
    end
end




"Get an existing, readable ini file name, create it if necessary"
function _get_ini_fnam()
    fna = _get_fnam_but_dont_create_file()
    if !isfile(fna)
        open(_prepare_init_file_configuration, fna, "w+")
        # Launch an editor
        if Sys.iswindows()
            run(`cmd /c $fna`; wait = false)
        end
        println("Default settings stored in $fna")
    end
    fna
end
_get_fnam_but_dont_create_file() =  joinpath(homedir(), "RouteSlopeDistance.ini")


"""
    _add_link_split(conta, keypair::String, keycoordinate::String, description::String; also_reverse = false)
    ---> Vector{Float64}

`description` is a comment and will not be read by `get_config_value`

# Example
```
julia> _add_link_split(conta, "(19429 6943497)-(19922 6944583)", "20160 6944585", "Notøy <-> Røyra øst"; also_reverse = true)
```
"""
function _add_link_split(conta, keypair::String, keycoordinate::String, description::String; also_reverse = false)
    v_assert = split(keypair, [' ', '-'])
    @assert ! isnothing(tryparse(Int, strip(v_assert[1], ['(', ')'])))    keypair
    @assert ! isnothing(tryparse(Int, strip(v_assert[2], ['(', ')'])))    keypair
    @assert ! isnothing(tryparse(Int, strip(v_assert[3], ['(', ')'])))    keypair
    @assert ! isnothing(tryparse(Int, strip(v_assert[4], ['(', ')'])))    keypair
    set(conta, "link split", keypair, keycoordinate * " # " * description)
    if also_reverse
        fromkey, tokey = split(keypair, '-')
        kpr = tokey * '-' * fromkey
        set(conta, "link split", kpr, keycoordinate * " # " * description)
    end
    nothing
end


"""
    _add_coord_replacement(conta, 
            old_new_pair::Pair{Tuple{Int64, Int64}, Tuple{Int64, Int64}}, 
            description::String; 
            alternative_out::Union{Nothing, Tuple{Int64, Int64}} = nothing)

Add a line to the defaul .ini file. If no `alternative_out` is given, sets 
ingoing and outgoing coordinates identical.

# Example

Equivalent to
```
set(conta, "coordinates replacement", "Out of 18365 6948288",  "18357 6948270")
set(conta, "coordinates replacement", "In to 18365 6948288",  "18357 6948270")
```
"""
function _add_coord_replacement(conta, 
        old_new_pair::Pair{Tuple{Int64, Int64}, Tuple{Int64, Int64}}, 
        description::String; 
        alternative_out::Union{Nothing, Tuple{Int64, Int64}} = nothing)
    oldc = old_new_pair[1]
    newc = old_new_pair[2]
    set(conta, "coordinates replacement", "In to $(oldc[1]) $(oldc[2])", "$(newc[1]) $(newc[2])  # $description")
    if ! isnothing(alternative_out)
        set(conta, "coordinates replacement", "Out of $(oldc[1]) $(oldc[2])", "$(alternative_out[1]) $(alternative_out[2])  # $description")
    else
        set(conta, "coordinates replacement", "Out of $(oldc[1]) $(oldc[2])", "$(newc[1]) $(newc[2])  # $description")
    end
    nothing
end
