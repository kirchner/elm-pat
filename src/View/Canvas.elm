module View.Canvas exposing (view)

import Dict
import Html exposing (Html)
import Html.Attributes as Html
import Math.Vector2 exposing (..)
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg


{- internal -}

import Events
import View.Colors as Colors
import Svg.Extra as Svg
import Types exposing (..)


view : Svg msg -> ViewPort -> PointStore -> Html msg
view tool viewPort store =
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
            , Svg.g [] (points store)
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


points : PointStore -> List (Svg msg)
points store =
    Dict.values store
        |> List.filterMap (point store)


point : PointStore -> Point -> Maybe (Svg msg)
point store point =
    position store point
        |> Maybe.map Svg.drawPoint
