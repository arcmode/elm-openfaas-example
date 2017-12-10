module Middleware.Favorite exposing (..)

import Task.Middleware exposing (Middleware, next, end)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Task


type Error
    = Http Http.Error


type alias Favorite =
    String


state =
    ""


getFavorite ( state, req ) =
    let
        getFavoriteData =
            Http.get "http://swapi.co/api/people/1/" decodeName
                |> Http.toTask

        decodeName =
            Decode.at [ "name" ] Decode.string

        onSuccess name =
            ( { state | favorite = name }, req )
    in
        Task.map onSuccess getFavoriteData
            |> Task.mapError Http
            |> next


encodeFavorite : String -> Encode.Value
encodeFavorite fav =
    Encode.string fav
