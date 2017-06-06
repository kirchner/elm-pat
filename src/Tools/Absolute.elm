module Tools.Absolute
    exposing
        ( State
        , init
        , initWith
        , svg
        , view
        )

import Dict exposing (Dict)
import Events
import Expr exposing (..)
import Html exposing (Html)
import Html.Attributes as Html
import Html.Events as Html
import Input.Float
import Math.Vector2 exposing (..)
import Maybe.Extra as Maybe
import Styles.Colors exposing (..)
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg
import Svg.Extra as Svg
import Tools.Common exposing (..)
import Tools.Styles exposing (..)
import Types exposing (..)


type alias State =
    { x : Maybe E
    , y : Maybe E
    , id : Maybe Id
    }


init : State
init =
    { x = Nothing
    , y = Nothing
    , id = Nothing
    }


initWith : Id -> E -> E -> State
initWith id x y =
    { x = Just x
    , y = Just y
    , id = Just id
    }


point : Data -> State -> Maybe Point
point data state =
    let
        xCursor =
            data.cursorPosition
                |> Maybe.map (\{ x, y } -> Number (toFloat x))

        yCursor =
            data.cursorPosition
                |> Maybe.map (\{ x, y } -> Number (toFloat y))

        x =
            xCursor |> Maybe.or state.x

        y =
            yCursor |> Maybe.or state.y
    in
    Maybe.map2 Absolute x y



{- canvas -}


svg : Callbacks msg -> (State -> msg) -> Data -> State -> Svg msg
svg callbacks updateState data state =
    let
        addPoint =
            point data state |> Maybe.map callbacks.addPoint
    in
    [ newPoint data state
    , horizontalLine data state
    , verticalLine data state
    , Just (svgUpdateMouse addPoint callbacks.updateCursorPosition data)
    ]
        |> List.filterMap identity
        |> Svg.g []


newPoint : Data -> State -> Maybe (Svg msg)
newPoint data state =
    let
        draw x y =
            Svg.g []
                [ Svg.drawPoint (vec2 x y)
                , Svg.drawSelector (vec2 x y)
                ]

        xState =
            state.x |> Maybe.andThen (compute data.variables)

        yState =
            state.y |> Maybe.andThen (compute data.variables)

        xCursor =
            data.cursorPosition
                |> Maybe.map (\{ x, y } -> toFloat x)

        yCursor =
            data.cursorPosition
                |> Maybe.map (\{ x, y } -> toFloat y)

        x =
            xCursor |> Maybe.or xState

        y =
            yCursor |> Maybe.or yState
    in
    Maybe.map2 draw x y


horizontalLine : Data -> State -> Maybe (Svg msg)
horizontalLine data state =
    state.y
        |> Maybe.andThen (compute data.variables)
        |> Maybe.map Svg.drawHorizontalLine


verticalLine : Data -> State -> Maybe (Svg msg)
verticalLine data state =
    state.x
        |> Maybe.andThen (compute data.variables)
        |> Maybe.map Svg.drawVerticalLine



{- view -}


view : Callbacks msg -> (State -> msg) -> Data -> State -> Svg msg
view callbacks updateState data state =
    let
        addPoint =
            point data state |> Maybe.map callbacks.addPoint

        updateX =
            (\s -> { state | x = parse s }) >> updateState

        updateY =
            (\s -> { state | y = parse s }) >> updateState

        attr =
            case addPoint of
                Just callback ->
                    Html.onClick callback

                Nothing ->
                    Html.disabled True
    in
    Html.div
        [ class [ ToolBox ] ]
        [ exprInput "x" state.x updateX
        , exprInput "y" state.y updateY
        , Html.div
            [ class [ Button ]
            , attr
            ]
            [ Html.text "add" ]
        ]
