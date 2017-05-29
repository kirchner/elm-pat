module View.Canvas exposing (view)

import Dict exposing (..)
import Events
import Expr exposing (..)
import Html exposing (Html)
import Html.Attributes as Html
import Math.Vector2 exposing (..)
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg
import Svg.Extra as Svg
import Types exposing (..)
import View.Colors as Colors


view : Svg msg -> ViewPort -> PointStore -> Dict String E -> Html msg
view tool viewPort store variables =
    let
        viewBoxString =
            String.join " "
                [ toString viewPort.x
                , toString viewPort.y
                , toString viewPort.width
                , toString viewPort.height
                ]
    in
    Svg.svg
        [ Svg.viewBox viewBoxString
        , Html.style
            [ ( "background-color", Colors.base3 )
            , ( "width", toString viewPort.width )
            , ( "height", toString viewPort.height )
            ]
        ]
        [ origin
        , Svg.g [] (points store variables)
        , tool
        ]


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


points : PointStore -> Dict String E -> List (Svg msg)
points store variables =
    Dict.values store
        |> List.filterMap (point store variables)


point : PointStore -> Dict String E -> Point -> Maybe (Svg msg)
point store variables point =
    case point of
        Absolute _ _ ->
            position store variables point
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
                (positionById store variables id)
                (position store variables point)

        Between idA idB _ ->
            Just (Svg.g [] [])
