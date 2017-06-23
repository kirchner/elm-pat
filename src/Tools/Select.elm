module Tools.Select exposing (..)

import Dict exposing (Dict)
import Keyboard.Extra as Keyboard
import Set exposing (Set)
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg
import Svg.Extra as Svg
import Tools.Common as Tools
    exposing
        ( Callbacks
        , Data
        , svgSelectPoint
        , viewPointSelect
        )
import Types exposing (..)


{- svg -}


svg : Callbacks msg -> Data -> Svg msg
svg callbacks data =
    Svg.g []
        [ viewSelectedPoints data
        , svgClearSelection callbacks.clearSelection data
        , svgSelectPoint callbacks.focusPoint callbacks.selectPoint data
        ]


viewSelectedPoints : Data -> Svg msg
viewSelectedPoints data =
    data.selectedPoints
        |> List.filterMap (viewSelectedPoint data)
        |> Svg.g []


viewSelectedPoint : Data -> Id -> Maybe (Svg msg)
viewSelectedPoint data id =
    let
        pointPosition =
            Dict.get id data.store
                |> Maybe.andThen (position data.store data.variables)
    in
    case pointPosition of
        Just position ->
            Just <|
                Svg.g []
                    [ Svg.drawPoint position
                    , Svg.drawSelector position
                    ]

        Nothing ->
            Nothing


svgClearSelection : msg -> Data -> Svg msg
svgClearSelection clearSelection data =
    Svg.rect
        [ Svg.x (toString data.viewPort.x)
        , Svg.y (toString data.viewPort.y)
        , Svg.width (toString data.viewPort.width)
        , Svg.height (toString data.viewPort.height)
        , Svg.fill "transparent"
        , Svg.strokeWidth "0"
        , Svg.onClick clearSelection
        ]
        []
