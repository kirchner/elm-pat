port module App exposing (main)

{- internal -}

import Editor
    exposing
        ( Flags
        , Msg
        , Ports
        , init
        , subscriptions
        , update
        )
import Html exposing (Html)
import Json.Decode exposing (Value)
import Model exposing (Model)
import View exposing (view)


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update ports
        , subscriptions = subscriptions
        , view = view
        }


ports : Ports
ports =
    { autofocus = autofocus
    , serialize = serialize
    }


port autofocus : () -> Cmd msg


port serialize : Value -> Cmd msg
