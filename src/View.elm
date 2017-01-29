module View exposing (view)

-- external

import Dict exposing (Dict)
import Html exposing (Html)
import Math.Vector2 exposing (..)
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg


-- internal

import Events
import Model exposing (..)
import Point exposing (..)


view : Model -> Html Msg
view model =
    Html.div
        []
        [ viewPattern model
        ]


viewPattern : Model -> Html Msg
viewPattern model =
    let
        widthString =
            toString (model.windowSize.width - 50)

        heightString =
            toString (model.windowSize.height - 50)

        viewBoxString =
            "-320 -200 " ++ widthString ++ " " ++ heightString
    in
        Svg.svg
            [ Svg.width widthString
            , Svg.height heightString
            , Svg.viewBox viewBoxString
            ]
            [ drawFocus model
            , drawPoints model.points
            , Svg.line
                [ Svg.x1 "-10"
                , Svg.y1 "0"
                , Svg.x2 "10"
                , Svg.y2 "0"
                , Svg.stroke "green"
                , Svg.strokeWidth "1"
                ]
                []
            , Svg.line
                [ Svg.x1 "0"
                , Svg.y1 "-10"
                , Svg.x2 "0"
                , Svg.y2 "10"
                , Svg.stroke "green"
                , Svg.strokeWidth "1"
                ]
                []
            ]


drawPoints : Dict PointId Point -> Svg Msg
drawPoints points =
    Svg.g [] <|
        List.map drawPoint <|
            Dict.toList points


drawPoint : ( PointId, Point ) -> Svg Msg
drawPoint ( id, point ) =
    let
        ( x, y ) =
            toTuple <| position point
    in
        Svg.g
            []
            [ Svg.circle
                [ Svg.cx <| toString x
                , Svg.cy <| toString y
                , Svg.r "2"
                , Svg.fill "black"
                ]
                []
            , Svg.circle
                [ Svg.cx <| toString x
                , Svg.cy <| toString y
                , Svg.r "8"
                , Svg.fill "transparent"
                , Svg.onMouseOver (FocusPoint id)
                , Svg.onMouseOut (UnFocusPoint id)
                ]
                []
            ]


drawFocus : Model -> Svg Msg
drawFocus model =
    case model.focusedPointId of
        Just id ->
            case Dict.get id model.points of
                Just point ->
                    let
                        ( x, y ) =
                            toTuple <| position point
                    in
                        Svg.circle
                            [ Svg.cx <| toString x
                            , Svg.cy <| toString y
                            , Svg.r "8"
                            , Svg.fill "none"
                            , Svg.stroke "green"
                            , Svg.strokeWidth "1"
                            ]
                            []

                Nothing ->
                    Svg.g [] []

        Nothing ->
            Svg.g [] []
