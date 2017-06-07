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
import Html exposing (Html)
import Html.Attributes as Html
import Html.Events as Html
import Math.Vector2 exposing (..)
import Maybe.Extra as Maybe
import Styles.Colors exposing (..)
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg
import Svg.Extra as Svg
import Tools.Common as Tools
    exposing
        ( Callbacks
        , Data
        , exprInput
        , idDropdown
        , svgSelectPoint
        , svgUpdateMouse
        )
import Tools.Styles exposing (..)
import Types exposing (..)


type alias State =
    { anchor : Maybe String
    , x : Maybe E
    , y : Maybe E
    , id : Maybe Id
    }


init : State
init =
    { anchor = Nothing
    , x = Nothing
    , y = Nothing
    , id = Nothing
    }


initWith : Id -> Id -> E -> E -> State
initWith id anchor x y =
    { anchor = Just (toString anchor)
    , x = Just x
    , y = Just y
    , id = Just id
    }


point : Data -> State -> Maybe Point
point data state =
    let
        anchorId =
            state.anchor
                |> Maybe.andThen (String.toInt >> Result.toMaybe)

        anchorPosition =
            anchorId
                |> Maybe.andThen (flip Dict.get data.store)
                |> Maybe.andThen (position data.store data.variables)

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
    Maybe.map3 Relative anchorId xOffset yOffset



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
view callbacks updateState data state =
    let
        updateAnchor =
            (\id -> { state | anchor = id }) >> updateState

        updateX =
            (\s -> { state | x = parse s }) >> updateState

        updateY =
            (\s -> { state | y = parse s }) >> updateState
    in
    [ idDropdown data state.anchor updateAnchor
    , exprInput "x" state.x updateX
    , exprInput "y" state.y updateY
    ]
        |> Tools.view callbacks data state point



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
