module Main exposing (..)

-- Encoding/Decoding utilities

import Dict exposing (Dict)
import Json.Encode as Encode
import Json.Decode.Extra exposing ((|:))
import Json.Decode as Decode exposing (field)
import Http.Encode exposing (Response, response)
import Http.Parser exposing (Request, request, expect, json, mapResult)


-- OpenFaas boilerplate including ports for IO

import Function


-- Middleware abstraction around Task

import Task
import Task.Middleware
    exposing
        ( Middleware
        , Error(..)
        , connect
        , middleware
        , mapError
        )


-- Middleware units used in this particular function

import Middleware.User as User exposing (User, getUser, encodeUser)
import Middleware.Favorite as Favorite exposing (Favorite, getFavorite, encodeFavorite)


-- How this function's responses look like


type alias ResponseBody =
    { user : User
    , favorite : Favorite
    }



-- How this function expect bodies to look like


type alias RequestBody =
    { state : String
    }



-- What our function errors are about


type Error
    = User User.Error
    | Favorite Favorite.Error
    | BadRequest Http.Parser.Error



-- State where our middleware units are going to deliver


type alias State =
    { user : User
    , favorite : Favorite
    }



-- Request Body decoder


body : Decode.Decoder RequestBody
body =
    Decode.succeed RequestBody
        |: (field "state" Decode.string)



-- Response as Error


onError err =
    { status = 500
    , headers = Dict.empty
    , body = Encode.string <| toString err
    }



-- Response as Success


onSuccess : ( State, Request RequestBody ) -> Response Encode.Value
onSuccess ( state, req ) =
    { status = 200
    , headers =
        Dict.fromList
            [ ( "X-Powered-By", "Elm |> OpenFaas |> k8s" )
            , ( "Content-Type", "application/json" )
            ]
    , body =
        Encode.object
            [ ( "user", encodeUser state.user )
            , ( "favorite", encodeFavorite state.favorite )
            ]
    }



-- Faas Program


type alias Flags =
    { home : String }


type alias Model =
    { flags : Flags
    }


fromResult : (x -> b) -> (a -> b) -> Result x a -> b
fromResult onError onSuccess result =
    case result of
        Ok res ->
            onSuccess res

        Err err ->
            onError err


mapResult : (x -> y) -> (a -> b) -> Result x a -> Result y b
mapResult err ok =
    Result.mapError err >> Result.map ok


toTask : Result x a -> Task.Task x a
toTask result =
    case result of
        Ok payload ->
            Task.succeed payload

        Err err ->
            Task.fail err


main : Program Never (Maybe a) Function.Msg
main =
    Function.program
        { parse =
            request
                >> expect (json body)
                >> mapResult BadRequest
                    ((,)
                        { user = User.state
                        , favorite = Favorite.state
                        }
                    )
        , handle =
            \result ->
                toTask result
                    |> connect
                        (middleware
                            [ getFavorite |> mapError Favorite
                            , getUser |> mapError User
                            ]
                        )
        , encode =
            fromResult
                (onError >> Http.Encode.json)
                (onSuccess >> Http.Encode.json)
        }
