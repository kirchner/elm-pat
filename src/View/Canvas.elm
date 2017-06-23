module View.Canvas exposing (view)

import Dict exposing (..)
import Events
import Expr exposing (..)
import Html exposing (Html)
import Html.Attributes as Html
import Math.Vector2 exposing (..)
import Styles.Colors as Colors
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg
import Svg.Extra as Svg
import Tools.Common
    exposing
        ( Data
        , svgSelectPoint
        )
import Types exposing (..)


view :
    Svg msg
    -> (Position -> msg)
    -> (Maybe Id -> msg)
    -> (Maybe Id -> msg)
    -> Data
    -> Html msg
view tool startDrag focusPoint selectPoint data =
    let
        viewBoxString =
            String.join " "
                [ toString data.viewPort.x
                , toString data.viewPort.y
                , toString data.viewPort.width
                , toString data.viewPort.height
                ]
    in
    Svg.svg
        [ Svg.viewBox viewBoxString
        , Html.style
            [ ( "background-color", Colors.base3 )
            , ( "width", toString data.viewPort.width )
            , ( "height", toString data.viewPort.height )
            ]
        ]
        [ origin
        , Svg.g [] (points data)
        , viewSelectedPoints data
        , dragArea startDrag data.viewPort
        , svgSelectPoint focusPoint selectPoint data
        , tool
        ]


dragArea : (Position -> msg) -> ViewPort -> Svg msg
dragArea startDrag viewPort =
    Svg.rect
        [ Svg.x (toString viewPort.x)
        , Svg.y (toString viewPort.y)
        , Svg.width (toString viewPort.width)
        , Svg.height (toString viewPort.height)
        , Svg.fill "transparent"
        , Svg.strokeWidth "0"
        , Events.onMouseDown startDrag
        ]
        []


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


origin : Svg msg
origin =
    Svg.g []
        [ Svg.line
            [ Svg.x1 "-10"
            , Svg.y1 "0"
            , Svg.x2 "10"
            , Svg.y2 "0"
            , Svg.stroke Colors.green
            , Svg.strokeWidth "1"
            ]
            []
        , Svg.line
            [ Svg.x1 "0"
            , Svg.y1 "-10"
            , Svg.x2 "0"
            , Svg.y2 "10"
            , Svg.stroke Colors.green
            , Svg.strokeWidth "1"
            ]
            []
        ]


points : Data -> List (Svg msg)
points data =
    Dict.values data.store
        |> List.filterMap (point data)


point : Data -> Point -> Maybe (Svg msg)
point data point =
    case point of
        Absolute _ _ ->
            position data.store data.variables point
                |> Maybe.map Svg.drawPoint

        Relative id _ _ ->
            let
                draw v w =
                    Svg.g []
                        [ Svg.drawPoint w
                        , Svg.drawRectArrow v w
                        ]
            in
            Maybe.map2
                draw
                (positionById data.store data.variables id)
                (position data.store data.variables point)

        Distance id _ _ ->
            let
                draw v w =
                    Svg.g []
                        [ Svg.drawPoint w
                        , Svg.drawArrow v w
                        ]
            in
            Maybe.map2
                draw
                (positionById data.store data.variables id)
                (position data.store data.variables point)

        Between idA idB _ ->
            Just (Svg.g [] [])
