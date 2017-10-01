module Tools.CircleIntersection
    exposing
        ( Msg
        , State
        , init
        , svg
        , update
        , view
        )

import Data.Expr as Expr exposing (E)
import Data.Point as Point exposing (Choice(..), Point)
import Data.Store as Store exposing (Id, Store)
import Html exposing (Html, map)
import Math.Vector2 exposing (..)
import Styles.Colors as Colors
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svgs.Extra as Extra
import Svgs.UpdateMouse as UpdateMouse
import Tools.Callbacks exposing (Callbacks)
import Tools.Data exposing (Data)
import Tools.PointMenu as PointMenu
import Views.ExprInput as ExprInput
import Views.Switch as Switch
import Views.Tool as Tool


type alias State =
    { firstRadius : Maybe E
    , lastRadius : Maybe E
    , choice : Choice
    , points : PointMenu.SelectablePoints
    }


init : Data -> State
init data =
    { firstRadius = Nothing
    , lastRadius = Nothing
    , choice = LeftMost
    , points = PointMenu.init 2 data
    }



---- UPDATE


type Msg
    = UpdateFirstRadius String
    | UpdateLastRadius String
    | UpdateChoice Int
    | PointMenuMsg PointMenu.Msg


update : Callbacks msg -> Msg -> State -> ( State, Cmd Msg, Maybe msg )
update callbacks msg state =
    case msg of
        UpdateFirstRadius string ->
            ( { state | firstRadius = Expr.parse string }
            , Cmd.none
            , Nothing
            )

        UpdateLastRadius string ->
            ( { state | lastRadius = Expr.parse string }
            , Cmd.none
            , Nothing
            )

        UpdateChoice id ->
            ( case id of
                0 ->
                    { state | choice = LeftMost }

                1 ->
                    { state | choice = RightMost }

                _ ->
                    state
            , Cmd.none
            , Nothing
            )

        PointMenuMsg msg ->
            PointMenu.update callbacks.selectPoint PointMenuMsg msg state



---- SVG


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
                [ Extra.drawSelector Extra.Solid Colors.red firstPosition
                , drawCircle firstPosition firstRadius
                , Extra.drawSelector Extra.Solid Colors.red lastPosition
                , drawCircle lastPosition lastRadius
                , Extra.drawLine firstPosition lastPosition
                , UpdateMouse.svg addPoint
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



---- VIEW


view : Callbacks msg -> Data -> State -> Html Msg
view callbacks data state =
    let
        choices =
            [ "a", "b" ]

        switchState =
            case state.choice of
                LeftMost ->
                    0

                RightMost ->
                    1
    in
    [ PointMenu.view 0 state |> Html.map PointMenuMsg
    , ExprInput.view "first radius" state.firstRadius UpdateFirstRadius
    , PointMenu.view 1 state |> Html.map PointMenuMsg
    , ExprInput.view "last radius" state.lastRadius UpdateLastRadius
    , Switch.view choices switchState UpdateChoice
    ]
        |> Tool.view callbacks data state point



---- COMPUTATIONS


point : Data -> State -> Maybe Point
point data state =
    case
        ( state |> PointMenu.selectedPoint 0 |> Maybe.map Tuple.first
        , state.firstRadius
        , state |> PointMenu.selectedPoint 1 |> Maybe.map Tuple.first
        , state.lastRadius
        )
    of
        ( Just first, Just firstRadius, Just last, Just lastRadius ) ->
            Point.circleIntersection first firstRadius last lastRadius state.choice
                |> Just

        _ ->
            Nothing


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
