module Middleware.User exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode exposing (field)
import Json.Decode.Extra exposing ((|:))
import Task
import Task.Middleware exposing (Middleware, next, end)
import Http


type alias User =
    { id : Int
    , first_name : String
    , last_name : String
    , avatar : String
    }


state : User
state =
    { id = 0
    , first_name = ""
    , last_name = ""
    , avatar = ""
    }


encodeUser : User -> Encode.Value
encodeUser user =
    Encode.object
        [ ( "id", Encode.int user.id )
        , ( "first_name", Encode.string user.first_name )
        , ( "last_name", Encode.string user.last_name )
        , ( "avatar", Encode.string user.avatar )
        ]


type Error
    = Http Http.Error


getUser ( state, req ) =
    let
        getUserData =
            Http.get "https://reqres.in/api/users/2" decodeUserData
                |> Http.toTask

        decodeUserData =
            Decode.at [ "data" ] <|
                Decode.succeed User
                    |: (field "id" Decode.int)
                    |: (field "first_name" Decode.string)
                    |: (field "last_name" Decode.string)
                    |: (field "avatar" Decode.string)

        onSuccess userData =
            ( { state | user = userData }, req )
    in
        Task.map onSuccess getUserData
            |> Task.mapError Http
            |> end
