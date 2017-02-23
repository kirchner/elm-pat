module Main exposing (main)

-- external

import Dict
import Html exposing (Html)
import Material
import Task
import Window


-- internal

import Model
    exposing
        ( Msg(Mdl, UpdateWindowSize)
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
    let
        windowSizeInit =
            Task.perform UpdateWindowSize Window.size

        mdlInit =
            Material.init Mdl
    in
        ( defaultModel, Cmd.batch [ windowSizeInit, mdlInit ] )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Window.resizes UpdateWindowSize
        , Material.subscriptions Mdl model
        ]
