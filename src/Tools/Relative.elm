module Tools.Relative
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
import Html exposing (Html, map)
import Html.Attributes as Html
import Html.Events as Html
import Math.Vector2 exposing (..)
import Maybe.Extra as Maybe
import Point exposing (Point)
import Store exposing (Id, Store)
import Styles.Colors as Colors exposing (..)
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg
import Svg.Extra as Svg
import Tools.Common as Tools
    exposing
        ( Callbacks
        , Data
        , exprInput
        , svgSelectPoint
        , svgUpdateMouse
        )
import Tools.Dropdown as Dropdown
import Tools.Styles exposing (..)
import Types exposing (..)


type alias State =
    { x : Maybe E
    , y : Maybe E
    , id : Maybe (Id Point)
    , dropdownState : Dropdown.State
    , selectedPoint : Maybe ( Id Point, Point )
    }


init : Data -> State
init data =
    { x = Nothing
    , y = Nothing
    , id = Nothing
    , dropdownState = Dropdown.init
    , selectedPoint =
        case List.head data.selectedPoints of
            Just id ->
                case Store.get id data.store of
                    Just point ->
                        Just ( id, point )

                    Nothing ->
                        Nothing

            Nothing ->
                Nothing
    }


initWith : Id Point -> Id Point -> E -> E -> State
initWith id anchor x y =
    { x = Just x
    , y = Just y
    , id = Just id
    , dropdownState = Dropdown.init
    , selectedPoint = Nothing
    }


point : Data -> State -> Maybe Point
point data state =
    let
        anchorId =
            state.selectedPoint
                |> Maybe.map Tuple.first

        anchorPosition =
            anchorId
                |> Maybe.andThen (flip Store.get data.store)
                |> Maybe.andThen (Point.position data.store data.variables)

        xCursor =
            data.cursorPosition
                |> Maybe.map (\{ x, y } -> toFloat x)

        yCursor =
            data.cursorPosition
                |> Maybe.map (\{ x, y } -> toFloat y)

        xOffsetCursor =
            Maybe.map2 (\x anchor -> Number (x - getX anchor))
                xCursor
                anchorPosition

        yOffsetCursor =
            Maybe.map2 (\y anchor -> Number (y - getY anchor))
                yCursor
                anchorPosition

        xOffset =
            xOffsetCursor |> Maybe.or state.x

        yOffset =
            yOffsetCursor |> Maybe.or state.y
    in
    Maybe.map3 Point.relative anchorId xOffset yOffset



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
            , horizontalLine data state anchorPosition
            , verticalLine data state anchorPosition
            , Just (svgUpdateMouse addPoint callbacks.updateCursorPosition data)
            ]
                |> List.filterMap identity
                |> Svg.g []

        Nothing ->
            let
                selectPoint =
                    (\maybeId ->
                        { state
                            | selectedPoint =
                                case maybeId of
                                    Just id ->
                                        Store.get id data.store
                                            |> Maybe.map (\point -> ( id, point ))

                                    Nothing ->
                                        Nothing
                        }
                    )
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
                            [ Svg.drawPoint Colors.red pointPosition
                            , Svg.drawSelector Svg.Solid Colors.red pointPosition
                            , Svg.drawRectArrow anchorPosition pointPosition
                            ]
                    )
    in
    anchorPosition data state
        |> Maybe.andThen draw


horizontalLine : Data -> State -> Vec2 -> Maybe (Svg msg)
horizontalLine data state anchorPosition =
    state.y
        |> Maybe.andThen (compute data.variables)
        |> Maybe.map
            (\y -> Svg.drawHorizontalLine (y + getY anchorPosition))


verticalLine : Data -> State -> Vec2 -> Maybe (Svg msg)
verticalLine data state anchorPosition =
    state.x
        |> Maybe.andThen (compute data.variables)
        |> Maybe.map
            (\x -> Svg.drawVerticalLine (x + getX anchorPosition))



{- view -}


view : Callbacks msg -> (State -> msg) -> Data -> State -> Svg msg
view callbacks updateStateCallback data state =
    let
        updateX =
            (\s -> { state | x = parse s }) >> updateStateCallback

        updateY =
            (\s -> { state | y = parse s }) >> updateStateCallback

        updateAutoState autoMsg =
            let
                ( newDropdownState, newSelectedPoint ) =
                    state.dropdownState
                        |> Dropdown.update state.selectedPoint data autoMsg
            in
            updateStateCallback
                { state
                    | dropdownState = newDropdownState
                    , selectedPoint = newSelectedPoint
                }
    in
    [ Dropdown.view state.selectedPoint data state.dropdownState
        |> map updateAutoState
    , exprInput "horizontal distance" state.x updateX
    , exprInput "vertical distance" state.y updateY
    ]
        |> Tools.view callbacks data state point



{- compute position -}


anchorPosition : Data -> State -> Maybe Vec2
anchorPosition data state =
    state.selectedPoint
        |> Maybe.map Tuple.first
        |> Maybe.andThen (flip Store.get data.store)
        |> Maybe.andThen (Point.position data.store data.variables)


pointPosition : Data -> State -> Vec2 -> Maybe Vec2
pointPosition data state anchorPosition =
    let
        x =
            state.x
                |> Maybe.andThen (compute data.variables)
                |> Maybe.map (\x -> x + getX anchorPosition)

        y =
            state.y
                |> Maybe.andThen (compute data.variables)
                |> Maybe.map (\y -> y + getY anchorPosition)
    in
    case data.cursorPosition of
        Just cursorPosition ->
            Just <|
                vec2
                    (x |> Maybe.withDefault (toFloat cursorPosition.x))
                    (y |> Maybe.withDefault (toFloat cursorPosition.y))

        Nothing ->
            Maybe.map2 vec2 x y
