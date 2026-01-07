# Ref. https://nvdbapiles-v3.atlas.vegvesen.no/dokumentasjon/openapi/#/Vegnett/get_beta_vegnett_rute

"""
    nvdb_request(url_ext::String, method::String= "GET"; 
                    Dict{Symbol, Any}(), logstate = LOGSTATE)
     --> JSON3.Object{Base.CodeUnits{UInt8, String}, Vector{UInt64}}

Access the nvdb Web API. This is called by every function 
in `endpoints.jl`.

Error results return an empty response object, while errors are written to 'stderr' / `stdout`.
"""
function nvdb_request(url_ext::String, method::String = "GET"; body::Dict{Symbol, Any} = Dict{Symbol, Any}(),
    logstate = LOGSTATE)
    #
    sbody = String(JSON3.write(body))
    # Not so cool, but this is how we get rid of spaces in vectors of strings:
    url_ext = replace(url_ext, ' ' => "")
    url = "$BASEURL$url_ext"
    idfields = get_nvdb_fields(sbody)
    # A template in case we don't get a response from HTTP.
    resp = HTTP.Messages.Response()
    try
        if method == "GET"
            resp = HTTP.request(method, url, idfields)
        elseif method == "POST" || method == "PUT" || method == "DELETE"
            resp = HTTP.request(method, url, idfields, sbody)
        else
            throw("unexpected method")
        end
        # Since execution did not skip to 'catch', this request was OK. Log the successfull request.
        request_to_stdout(method, url, sbody, idfields, logstate, true)
    catch e
        error_logstate = Logstate(logstate.authorization, true, logstate.empty_response)
        request_to_stdout(method, url, sbody, idfields, error_logstate, false)
        if  e isa HTTP.ExceptionRequest.StatusError && e.status ∈ keys(RESP_DIC) #[400, 401, 403, 404, 422, 429]
            response_body = e.response.body |> String
            code_meaning = get(RESP_DIC, Int(e.status), "")
            if response_body != ""
                try 
                    response_object = JSON3.read(response_body)
                    iob = IOBuffer()
                    JSON3.pretty(iob, response_object)
                    msg = String(take!(iob))
                catch err
                    # (Some) bad requests return invalid json.
                    msg = response_body
                end
            else
                msg = "$(e.status): $code_meaning"
            end
            if e.status == 400 
                @info msg
                return JSON3.Object()
            elseif e.status == 403
                @info msg
                printstyled("  This message may have been triggered by insufficient identification.\n", color = :red)
                logstate.authorization && printstyled("               id fields: ", idfields, "\n", color = :red)
                return JSON3.Object()
            elseif e.status == 404 # Not found.
                response_object = JSON3.read(response_body)
                if response_object[1].code == 4012
                    @warn response_object[1]
                    return JSON3.Object()
                else
                    @info msg
                    return JSON3.Object()
                end
            elseif e.status == 405
                @info msg 
                return JSON3.Object()
            elseif e.status == 422 
                @info msg
                printstyled(" (status code:) $(e.status) (meaning:) $code_meaning ",  "\n", color = :red)
                return JSON3.Object()
            elseif e.status == 429 # API rate limit temporarily exceeded.
                @info msg
                retry_in_seconds =  HTTP.header(e.response, "retry-after")
                @warn retry_in_seconds 
                return JSON3.Object()
            elseif e.status == 500
                @info msg 
                printstyled(" (status code:) $(e.status) (meaning:) $code_meaning ",  "\n", color = :red)
                return JSON3.Object()
            else # 401 probably
                @info msg
                @warn "Error code $(e.status)."
                return JSON3.Object()
            end
        else
            msg = "HTTP.request call (unexpected error): method = $method\n header with identification fields = $idfields \n $url_ext"
            @warn msg
            if e isa HTTP.Exceptions.ConnectError
                @error string(e.url)
                @error string(e.error)
                return JSON3.Object()
            elseif e isa HTTP.RequestError
                @error string(e.error)
                return JSON3.Object()
            else
                response_body = e.response.body |> String
                code_meaning = "?"
                msg = "$(e.status): $code_meaning"
                @error msg
                @error string(e)
                return JSON3.Object()
            end
        end
    end
    response_body = resp.body |> String
    if method == "PUT" || method == "DELETE"
        if response_body == "" && resp.status ∈ [200, 201, 202, 203, 204]
            return JSON3.Object()
        elseif resp.status ∈ [200, 201, 202, 203, 204]
            @warn JSON3.read(response_body)
            return JSON3.Object()
        else
            code_meaning = get(RESP_DIC, Int(resp.status), "")
            msg = "$(resp.status): $code_meaning"
            @info msg
            return JSON3.Object()
        end
    else
        if resp.status == 204
            if logstate.empty_response
                code_meaning = get(RESP_DIC, Int(resp.status), "")
                msg = "$(resp.status): $code_meaning"
                @info msg
            end
            return JSON3.Object()
        else
            obj = JSON3.read(response_body)
            # If it's an array, wrap it.
            if isa(obj, JSON3.Object)
                obj
            elseif isa(obj, JSON3.Array)
                msg = "Unexpected return type: An array of JSON3 objects. Please make the request directly without going through nvdb_request:\n"
                if method == "GET"
                    msg *= "resp = HTTP.request(\"GET\", url, idfields);\n"
                    msg *= "where url = \"$url\"\n"
                    msg *= "and idfields = $idfields\n"
                    msg *= "oarr = JSON3.read(resp.body)"
                    @warn msg
                    return JSON3.Object() 
                else
                    msg *= "resp = HTTP.request($method, $url, $idfields, $sbody);\n"
                    msg *= "oarr = JSON3.read(resp.body)"
                    @warn msg
                    return JSON3.Object() 
                end
            else
                msg = "Unexpected return type: $(typeof(obj))"
                throw(ErrorException(msg))
            end
        end
    end
end


"""
    request_to_stdout(method, url, body, idfields, logstate, no_mistake)

Print a request after it is made.
"""
function request_to_stdout(method, url, body, idfields, logstate, no_mistake)
    if no_mistake
        color = :light_black
    else
        color = :red
    end
    if logstate.request_string
        if body == ""
            printstyled("     ", method, " ", url, "\n"; color)
        else
            printstyled("     ", method, " ", url, "   \\", body, "\n"; color)
        end
    end
    # We want to be able to reuse console output for examples, so hiding confidential output is a choice:
    if logstate.authorization
        printstyled("               identification fields: ", idfields, "\n"; color)
    end
end