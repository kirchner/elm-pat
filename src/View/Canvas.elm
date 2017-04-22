module View.Canvas exposing (view)

import Dict
import Html exposing (Html)
import Html.Attributes as Html
import Math.Vector2 exposing (..)
import Svg exposing (Svg)
import Svg.Attributes as Svg


{- internal -}

import Events
import View.Colors as Colors
import Svg.Extra as Svg
import Types exposing (..)


view : (Position -> msg) -> (Position -> msg) -> Svg msg -> Position -> PointStore -> Html msg
view clickCallback moveCallback tool center store =
    let
        viewBoxString =
            String.concat
                [ toString center.x
                , " "
                , toString center.y
                , " 640 640"
                ]
    in
        Svg.svg
            [ Svg.viewBox viewBoxString
            , Html.style
                [ ( "background-color", Colors.base3 )
                , ( "width", "640" )
                , ( "height", "640" )
                ]
            ]
            [ origin
            , Svg.g [] (points store)
            , tool
            , Svg.rect
                [ Svg.x (toString center.x)
                , Svg.y (toString center.y)
                , Svg.width "640"
                , Svg.height "640"
                , Svg.fill "transparent"
                , Svg.strokeWidth "0"
                , Events.onClick clickCallback
                , Events.onMove moveCallback
                ]
                []
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
