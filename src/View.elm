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
import Tool exposing (..)


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
    if List.isEmpty model.agenda then
        Html.div [] <|
            List.map viewToolButton allTools
    else
        Html.div [] <|
            List.map viewStepInfo model.agenda


viewToolButton : Tool -> Html Msg
viewToolButton tool =
    Html.button
        [ Events.onClick <| InitTool tool ]
        [ Html.text <| toolInfoText tool ]


viewStepInfo : Step -> Html Msg
viewStepInfo step =
    Html.text <| stepInfoText step



-- pattern


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
            , drawPoints model
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
            ]


eventRect : Model -> Svg Msg
eventRect model =
    let
        widthString =
            toString (model.windowSize.width - 50)

        heightString =
            toString (model.windowSize.height - 50)
    in
        case List.head model.agenda |> Maybe.andThen (patternEvents model.offset) of
            Just events ->
                Svg.g
                    []
                    [ Svg.rect
                        ([ Svg.x "-320"
                         , Svg.y "-200"
                         , Svg.width widthString
                         , Svg.height heightString
                         , Svg.fill "transparent"
                         ]
                            ++ events
                        )
                        []
                    ]

            Nothing ->
                Svg.g [] []


patternEvents : Vec2 -> Step -> Maybe (List (Svg.Attribute Msg))
patternEvents offset step =
    let
        offsetPosition =
            Json.map2 positionToVec
                (Json.field "offsetX" Json.int)
                (Json.field "offsetY" Json.int)

        positionToVec x y =
            add offset <| vec2 (toFloat x) (toFloat y)
    in
        case step of
            Position _ ->
                Just
                    [ Svg.on "click"
                        (Json.map
                            (\pos -> DoStep (Position (Just pos)))
                            offsetPosition
                        )
                    ]

            _ ->
                Nothing



-- draw points


drawPoints : Model -> Svg Msg
drawPoints model =
    Svg.g [] <|
        List.filterMap
            (drawPoint model.points (List.head model.agenda))
            (Dict.keys model.points)


drawPoint : Dict PointId Point -> Maybe Step -> PointId -> Maybe (Svg Msg)
drawPoint points step id =
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
                , eventCircle step v id
                ]
    in
        Maybe.map draw <| position points id


eventCircle : Maybe Step -> Vec2 -> PointId -> Svg Msg
eventCircle step position id =
    let
        ( x, y ) =
            toTuple <| position
    in
        case pointEvents id step of
            Just events ->
                Svg.g
                    []
                    [ Svg.circle
                        ([ Svg.cx <| toString x
                         , Svg.cy <| toString y
                         , Svg.r "8"
                         , Svg.fill "transparent"
                         ]
                            ++ events
                        )
                        []
                    ]

            Nothing ->
                Svg.g [] []


pointEvents : PointId -> Maybe Step -> Maybe (List (Svg.Attribute Msg))
pointEvents id step =
    case step of
        Just (Position _) ->
            Nothing

        Just (SelectPoint _) ->
            Just
                [ Svg.onMouseOver (FocusPoint id)
                , Svg.onMouseOut (UnFocusPoint id)
                , Svg.onClick (DoStep (SelectPoint (Just id)))
                ]

        _ ->
            Just
                [ Svg.onMouseOver (FocusPoint id)
                , Svg.onMouseOut (UnFocusPoint id)
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
            -- TODO
            Nothing

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
        ( x, y ) =
            toTuple point

        ( ax, ay ) =
            toTuple anchor
    in
        Svg.g []
            [ Svg.line
                [ Svg.x1 <| toString x
                , Svg.y1 <| toString y
                , Svg.x2 <| toString x
                , Svg.y2 <| toString ay
                , Svg.strokeDasharray "5, 10"
                , Svg.strokeWidth "1"
                , Svg.stroke "black"
                ]
                []
            , Svg.line
                [ Svg.x1 <| toString x
                , Svg.y1 <| toString ay
                , Svg.x2 <| toString ax
                , Svg.y2 <| toString ay
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
