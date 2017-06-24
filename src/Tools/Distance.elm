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
import Events
import Expr exposing (..)
import FormatNumber
import Html exposing (Html)
import Html.Attributes as Html
import Html.Events as Html
import Keyboard.Extra as Keyboard
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
        , exprInput_
        , idDropdown
        , svgSelectPoint
        , svgUpdateMouse
        )
import Tools.Styles exposing (..)
import Types exposing (..)


type alias State =
    { anchor : Maybe String
    , distance : Maybe E
    , angle : Maybe E
    , id : Maybe (Id Point)
    }


init : Data -> State
init data =
    { anchor = Maybe.map toString (List.head data.selectedPoints)
    , distance = Nothing
    , angle = Nothing
    , id = Nothing
    }


initWith : Id Point -> Id Point -> E -> E -> State
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
                |> Maybe.map Store.fromInt

        anchorPosition =
            anchorId
                |> Maybe.andThen (flip Store.get data.store)
                |> Maybe.andThen (Point.position data.store data.variables)

        deltaCursor =
            Maybe.map2 sub cursorPosition anchorPosition

        distanceCursor =
            deltaCursor
                |> Maybe.map length
                |> Maybe.map Number

        angleCursor =
            deltaCursor
                |> Maybe.map (\delta -> atan2 (getY delta) (getX delta))
                |> Maybe.map snap
                |> Maybe.map Number

        snap angle =
            if List.member Keyboard.Shift data.pressedKeys then
                snapAngle 8 angle
            else
                angle

        distance =
            distanceCursor |> Maybe.or state.distance

        angle =
            angleCursor |> Maybe.or state.angle
    in
    Maybe.map3 Point.Distance anchorId distance angle



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
        lerp t u v =
            add (scale (1 - t) u) (scale t v)

        format =
            FormatNumber.format
                { decimals = 2
                , thousandSeparator = " "
                , decimalSeparator = "."
                }

        draw anchorPosition =
            pointPosition data state anchorPosition
                |> Maybe.map
                    (\pointPosition ->
                        Svg.g []
                            [ Svg.drawPoint Colors.red pointPosition
                            , Svg.drawSelector Svg.Solid Colors.red pointPosition
                            , Svg.drawArrow anchorPosition pointPosition
                            , Svg.drawAngleArc Svg.defaultArcConfig anchorPosition pointPosition
                            , Svg.label
                                [ Svg.transform (Svg.translate (lerp 0.5 anchorPosition pointPosition))
                                ]
                                [ Svg.text (format (length (sub pointPosition anchorPosition)))
                                ]
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
        updateAnchor =
            (\id -> { state | anchor = id }) >> updateState

        updateDistance =
            (\s -> { state | distance = parse s }) >> updateState

        updateAngle =
            (\s -> { state | angle = parse s }) >> updateState

        ( distancePlaceholder, anglePlaceholder ) =
            case ( data.cursorPosition, anchorPosition data state ) of
                ( Just mousePosition, Just anchorPosition ) ->
                    let
                        p =
                            pointPosition data state anchorPosition

                        w =
                            anchorPosition
                                |> flip sub (toVec mousePosition)
                    in
                    ( w
                        |> length
                        |> toString
                    , atan2 (getY w) (getX w)
                        |> toString
                    )

                _ ->
                    ( "distance", "angle" )
    in
    [ idDropdown data state.anchor updateAnchor
    , exprInput_ True distancePlaceholder state.distance updateDistance
    , exprInput anglePlaceholder state.angle updateAngle
    ]
        |> Tools.view callbacks data state point



{- compute position -}


anchorPosition : Data -> State -> Maybe Vec2
anchorPosition data state =
    state.anchor
        |> Maybe.andThen (String.toInt >> Result.toMaybe)
        |> Maybe.map Store.fromInt
        |> Maybe.andThen (flip Store.get data.store)
        |> Maybe.andThen (Point.position data.store data.variables)


pointPosition : Data -> State -> Vec2 -> Maybe Vec2
pointPosition data state anchorPosition =
    let
        position distance angle =
            vec2 (cos (snap angle)) (sin (snap angle))
                |> scale distance
                |> add anchorPosition

        snap angle =
            if List.member Keyboard.Shift data.pressedKeys then
                snapAngle 8 angle
            else
                angle
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


snapAngle : Int -> Float -> Float
snapAngle count angle =
    let
        divisor =
            2 * pi / toFloat count
    in
    toFloat (round (angle / divisor)) * divisor
