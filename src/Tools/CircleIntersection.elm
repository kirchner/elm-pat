module Tools.CircleIntersection
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
import Point exposing (Choice(..), Point)
import Store exposing (Id, Store)
import Styles.Colors as Colors
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Extra as Svg
import Tools.Common exposing (Callbacks, Data)
import Tools.Dropdown as Dropdown
import Types exposing (Position, toVec)


type alias State =
    { firstDropdown : Dropdown.State
    , first : Maybe ( Id Point, Point )
    , lastDropdown : Dropdown.State
    , last : Maybe ( Id Point, Point )
    , firstRadius : Maybe E
    , lastRadius : Maybe E
    , choice : Choice
    }


init : Data -> State
init data =
    { firstDropdown = Dropdown.init
    , first = Nothing
    , lastDropdown = Dropdown.init
    , last = Nothing
    , firstRadius = Nothing
    , lastRadius = Nothing
    , choice = LeftMost
    }


point : Data -> State -> Maybe Point
point data state =
    case
        ( state.first |> Maybe.map Tuple.first
        , state.firstRadius
        , state.last |> Maybe.map Tuple.first
        , state.lastRadius
        )
    of
        ( Just first, Just firstRadius, Just last, Just lastRadius ) ->
            Point.circleIntersection first firstRadius last lastRadius state.choice
                |> Just

        _ ->
            Nothing



{- svg -}


svg : Callbacks msg -> (State -> msg) -> Data -> State -> Svg msg
svg callbacks updateState data state =
    case
        ( firstPosition data state
        , state.firstRadius |> Maybe.andThen (Expr.compute data.variables)
        , lastPosition data state
        , state.lastRadius |> Maybe.andThen (Expr.compute data.variables)
        )
    of
        ( Just firstPosition, Just firstRadius, Just lastPosition, Just lastRadius ) ->
            let
                addPoint =
                    point data state |> Maybe.map callbacks.addPoint
            in
            Svg.g []
                [ Svg.drawSelector Svg.Solid Colors.red firstPosition
                , drawCircle firstPosition firstRadius
                , Svg.drawSelector Svg.Solid Colors.red lastPosition
                , drawCircle lastPosition lastRadius
                , Svg.drawLine firstPosition lastPosition
                , Tools.Common.svgUpdateMouse addPoint
                    callbacks.updateCursorPosition
                    data
                ]

        _ ->
            Svg.g [] []


drawCircle : Vec2 -> Float -> Svg msg
drawCircle center radius =
    Svg.circle
        [ Svg.cx (toString (getX center))
        , Svg.cy (toString (getY center))
        , Svg.r (toString radius)
        , Svg.strokeWidth "1"
        , Svg.stroke Colors.base1
        , Svg.fill "none"
        , Svg.strokeDasharray "5, 5"
        ]
        []



{- view -}


view : Callbacks msg -> (State -> msg) -> Data -> State -> Html msg
view callbacks updateState data state =
    let
        updateFirstRadius =
            (\s -> { state | firstRadius = Expr.parse s }) >> updateState

        updateLastRadius =
            (\s -> { state | lastRadius = Expr.parse s }) >> updateState

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

        updateChoice =
            (\id ->
                if id == 0 then
                    { state | choice = LeftMost }
                else if id == 1 then
                    { state | choice = RightMost }
                else
                    state
            )
                >> updateState

        choices =
            [ "a", "b" ]

        switchState =
            case state.choice of
                LeftMost ->
                    0

                RightMost ->
                    1
    in
    [ Dropdown.view state.first data state.firstDropdown
        |> map updateFirstDropdown
    , Tools.Common.exprInput "first radius" state.firstRadius updateFirstRadius
    , Dropdown.view state.last data state.lastDropdown
        |> map updateLastDropdown
    , Tools.Common.exprInput "last radius" state.lastRadius updateLastRadius
    , Tools.Common.switch choices switchState updateChoice
    ]
        |> Tools.Common.view callbacks data state point



{- positions -}


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
