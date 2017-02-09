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
import Boundary exposing (..)
import Cut exposing (..)
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
    case model.focus of
        Just (FPoint id) ->
            case Dict.get id model.points of
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

        Just (FCut id) ->
            case Dict.get id model.cuts of
                Just cut ->
                    Html.div []
                        [ Html.text "cut: "
                        , Html.text <| toString cut
                        ]

                Nothing ->
                    Html.div [] []

        Just (FBoundary id) ->
            case Dict.get id model.boundaries of
                Just boundary ->
                    Html.div []
                        [ Html.text "boundary: "
                        , Html.text <| toString boundary
                        ]

                Nothing ->
                    Html.div [] []

        _ ->
            Html.div [] []



-- tool box


viewToolBox : Model -> Html Msg
viewToolBox model =
    case model.selectedTool of
        Just tool ->
            -- TODO view tool info
            Html.div []
                [ Html.button
                    [ Events.onClick <| AbortTool ]
                    [ Html.text "abort" ]
                , Html.button
                    [ Events.onClick <| DoStep Tools.NoOp ]
                    [ Html.text "no step" ]
                ]

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
                , Html.button
                    [ Events.onClick <| InitTool Tools.cutFromPointPointTool ]
                    [ Html.text "add cut" ]
                , Html.button
                    [ Events.onClick <| InitTool Tools.boundaryFromPointsTool ]
                    [ Html.text "add boundary" ]
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
            [ drawOrigin
            , drawSelection model
            , drawGuideLines model
            , eventRect model
            , drawCuts model
            , drawBoundaries model
            , drawPoints model
            ]


drawOrigin : Svg Msg
drawOrigin =
    Svg.g []
        [ Svg.line
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
            (drawPoint model.points model.focus)
            (Dict.keys model.points)


drawPoint : Dict PointId Point -> Maybe Focus -> PointId -> Maybe (Svg Msg)
drawPoint points focus id =
    let
        color =
            case focus of
                Just (FPoint focusId) ->
                    if id == focusId then
                        "green"
                    else
                        "black"

                _ ->
                    "black"

        draw v =
            Svg.g
                []
                [ Svg.circle
                    [ Svg.cx <| toString <| getX v
                    , Svg.cy <| toString <| getY v
                    , Svg.r "2"
                    , Svg.fill color
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
                , Svg.onMouseOver (SetFocus <| FPoint id)
                , Svg.onMouseOut UnFocus
                , Svg.onClick (DoStep (Tools.SelectPoint id))
                ]
                []
            ]



-- draw guide lines


drawGuideLines : Model -> Svg Msg
drawGuideLines model =
    Svg.g [] <|
        List.filterMap
            (drawGuideLine model.points model.focus)
            (Dict.keys model.points)


drawGuideLine : Dict PointId Point -> Maybe Focus -> PointId -> Maybe (Svg Msg)
drawGuideLine points focus id =
    let
        color =
            case focus of
                Just (FPoint focusId) ->
                    if id == focusId then
                        "green"
                    else
                        "black"

                _ ->
                    "black"
    in
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
                        (drawADGuideLines color)
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
                        (drawDDGuideLines color)
                        anchorPosition
                        pointPosition

            _ ->
                Nothing


drawDDGuideLines : String -> Vec2 -> Vec2 -> Svg Msg
drawDDGuideLines color anchor point =
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
                , Svg.stroke color
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
                , Svg.stroke color
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


drawADGuideLines : String -> Vec2 -> Vec2 -> Svg Msg
drawADGuideLines color anchor point =
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
                , Svg.stroke color
                ]
                []
            ]



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



-- draw cuts


drawCuts : Model -> Svg Msg
drawCuts model =
    Svg.g [] <|
        List.filterMap
            (drawCut model.points model.cuts model.focus)
            (Dict.keys model.cuts)


drawCut : Dict PointId Point -> Dict CutId Cut -> Maybe Focus -> CutId -> Maybe (Svg Msg)
drawCut points cuts focus id =
    let
        draw cut =
            Maybe.map2 drawLine
                (position points cut.anchorA)
                (position points cut.anchorB)

        color =
            case focus of
                Just (FCut focusId) ->
                    if id == focusId then
                        "green"
                    else
                        "black"

                _ ->
                    "black"

        drawLine v w =
            Svg.g []
                [ Svg.line
                    [ Svg.x1 <| toString <| getX v
                    , Svg.y1 <| toString <| getY v
                    , Svg.x2 <| toString <| getX w
                    , Svg.y2 <| toString <| getY w
                    , Svg.stroke color
                    , Svg.strokeWidth "1"
                    ]
                    []
                , Svg.line
                    [ Svg.x1 <| toString <| getX v
                    , Svg.y1 <| toString <| getY v
                    , Svg.x2 <| toString <| getX w
                    , Svg.y2 <| toString <| getY w
                    , Svg.stroke "transparent"
                    , Svg.strokeWidth "8"
                    , Svg.onMouseOver (SetFocus <| FCut id)
                    , Svg.onMouseOut UnFocus
                    ]
                    []
                ]
    in
        Dict.get id cuts |> Maybe.andThen draw



-- draw boundaries


drawBoundaries : Model -> Svg Msg
drawBoundaries model =
    Svg.g [] <|
        List.filterMap
            (drawBoundary model.points model.boundaries model.focus)
            (Dict.keys model.boundaries)


drawBoundary : Dict PointId Point -> Dict BoundaryId Boundary -> Maybe Focus -> BoundaryId -> Maybe (Svg Msg)
drawBoundary points boundaries focus id =
    let
        draw boundary =
            Svg.g [] <|
                Tuple.second <|
                    List.foldl appendLine ( Nothing, [] ) (Boundary.toList boundary)

        color =
            case focus of
                Just (FBoundary id) ->
                    "green"

                _ ->
                    "black"

        appendLine nextId ( previousId, svgs ) =
            case previousId of
                Just id ->
                    let
                        newLine =
                            Maybe.withDefault (Svg.g [] []) <|
                                Maybe.map2
                                    drawLine
                                    (position points id)
                                    (position points nextId)
                    in
                        ( Just nextId, newLine :: svgs )

                Nothing ->
                    ( Just nextId, svgs )

        drawLine v w =
            Svg.g []
                [ Svg.line
                    [ Svg.x1 <| toString <| getX v
                    , Svg.y1 <| toString <| getY v
                    , Svg.x2 <| toString <| getX w
                    , Svg.y2 <| toString <| getY w
                    , Svg.stroke color
                    , Svg.strokeWidth "1"
                    ]
                    []
                , Svg.line
                    [ Svg.x1 <| toString <| getX v
                    , Svg.y1 <| toString <| getY v
                    , Svg.x2 <| toString <| getX w
                    , Svg.y2 <| toString <| getY w
                    , Svg.stroke "transparent"
                    , Svg.strokeWidth "8"
                    , Svg.onMouseOver (SetFocus <| FBoundary id)
                    , Svg.onMouseOut UnFocus
                    ]
                    []
                ]
    in
        Maybe.map draw <| Dict.get id boundaries
