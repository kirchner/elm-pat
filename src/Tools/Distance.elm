module Tools.Distance
    exposing
        ( State
        , init
        , initWith
        , svg
        , view
        )

import Css
import Dict exposing (Dict)
import Dropdown
import Events
import Expr exposing (..)
import Html exposing (Html)
import Html.Attributes as Html
import Html.Events as Html
import Input.Float
import Math.Vector2 exposing (..)
import Maybe.Extra as Maybe
import Styles.Colors as Colors exposing (..)
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg
import Svg.Extra as Svg
import Tools.Common exposing (..)
import Tools.Styles exposing (..)
import Types exposing (..)


type alias State =
    { anchor : Maybe String
    , distance : Maybe E
    , angle : Maybe E
    , id : Maybe Id
    }


init : State
init =
    { anchor = Nothing
    , distance = Nothing
    , angle = Nothing
    , id = Nothing
    }


initWith : Id -> Id -> E -> E -> State
initWith id anchor distance angle =
    { anchor = Just (toString anchor)
    , distance = Just distance
    , angle = Just angle
    , id = Just id
    }


point : Data -> State -> Maybe Point
point data state =
    let
        cursorPosition =
            data.cursorPosition
                |> Maybe.map (\{ x, y } -> vec2 (toFloat x) (toFloat y))

        anchorId =
            state.anchor
                |> Maybe.andThen (String.toInt >> Result.toMaybe)

        anchorPosition =
            anchorId
                |> Maybe.andThen (flip Dict.get data.store)
                |> Maybe.andThen (position data.store data.variables)

        deltaCursor =
            Maybe.map2 sub cursorPosition anchorPosition

        distanceCursor =
            deltaCursor
                |> Maybe.map length
                |> Maybe.map Number

        angleCursor =
            deltaCursor
                |> Maybe.map (\delta -> atan2 (getY delta) (getX delta))
                |> Maybe.map Number

        distance =
            distanceCursor |> Maybe.or state.distance

        angle =
            angleCursor |> Maybe.or state.angle
    in
    Maybe.map3 Distance anchorId distance angle



{- svg -}


svg : Callbacks msg -> (State -> msg) -> Data -> State -> Svg msg
svg callbacks updateState data state =
    case anchorPosition data state of
        Just anchorPosition ->
            let
                addPoint =
                    point data state |> Maybe.map callbacks.addPoint
            in
            [ newPoint data state
            , circle data state
            , line data state
            , Just (svgUpdateMouse addPoint callbacks.updateCursorPosition data)
            ]
                |> List.filterMap identity
                |> Svg.g []

        Nothing ->
            let
                selectPoint =
                    (\id -> { state | anchor = id |> Maybe.map toString })
                        >> updateState
            in
            [ svgSelectPoint callbacks.focusPoint selectPoint data ]
                |> Svg.g []


newPoint : Data -> State -> Maybe (Svg msg)
newPoint data state =
    let
        draw anchorPosition =
            pointPosition data state anchorPosition
                |> Maybe.map
                    (\pointPosition ->
                        Svg.g []
                            [ Svg.drawPoint pointPosition
                            , Svg.drawSelector pointPosition
                            , Svg.drawArrow anchorPosition pointPosition
                            ]
                    )
    in
    anchorPosition data state
        |> Maybe.andThen draw


circle : Data -> State -> Maybe (Svg msg)
circle data state =
    let
        draw anchorPosition distance =
            Svg.circle
                [ Svg.cx (toString (getX anchorPosition))
                , Svg.cy (toString (getY anchorPosition))
                , Svg.r (toString distance)
                , Svg.strokeWidth "1"
                , Svg.stroke Colors.base1
                , Svg.fill "none"
                , Svg.strokeDasharray "5, 5"
                ]
                []
    in
    case anchorPosition data state of
        Just anchorPosition ->
            state.distance
                |> Maybe.andThen (compute data.variables)
                |> Maybe.map (draw anchorPosition)

        Nothing ->
            Nothing


line : Data -> State -> Maybe (Svg msg)
line data state =
    let
        draw anchorPosition angle =
            Svg.drawArrow anchorPosition
                (vec2 (cos angle) (sin angle)
                    |> scale 10000
                    |> add anchorPosition
                )
    in
    case anchorPosition data state of
        Just anchorPosition ->
            state.angle
                |> Maybe.andThen (compute data.variables)
                |> Maybe.map (draw anchorPosition)

        Nothing ->
            Nothing



{- view -}


view : Callbacks msg -> (State -> msg) -> Data -> State -> Svg msg
view callbacks updateState data state =
    let
        addPoint =
            point data state |> Maybe.map callbacks.addPoint

        updateAnchor =
            (\id -> { state | anchor = id })
                >> updateState

        updateDistance =
            (\s -> { state | distance = parse s }) >> updateState

        updateAngle =
            (\s -> { state | angle = parse s }) >> updateState

        attr =
            case addPoint of
                Just callback ->
                    Html.onClick callback

                Nothing ->
                    Html.disabled True

        items =
            Dict.keys data.store
                |> List.map toString
                |> List.map
                    (\id ->
                        { value = id
                        , text = "point " ++ id
                        , enabled = True
                        }
                    )
    in
    Html.div
        [ class [ ToolBox ] ]
        [ Html.div []
            [ Html.text "id:"
            , Dropdown.dropdown
                { items = items
                , emptyItem =
                    Just
                        { value = "-1"
                        , text = "select point"
                        , enabled = True
                        }
                , onChange = updateAnchor
                }
                []
                state.anchor
            , Html.button
                [ Html.onClick (updateAnchor Nothing) ]
                [ Html.text "clear" ]
            ]
        , exprInput "d" state.distance updateDistance
        , exprInput "a" state.angle updateAngle
        , Html.div
            [ class [ Button ]
            , attr
            ]
            [ Html.text "add" ]
        ]



{- compute position -}


anchorPosition : Data -> State -> Maybe Vec2
anchorPosition data state =
    state.anchor
        |> Maybe.andThen (String.toInt >> Result.toMaybe)
        |> Maybe.andThen (flip Dict.get data.store)
        |> Maybe.andThen (position data.store data.variables)


pointPosition : Data -> State -> Vec2 -> Maybe Vec2
pointPosition data state anchorPosition =
    let
        position distance angle =
            vec2 (cos angle) (sin angle)
                |> scale distance
                |> add anchorPosition
    in
    case
        data.cursorPosition
            |> Maybe.map (\{ x, y } -> vec2 (toFloat x) (toFloat y))
    of
        Just cursorPosition ->
            let
                delta =
                    sub cursorPosition anchorPosition
            in
            Just <|
                position
                    (state.distance
                        |> Maybe.andThen (compute data.variables)
                        |> Maybe.withDefault (length delta)
                    )
                    (state.angle
                        |> Maybe.andThen (compute data.variables)
                        |> Maybe.withDefault (atan2 (getY delta) (getX delta))
                    )

        Nothing ->
            Maybe.map2 position
                (state.distance |> Maybe.andThen (compute data.variables))
                (state.angle |> Maybe.andThen (compute data.variables))
