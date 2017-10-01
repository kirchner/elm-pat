module Views.Tool exposing (..)

import Data.Point exposing (Point)
import Html exposing (Html)
import Html.Attributes as Attributes
import Tools.Callbacks exposing (Callbacks)
import Tools.Data exposing (Data)
import Views.Common as Common


view :
    Callbacks msg
    -> Data
    -> state
    -> (Data -> state -> Maybe Point)
    -> List (Html m)
    -> Html m
view callbacks data state point elements =
    let
        addPoint =
            point data state |> Maybe.map callbacks.addPoint

        button =
            case addPoint of
                Just callback ->
                    [ Common.iconSmall "add" callback ]

                Nothing ->
                    []
    in
    Html.div
        [ Attributes.class "tool__tool-box" ]
        elements
