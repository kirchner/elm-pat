module Main exposing (main)

-- external

import Dict
import Html exposing (Html)
import Task
import Window


-- internal

import Model
    exposing
        ( Msg(UpdateWindowSize)
        , Model
        , defaultModel
        )
import Update exposing (update)
import View exposing (view)


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
