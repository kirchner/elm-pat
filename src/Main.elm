module Main exposing (..)

-- external

import Dict
import Html exposing (Html)
import Task
import Window


-- internal

import Events
import Model exposing (..)
import Point exposing (..)
import Tool exposing (..)
import View exposing (..)


-- MAIN


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


init : ( Model, Cmd Msg )
init =
    ( defaultModel, Task.perform UpdateWindowSize Window.size )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Window.resizes UpdateWindowSize
        ]
