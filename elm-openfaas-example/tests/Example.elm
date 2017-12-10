module Example exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import Parser
import Json.Decode as Decode
import Json.Decode.Extra exposing ((|:))
import Json.Encode as Encode
import Http.Parser
import Http.Encode
import Dict


type alias Body =
    { state : String
    }


bodyDecoder =
    Decode.succeed Body
        |: (Decode.field "state" Decode.string)


ex1 =
    { title = "Parses method, headers and body with multiline string"
    , result =
        let
            req =
                """POST /api?hola=mundo%20foo%20bar HTTP/1.1
Host: localhost:8080
User-Agent: curl/7.54.0
Content-Length: 13
Accept: */*
Content-Type: application/json

{"state": ""}"""
        in
            Http.Parser.request req |> Http.Parser.andThen (Http.Parser.json bodyDecoder)
    , expected =
        Ok
            { method = "POST"
            , uri = "/api?hola=mundo%20foo%20bar"
            , headers =
                Dict.fromList
                    [ ( "Host", "localhost:8080" )
                    , ( "User-Agent", "curl/7.54.0" )
                    , ( "Content-Length", "13" )
                    , ( "Accept", "*/*" )
                    , ( "Content-Type", "application/json" )
                    ]
            , body = { state = "" }
            }
    }


ex2 =
    { title = "Parses method, headers and body with normal string"
    , result =
        let
            req =
                "POST /api?hola=mundo%20foo%20bar HTTP/1.1\x0D\nHost: localhost:8080\x0D\nUser-Agent: curl/7.54.0\x0D\nContent-Length: 13\x0D\nAccept: */*\x0D\nContent-Type: application/json\x0D\n\x0D\n{\"state\": \"\"}"
        in
            Http.Parser.request req |> Http.Parser.andThen (Http.Parser.json bodyDecoder)
    , expected =
        Ok
            { method = "POST"
            , uri = "/api?hola=mundo%20foo%20bar"
            , headers =
                Dict.fromList
                    [ ( "Host", "localhost:8080" )
                    , ( "User-Agent", "curl/7.54.0" )
                    , ( "Content-Length", "13" )
                    , ( "Accept", "*/*" )
                    , ( "Content-Type", "application/json" )
                    ]
            , body = { state = "" }
            }
    }


ex3 =
    { title = "fails if request is longer than expected from content-length's header value"
    , result =
        let
            req =
                """POST /api?hola=mundo%20foo%20bar HTTP/1.1
Host: localhost:8080
User-Agent: curl/7.54.0
Content-Length: 13
Accept: */*
Content-Type: application/x-www-form-urlencoded

{"state": ""}this is not part of the request body"""
        in
            Http.Parser.request req |> Http.Parser.andThen (Http.Parser.json bodyDecoder)
    , expected =
        Err <|
            Http.Parser.ParserError
                { row = 8
                , col = 14
                , source =
                    "POST /api?hola=mundo%20foo%20bar HTTP/1.1\nHost: localhost:8080\nUser-Agent: curl/7.54.0\nContent-Length: 13\nAccept: */*\nContent-Type: application/x-www-form-urlencoded\n\n{\"state\": \"\"}this is not part of the request body"
                , problem = Parser.ExpectingEnd
                , context = []
                }
    }


parserExamples =
    [ ex1
    , ex2
    , ex3
    ]


encodeExamples =
    [ { title = "Encode response"
      , expected = "HTTP/1.1 200 STATUS CODE 200\x0D\nContent-Length: 13\x0D\nfoo: bar\x0D\n\x0D\n\"hello world\""
      , result = Http.Encode.response Encode.string { body = "hello world", status = 200, headers = Dict.fromList [ ( "foo", "bar" ) ] }
      }
    ]


buildTest { title, result, expected } =
    test title (\_ -> Expect.equal expected result)


suite : Test
suite =
    describe "Http <-> String" <|
        [ describe "Http parser" <|
            List.map buildTest parserExamples
        , describe "Http encoder" <|
            List.map buildTest encodeExamples
        ]
