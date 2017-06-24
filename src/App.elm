port module App exposing (main)

import Html exposing (Html)


{- internal -}

import Model exposing (Model)
import Editor
    exposing
        ( Msg
        , Flags
        , init
        , update
        , subscriptions
        )
import View exposing (view)
import Json.Decode exposing (Value)


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update ports
        , subscriptions = subscriptions
        , view = view
        }


ports =
    { autofocus = autofocus
    , serialize = serialize
    }


port autofocus : () -> Cmd msg

port serialize : Value -> Cmd msg
