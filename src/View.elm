module View exposing (view)

-- external

import Dict exposing (Dict)
import Json.Decode as Json
import Html exposing (Html)
import Html.Events as Events
import Html.Attributes as Html
import Math.Vector2 exposing (..)
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg


-- internal

import Model exposing (..)
import Point exposing (..)
import Tools


view : Model -> Html Msg
view model =
    Html.div
        []
        [ viewPattern model
        , viewInfoBox model
        , viewToolBox model
        ]



-- info box


viewInfoBox : Model -> Html Msg
viewInfoBox model =
    case
        model.focusedPointId
            |> Maybe.andThen (flip Dict.get model.points)
    of
        Just point ->
            case point of
                Origin info ->
                    Html.div []
                        [ Html.text "origin: "
                        , Html.text <| toString info
                        ]

                ADPoint info ->
                    Html.div []
                        [ Html.text "ad point: "
                        , Html.text <| toString info
                        ]

                DDPoint info ->
                    Html.div []
                        [ Html.text "dd point: "
                        , Html.text <| toString info
                        ]

        Nothing ->
            Html.div [] []



-- tool box


viewToolBox : Model -> Html Msg
viewToolBox model =
    case model.selectedTool of
        Just tool ->
            -- TODO view tool info
            Html.div [] []

        Nothing ->
            Html.div []
                [ Html.button
                    [ Events.onClick <| InitTool Tools.pointFromOriginTool ]
                    [ Html.text "add origin" ]
                , Html.button
                    [ Events.onClick <| InitTool <| Tools.pointFromDDPointTool model.points ]
                    [ Html.text "add dd point" ]
                , Html.button
                    [ Events.onClick <| InitTool <| Tools.pointFromADPointTool model.points ]
                    [ Html.text "add ad point" ]
                ]


viewPattern : Model -> Html Msg
viewPattern model =
    let
        width =
            toFloat <| model.windowSize.width - 50

        height =
            toFloat <| model.windowSize.height - 50

        viewBoxString =
            List.foldl (\x str -> str ++ " " ++ toString x)
                ""
                [ getX model.offset
                , getY model.offset
                , width
                , height
                ]
    in
        Svg.svg
            [ Svg.width <| toString width
            , Svg.height <| toString height
            , Svg.viewBox viewBoxString
            ]
            [ drawFocus model
            , drawSelection model
            , drawGuideLines model
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
            , eventRect model
            , drawPoints model
            ]


eventRect : Model -> Svg Msg
eventRect model =
    let
        widthString =
            toString (model.windowSize.width - 50)

        heightString =
            toString (model.windowSize.height - 50)

        offsetPosition =
            Json.map2 positionToVec
                (Json.field "offsetX" Json.int)
                (Json.field "offsetY" Json.int)

        positionToVec x y =
            add model.offset <| vec2 (toFloat x) (toFloat y)
    in
        Svg.g
            []
            [ Svg.rect
                [ Svg.x "-320"
                , Svg.y "-200"
                , Svg.width widthString
                , Svg.height heightString
                , Svg.fill "transparent"
                , Svg.on "click"
                    (Json.map
                        (\pos -> DoStep (Tools.InputPosition pos))
                        offsetPosition
                    )
                ]
                []
            ]



-- draw points


drawPoints : Model -> Svg Msg
drawPoints model =
    Svg.g [] <|
        List.filterMap
            (drawPoint model.points)
            (Dict.keys model.points)


drawPoint : Dict PointId Point -> PointId -> Maybe (Svg Msg)
drawPoint points id =
    let
        draw v =
            Svg.g
                []
                [ Svg.circle
                    [ Svg.cx <| toString <| getX v
                    , Svg.cy <| toString <| getY v
                    , Svg.r "2"
                    , Svg.fill "black"
                    ]
                    []
                , eventCircle v id
                ]
    in
        Maybe.map draw <| position points id


eventCircle : Vec2 -> PointId -> Svg Msg
eventCircle position id =
    let
        ( x, y ) =
            toTuple <| position
    in
        Svg.g
            []
            [ Svg.circle
                [ Svg.cx <| toString x
                , Svg.cy <| toString y
                , Svg.r "8"
                , Svg.fill "transparent"
                , Svg.onMouseOver (FocusPoint id)
                , Svg.onMouseOut (UnFocusPoint id)
                , Svg.onClick (DoStep (Tools.SelectPoint id))
                ]
                []
            ]



-- draw guide lines


drawGuideLines : Model -> Svg Msg
drawGuideLines model =
    Svg.g [] <|
        List.filterMap
            (drawGuideLine model.points)
            (Dict.keys model.points)


drawGuideLine : Dict PointId Point -> PointId -> Maybe (Svg Msg)
drawGuideLine points id =
    case Dict.get id points of
        Just (Origin _) ->
            Nothing

        Just (ADPoint info) ->
            let
                pointPosition =
                    position points id

                anchorPosition =
                    position points info.anchor
            in
                Maybe.map2
                    drawADGuideLines
                    anchorPosition
                    pointPosition

        Just (DDPoint info) ->
            let
                pointPosition =
                    position points id

                anchorPosition =
                    position points info.anchor
            in
                Maybe.map2
                    drawDDGuideLines
                    anchorPosition
                    pointPosition

        _ ->
            Nothing


drawDDGuideLines : Vec2 -> Vec2 -> Svg Msg
drawDDGuideLines anchor point =
    let
        ( ax, ay ) =
            toTuple anchor

        ( x, y ) =
            toTuple point
    in
        Svg.g []
            [ Svg.line
                [ Svg.x1 <| toString ax
                , Svg.y1 <| toString ay
                , Svg.x2 <| toString x
                , Svg.y2 <| toString ay
                , Svg.strokeDasharray "5, 10"
                , Svg.strokeWidth "1"
                , Svg.stroke "black"
                ]
                []
            , Svg.text_
                [ Svg.x <| toString (0.5 * (x + ax))
                , Svg.y <| toString (ay + 11)
                , Svg.fontSize "10"
                , Svg.textAnchor "middle"
                ]
                [ Svg.text <| toString (x - ax) ]
            , Svg.line
                [ Svg.x1 <| toString x
                , Svg.y1 <| toString ay
                , Svg.x2 <| toString x
                , Svg.y2 <| toString y
                , Svg.strokeDasharray "5, 10"
                , Svg.strokeWidth "1"
                , Svg.stroke "black"
                ]
                []
            , Svg.text_
                [ Svg.x <| toString (x + 3)
                , Svg.y <| toString (0.5 * (y + ay))
                , Svg.fontSize "10"
                , Svg.textAnchor "start"
                ]
                [ Svg.text <| toString (y - ay) ]
            ]


drawADGuideLines : Vec2 -> Vec2 -> Svg Msg
drawADGuideLines anchor point =
    let
        ( ax, ay ) =
            toTuple anchor

        ( x, y ) =
            toTuple point
    in
        Svg.g []
            [ Svg.line
                [ Svg.x1 <| toString ax
                , Svg.y1 <| toString ay
                , Svg.x2 <| toString x
                , Svg.y2 <| toString y
                , Svg.strokeDasharray "5, 10"
                , Svg.strokeWidth "1"
                , Svg.stroke "black"
                ]
                []
            ]



-- draw focus


drawFocus : Model -> Svg Msg
drawFocus model =
    case model.focusedPointId |> Maybe.andThen (position model.points) of
        Just v ->
            Svg.circle
                [ Svg.cx <| toString <| getX v
                , Svg.cy <| toString <| getY v
                , Svg.r "8"
                , Svg.fill "none"
                , Svg.stroke "green"
                , Svg.strokeWidth "1"
                ]
                []

        Nothing ->
            Svg.g [] []



-- draw selection


drawSelection : Model -> Svg Msg
drawSelection model =
    Svg.g [] <|
        List.map (drawSelectionCircle model.points) model.selectedPoints


drawSelectionCircle : Dict PointId Point -> PointId -> Svg Msg
drawSelectionCircle points id =
    case position points id of
        Just v ->
            Svg.circle
                [ Svg.cx <| toString <| getX v
                , Svg.cy <| toString <| getY v
                , Svg.r "8"
                , Svg.fill "none"
                , Svg.stroke "red"
                , Svg.strokeWidth "1"
                ]
                []

        Nothing ->
            Svg.g [] []
