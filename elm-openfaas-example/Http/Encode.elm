module Http.Encode exposing (Response, response, json)

import Json.Encode as Encode
import Dict exposing (Dict)


newLine =
    "\x0D\n"


singleSpace =
    " "


json =
    response <| Encode.encode 4


type alias Response body =
    { body : body, status : Int, headers : Dict String String }


response :
    (e -> String)
    -> Response e
    -> String
response encode res =
    let
        responseBody =
            encode res.body

        contentLength =
            String.length responseBody
                |> toString

        headersDict =
            Dict.insert "Content-Length" contentLength res.headers

        headersString =
            Dict.toList headersDict
                |> List.map (\( k, v ) -> k ++ ": " ++ v)
                |> String.join newLine

        status =
            toString res.status

        statusMessage =
            "STATUS CODE " ++ status

        version =
            "HTTP/1.1 "
    in
        version
            ++ status
            ++ singleSpace
            ++ statusMessage
            ++ newLine
            ++ headersString
            ++ newLine
            ++ newLine
            ++ responseBody
