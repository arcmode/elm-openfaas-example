port module Function exposing (..)

import Task
import Dict exposing (Dict)
import Http.Parser exposing (request, expect, json, mapResult)


port input : (String -> msg) -> Sub msg


port output : String -> Cmd msg


type Msg
    = Input String
    | Output String


type alias Request body =
    { method : String
    , uri : String
    , headers : Dict String String
    , body : body
    }


type alias Response body =
    { status : Int
    , headers : Dict String String
    , body : body
    }


program :
    { parse : String -> c
    , handle : c -> Task.Task x a1
    , encode : Result x a1 -> String
    }
    -> Program Never (Maybe b) Msg
program { parse, encode, handle } =
    let
        update msg model =
            case msg of
                Input string ->
                    let
                        eff =
                            parse string
                                |> handle
                                |> Task.attempt (encode >> Output)
                    in
                        ( model, eff )

                Output response ->
                    ( model, output response )
    in
        Platform.program
            { init = ( Nothing, Cmd.none )
            , update = update
            , subscriptions = always <| input Input
            }
