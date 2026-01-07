"""
    get_posisjon(easting::T, northing::T) where T
    --> ::String

v3: https://nvdbapiles-v3.atlas.vegvesen.no/dokumentasjon/openapi/#/Vegnett/get_posisjon
v4: https://nvdb-docs.atlas.vegvesen.no/nvdbapil/v4/Posisjon

Returns a vegsystemreferanse prefixed by kommunenummer, or an error message.
The server sends more info. Unfortunately, the server returns HTTP error 
'404 Not found' when an object can't be found, which 
is printed and can be annoying.

Instead of adding lots of parameters to the call, we stick with the default
'Kjørende' selection.

We only intend to use this for identifying problematic points on a route.
When such are identified, we could 'hard-code' some numeric replacements,
updated in the .ini file.
"""
function get_posisjon(easting::T, northing::T;
    trafikantgruppe        = "K",
        maks_avstand = 10) where T
    url = "posisjon?nord=$(fixed(northing))&ost=$(fixed(easting))"
    url *= "& maks_avstand = $maks_avstand"
    url *= "& trafikantgruppe =  $trafikantgruppe "
    o = nvdb_request(url)
    if o isa AbstractArray
        # A successful response methinks
        @assert ! isempty(o) "Empty response to $url"
        kortform = get(o[1].vegsystemreferanse, :kortform, "")
        if kortform !== ""
            return "$(o[1].kommune) $(o[1].vegsystemreferanse.kortform)"
        else
            return "Error: Vegsystemreferanse mangler på dette objektet."
        end
    else
        code = get(o, :code, 0)
        if code == 4012
            return "Error: " * o.message * "\n" * o.message_detailed
        end
    end
    JSON3.pretty(o)
    throw("unknown response")
end




"""
    post_beta_vegnett_rute(easting1, northing1, easting2, northing2)
    --> JSON3.Object, waitsec

v3:
https://nvdbapiles-v3.atlas.vegvesen.no/dokumentasjon/openapi/#/Vegnett/post_beta_vegnett_rute
v4:
https://nvdbapiles.atlas.vegvesen.no/swagger-ui/index.html?urls.primaryName=Vegnett#/Rute
"""
function post_beta_vegnett_rute(easting1, northing1, easting2, northing2; omkrets::Int64 = 100)
    # v3:
    # "Gyldige verdier for 'typeveg' er [kanalisertveg, enkelbilveg, rampe, rundkjøring, 
    # bilferje, passasjerferje, gangogsykkelveg, sykkelveg, gangveg, gågate, fortau, trapp, 
    # gangfelt, gatetun, traktorveg, sti, annet]
    # v4:
    # typeVeg
    # allarray
    #0"Enkel bilveg"
    #1"Kanalisert veg"
    #2"Rampe"
    #3"Rundkjøring"
    #4"Bilferje"
    #5"Gang- og sykkelveg"
    #6"Sykkelveg"
    #7"Gangveg"
    #8"Gågate"
    #9"Fortau"
    #10"Trapp"
    #11"Gangfelt"
    #12"Gatetun"
    #13"Passasjerferje"
    #14"Traktorveg"
    #15"Sti"
    #16"Annet"


    body = Dict{Symbol, Any}([
        #v3:typeveg                => "kanalisertVeg,enkelBilveg,rampe,rundkjøring,gangOgSykkelveg"
        :typeveg                => ["Kanalisert veg", "Enkel bilveg", "Rampe", "Rundkjøring", "Gang- og sykkelveg", "Bilferje"]
        :konnekteringslenker    => true
        :start                  => "$(fixed(easting1)) , $(fixed(northing1))"
        :trafikantgruppe        => "K"
        :maks_avstand  => 10
        :detaljerte_lenker      => true
        :behold_trafikantgruppe => true
        :slutt                  => "$(fixed(easting2)) , $(fixed(northing2))"
        :tidspunkt              => "2023-07-28"
        :inkluderAntall         => false
        ])
    push!(body, :omkrets => omkrets)
    # Make the call, get a json object
   nvdb_request("vegnett/api/v4/beta/vegnett/rute", "POST"; body)
end


"""
    get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, vegsystemreferanse::String; inkluder = "", alle_versjoner = false)
    --> JSON3.Object

v3:
https://nvdbapiles-v3.atlas.vegvesen.no/dokumentasjon/openapi/#/Vegobjekter/get_vegobjekter__vegobjekttypeid_
v4:
https://nvdbapiles.atlas.vegvesen.no/swagger-ui/index.html?urls.primaryName=Vegobjekter#/Vegobjekter/getVegobjektByTypeAndId
Drops 'arm'

"""
function get_vegobjekter__vegobjekttypeid_(vegobjekttype_id, vegsystemreferanse::String; 
    inkluder = "", alle_versjoner = false, segmentering = false, kommune = "", inkluderAntall = false)
    u = "vegobjekter/$vegobjekttype_id"
    a = urlstring(;  vegsystemreferanse = vegsystemreferanse, inkluder, alle_versjoner, segmentering, kommune)
    url = build_query_string(u, a)
    o = nvdb_request(url)
    isempty(o) && throw("Request failed, check connection")
    o
end
