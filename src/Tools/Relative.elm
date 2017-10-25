module Tools.Relative
    exposing
        ( Msg
        , State
        , init
        , svg
        , update
        , view
        )

import Array exposing (Array)
import Data.Expr exposing (..)
import Data.Point as Point exposing (Point)
import Data.Store as Store exposing (Id, Store)
import Html exposing (Html, map)
import Math.Vector2 exposing (..)
import Maybe.Extra as Maybe
import Styles.Colors as Colors exposing (..)
import Svg exposing (Svg)
import Svgs.Extra as Extra
import Svgs.SelectPoint as SelectPoint
import Svgs.UpdateMouse as UpdateMouse
import Tools.Callbacks exposing (Callbacks)
import Tools.Data exposing (Data)
import Tools.PointMenu as PointMenu
import Views.ExprInput as ExprInput
import Views.Tool as Tool


type alias State =
    { x : Maybe E
    , y : Maybe E
    , points : PointMenu.SelectablePoints
    }


init : Data -> State
init data =
    { x = Nothing
    , y = Nothing
    , points = PointMenu.init 1 data
    }



---- UPDATE


type Msg
    = UpdateX String
    | UpdateY String
    | PointMenuMsg PointMenu.Msg


update : Callbacks msg -> Msg -> State -> ( State, Cmd Msg, Maybe msg )
update callbacks msg state =
    case msg of
        UpdateX string ->
            ( { state | x = parse string }
            , Cmd.none
            , Nothing
            )

        UpdateY string ->
            ( { state | y = parse string }
            , Cmd.none
            , Nothing
            )

        PointMenuMsg msg ->
            PointMenu.update callbacks.selectPoint PointMenuMsg msg state



---- SVG


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
            , Just (UpdateMouse.svg addPoint callbacks.updateCursorPosition data.viewPort)
            ]
                |> List.filterMap identity
                |> Svg.g []

        Nothing ->
            let
                selectPoint =
                    Maybe.map (\id -> PointMenu.selectPoint 0 id data state)
                        >> Maybe.withDefault state
                        >> updateState
            in
            [ SelectPoint.svg callbacks.focusPoint selectPoint data ]
                |> Svg.g []


newPoint : Data -> State -> Maybe (Svg msg)
newPoint data state =
    let
        draw anchorPosition =
            pointPosition data state anchorPosition
                |> Maybe.map
                    (\pointPosition ->
                        Svg.g []
                            [ Extra.drawPoint Colors.red pointPosition
                            , Extra.drawSelector Extra.Solid Colors.red pointPosition
                            , Extra.drawRectArrow anchorPosition pointPosition
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
            (\y -> Extra.drawHorizontalLine (y + getY anchorPosition))


verticalLine : Data -> State -> Vec2 -> Maybe (Svg msg)
verticalLine data state anchorPosition =
    state.x
        |> Maybe.andThen (compute data.variables)
        |> Maybe.map
            (\x -> Extra.drawVerticalLine (x + getX anchorPosition))



---- VIEW


view : Callbacks msg -> Data -> State -> Html Msg
view callbacks data state =
    [ PointMenu.view 0 state |> Html.map PointMenuMsg
    , ExprInput.view "horizontal distance" state.x UpdateX
    , ExprInput.view "vertical distance" state.y UpdateY
    ]
        |> Tool.view callbacks data state point



---- COMPUTATIONS


point : Data -> State -> Maybe Point
point data state =
    let
        anchorId =
            state.points
                |> Array.get 0
                |> Maybe.andThen .selected
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


anchorPosition : Data -> State -> Maybe Vec2
anchorPosition data state =
    state.points
        |> Array.get 0
        |> Maybe.andThen .selected
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
