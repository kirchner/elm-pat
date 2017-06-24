module Tools.Between
    exposing
        ( State
        , init
        , svg
        , view
        )

import Expr exposing (E)
import Html exposing (Html, map)
import Math.Vector2 exposing (..)
import Maybe.Extra as Maybe
import Point exposing (Point)
import Store exposing (Id, Store)
import Styles.Colors as Colors
import Svg exposing (Svg)
import Svg.Extra as Svg
import Tools.Common exposing (Callbacks, Data)
import Tools.Dropdown as Dropdown
import Types exposing (Position, toVec)


type alias State =
    { firstDropdown : Dropdown.State
    , first : Maybe ( Id Point, Point )
    , lastDropdown : Dropdown.State
    , last : Maybe ( Id Point, Point )
    , ratio : Maybe E
    }


init : Data -> State
init data =
    { firstDropdown = Dropdown.init
    , first = Nothing
    , lastDropdown = Dropdown.init
    , last = Nothing
    , ratio = Nothing
    }


point : Data -> State -> Maybe Point
point data state =
    case ( firstPosition data state, lastPosition data state ) of
        ( Just firstPosition, Just lastPosition ) ->
            let
                maybeRatio =
                    data.cursorPosition
                        |> Maybe.map (ratio data state firstPosition lastPosition)
                        |> Maybe.or
                            (state.ratio
                                |> Maybe.andThen (Expr.compute data.variables)
                            )
            in
            case maybeRatio of
                Just ratio ->
                    Maybe.map2
                        (\first last ->
                            Point.between first last ratio
                        )
                        (state.first |> Maybe.map Tuple.first)
                        (state.last |> Maybe.map Tuple.first)

                Nothing ->
                    Nothing

        _ ->
            Nothing



{- svg -}


svg : Callbacks msg -> (State -> msg) -> Data -> State -> Svg msg
svg callbacks updateState data state =
    case ( firstPosition data state, lastPosition data state ) of
        ( Just firstPosition, Just lastPosition ) ->
            let
                addPoint =
                    point data state
                        |> Maybe.map callbacks.addPoint
            in
            Svg.g []
                [ Svg.drawSelector Svg.Solid Colors.red firstPosition
                , Svg.drawSelector Svg.Solid Colors.red lastPosition
                , Svg.drawLine firstPosition lastPosition
                , newPoint data state firstPosition lastPosition
                , Tools.Common.svgUpdateMouse addPoint
                    callbacks.updateCursorPosition
                    data
                ]

        ( Just firstPosition, Nothing ) ->
            let
                selectPoint =
                    (\maybeId ->
                        { state
                            | last =
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
            Svg.g []
                [ Svg.drawSelector Svg.Solid Colors.red firstPosition
                , Tools.Common.svgSelectPoint callbacks.focusPoint selectPoint data
                ]

        ( Nothing, Just lastPosition ) ->
            let
                selectPoint =
                    (\maybeId ->
                        { state
                            | first =
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
            Svg.g []
                [ Svg.drawSelector Svg.Solid Colors.red lastPosition
                , Tools.Common.svgSelectPoint callbacks.focusPoint selectPoint data
                ]

        ( Nothing, Nothing ) ->
            let
                selectPoint =
                    (\maybeId ->
                        { state
                            | first =
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
            Svg.g []
                [ Tools.Common.svgSelectPoint callbacks.focusPoint selectPoint data ]


newPoint : Data -> State -> Vec2 -> Vec2 -> Svg msg
newPoint data state firstPosition lastPosition =
    let
        maybeRatio =
            data.cursorPosition
                |> Maybe.map (ratio data state firstPosition lastPosition)
                |> Maybe.or
                    (state.ratio
                        |> Maybe.andThen (Expr.compute data.variables)
                    )
    in
    case maybeRatio of
        Just ratio ->
            let
                pointPosition =
                    lastPosition
                        |> flip sub firstPosition
                        |> scale ratio
                        |> add firstPosition
            in
            Svg.g []
                [ Svg.drawPoint Colors.red pointPosition
                , Svg.drawSelector Svg.Solid Colors.red pointPosition
                ]

        Nothing ->
            Svg.g [] []



{- view -}


view : Callbacks msg -> (State -> msg) -> Data -> State -> Html msg
view callbacks updateState data state =
    let
        updateFirstDropdown msg =
            let
                ( newFirstDropdown, newFirst ) =
                    state.firstDropdown
                        |> Dropdown.update state.first data msg
            in
            updateState
                { state
                    | firstDropdown = newFirstDropdown
                    , first = newFirst
                }

        updateLastDropdown msg =
            let
                ( newLastDropdown, newLast ) =
                    state.lastDropdown
                        |> Dropdown.update state.last data msg
            in
            updateState
                { state
                    | lastDropdown = newLastDropdown
                    , last = newLast
                }

        updateRatio =
            (\s -> { state | ratio = Expr.parse s }) >> updateState
    in
    [ Dropdown.view state.first data state.firstDropdown
        |> map updateFirstDropdown
    , Dropdown.view state.last data state.lastDropdown
        |> map updateLastDropdown
    , Tools.Common.exprInput "ratio" state.ratio updateRatio
    ]
        |> Tools.Common.view callbacks data state point



{- compute positions -}


ratio : Data -> State -> Vec2 -> Vec2 -> Position -> Float
ratio data state firstPosition lastPosition cursorPosition =
    let
        deltaAnchors =
            lastPosition |> flip sub firstPosition

        deltaCursor =
            toVec cursorPosition |> flip sub firstPosition

        project v w =
            w |> scale (dot v w / lengthSquared w)

        pointPosition =
            project deltaCursor deltaAnchors
                |> add firstPosition

        ratio =
            (pointPosition |> flip sub firstPosition |> length)
                / (lastPosition |> flip sub firstPosition |> length)
    in
    ratio


firstPosition : Data -> State -> Maybe Vec2
firstPosition data state =
    state.first
        |> Maybe.map Tuple.first
        |> position data state


lastPosition : Data -> State -> Maybe Vec2
lastPosition data state =
    state.last
        |> Maybe.map Tuple.first
        |> position data state


position : Data -> State -> Maybe (Id Point) -> Maybe Vec2
position data state maybeId =
    maybeId
        |> Maybe.andThen (flip Store.get data.store)
        |> Maybe.andThen (Point.position data.store data.variables)
