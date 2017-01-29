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



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        UpdateWindowSize newSize ->
            { model
                | windowSize = newSize
            }
                ! []

        AddOrigin info ->
            { model
                | points = Dict.insert model.pointId (Origin info) model.points
                , pointId = nextId model.pointId
            }
                ! []

        FocusPoint id ->
            { model
                | focusedPointId = Just id
            }
                ! []

        UnFocusPoint id ->
            if model.focusedPointId == (Just id) then
                { model
                    | focusedPointId = Nothing
                }
                    ! []
            else
                model ! []
