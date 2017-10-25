module Tools.Between
    exposing
        ( Msg
        , State
        , init
        , svg
        , update
        , view
        )

import Data.Expr as Expr exposing (E)
import Data.Point as Point exposing (Point)
import Data.Position as Position exposing (Position)
import Data.Store as Store exposing (Id, Store)
import Html exposing (Html, map)
import Math.Vector2 exposing (..)
import Math.Vector2.Extra exposing (..)
import Maybe.Extra as Maybe
import Styles.Colors as Colors
import Svg exposing (Svg)
import Svgs.Extra as Extra
import Svgs.SelectPoint as SelectPoint
import Svgs.UpdateMouse as UpdateMouse
import Tools.Callbacks exposing (Callbacks)
import Tools.Data exposing (Data)
import Tools.PointMenu as PointMenu
import Views.ExprInput as ExprInput


type alias State =
    { ratio : Maybe E
    , points : PointMenu.SelectablePoints
    }


init : Data -> State
init data =
    { ratio = Nothing
    , points = PointMenu.init 2 data
    }



---- UPDATE


type Msg
    = UpdateRatio String
    | PointMenuMsg PointMenu.Msg


update : Callbacks msg -> Msg -> State -> ( State, Cmd Msg, Maybe msg )
update callbacks msg state =
    case msg of
        UpdateRatio string ->
            ( { state | ratio = Expr.parse string }
            , Cmd.none
            , Nothing
            )

        PointMenuMsg msg ->
            PointMenu.update callbacks.selectPoint PointMenuMsg msg state



---- SVG


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
                [ Extra.drawSelector Extra.Solid Colors.red firstPosition
                , Extra.drawSelector Extra.Solid Colors.red lastPosition
                , Extra.drawLine firstPosition lastPosition
                , newPoint data state firstPosition lastPosition
                , UpdateMouse.svg addPoint
                    callbacks.updateCursorPosition
                    data.viewPort
                ]

        ( Just firstPosition, Nothing ) ->
            let
                selectPoint =
                    Maybe.map (\id -> PointMenu.selectPoint 1 id data state)
                        >> Maybe.withDefault state
                        >> updateState
            in
            Svg.g []
                [ Extra.drawSelector Extra.Solid Colors.red firstPosition
                , SelectPoint.svg callbacks.focusPoint selectPoint data
                ]

        ( Nothing, Just lastPosition ) ->
            let
                selectPoint =
                    Maybe.map (\id -> PointMenu.selectPoint 0 id data state)
                        >> Maybe.withDefault state
                        >> updateState
            in
            Svg.g []
                [ Extra.drawSelector Extra.Solid Colors.red lastPosition
                , SelectPoint.svg callbacks.focusPoint selectPoint data
                ]

        ( Nothing, Nothing ) ->
            let
                selectPoint =
                    Maybe.map (\id -> PointMenu.selectPoint 0 id data state)
                        >> Maybe.withDefault state
                        >> updateState
            in
            Svg.g []
                [ SelectPoint.svg callbacks.focusPoint selectPoint data ]


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
                [ Extra.drawPoint Colors.red pointPosition
                , Extra.drawSelector Extra.Solid Colors.red pointPosition
                ]

        Nothing ->
            Svg.g [] []



---- VIEW


view : State -> Html Msg
view state =
    Html.div []
        [ PointMenu.view 0 state |> Html.map PointMenuMsg
        , PointMenu.view 1 state |> Html.map PointMenuMsg
        , ExprInput.view "ratio" state.ratio UpdateRatio
        ]



---- COMPUTATIONS


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
                        (state |> PointMenu.selectedPoint 0 |> Maybe.map Tuple.first)
                        (state |> PointMenu.selectedPoint 1 |> Maybe.map Tuple.first)

                Nothing ->
                    Nothing

        _ ->
            Nothing


ratio : Data -> State -> Vec2 -> Vec2 -> Position -> Float
ratio data state firstPosition lastPosition cursorPosition =
    let
        deltaAnchors =
            lastPosition |> flip sub firstPosition

        deltaCursor =
            Position.toVec cursorPosition |> flip sub firstPosition

        projection =
            project deltaCursor deltaAnchors

        pointPosition =
            projection
                |> add firstPosition

        ratio =
            (pointPosition |> flip sub firstPosition |> length)
                / (lastPosition |> flip sub firstPosition |> length)
    in
    if haveSameDirection projection deltaAnchors then
        ratio
    else
        -1 * ratio


firstPosition : Data -> State -> Maybe Vec2
firstPosition data state =
    state
        |> PointMenu.selectedPoint 0
        |> Maybe.map Tuple.first
        |> position data state


lastPosition : Data -> State -> Maybe Vec2
lastPosition data state =
    state
        |> PointMenu.selectedPoint 1
        |> Maybe.map Tuple.first
        |> position data state


position : Data -> State -> Maybe (Id Point) -> Maybe Vec2
position data state maybeId =
    maybeId
        |> Maybe.andThen (flip Store.get data.store)
        |> Maybe.andThen (Point.position data.store data.variables)
