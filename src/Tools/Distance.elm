module Tools.Distance
    exposing
        ( Msg
        , State
        , init
        , svg
        , update
        , view
        )

import Data.Expr exposing (..)
import Data.Point as Point exposing (Point)
import Data.Position as Position
import Data.Store as Store exposing (Id, Store)
import FormatNumber
import Html exposing (Html, map)
import Keyboard.Extra as Keyboard
import Math.Vector2 exposing (..)
import Maybe.Extra as Maybe
import Styles.Colors as Colors exposing (..)
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svgs.Extra as Extra
import Svgs.SelectPoint as SelectPoint
import Svgs.UpdateMouse as UpdateMouse
import Tools.Callbacks exposing (Callbacks)
import Tools.Data exposing (Data)
import Tools.PointMenu as PointMenu
import Views.ExprInput as ExprInput
import Views.Tool as Tool


type alias State =
    { distance : Maybe E
    , angle : Maybe E
    , points : PointMenu.SelectablePoints
    }


init : Data -> State
init data =
    { distance = Nothing
    , angle = Nothing
    , points = PointMenu.init 1 data
    }



---- UPDATE


type Msg
    = UpdateDistance String
    | UpdateAngle String
    | PointMenuMsg PointMenu.Msg


update : Callbacks msg -> Msg -> State -> ( State, Cmd Msg, Maybe msg )
update callbacks msg state =
    case msg of
        UpdateDistance string ->
            ( { state | distance = parse string }
            , Cmd.none
            , Nothing
            )

        UpdateAngle string ->
            ( { state | angle = parse string }
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
            , circle data state
            , line data state
            , Just (UpdateMouse.svg addPoint callbacks.updateCursorPosition data)
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
                            [ Extra.drawPoint Colors.red pointPosition
                            , Extra.drawSelector Extra.Solid Colors.red pointPosition
                            , Extra.drawArrow anchorPosition pointPosition
                            , Extra.drawAngleArc Extra.defaultArcConfig anchorPosition pointPosition
                            , Extra.label
                                [ Svg.transform (Extra.translate (lerp 0.5 anchorPosition pointPosition))
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
            Extra.drawArrow anchorPosition
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



---- VIEW


view : Callbacks msg -> Data -> State -> Html Msg
view callbacks data state =
    let
        ( distancePlaceholder, anglePlaceholder ) =
            case ( data.cursorPosition, anchorPosition data state ) of
                ( Just mousePosition, Just anchorPosition ) ->
                    let
                        p =
                            pointPosition data state anchorPosition

                        w =
                            anchorPosition
                                |> flip sub (Position.toVec mousePosition)
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
    [ PointMenu.view 0 state |> Html.map PointMenuMsg
    , ExprInput.viewWithClear True distancePlaceholder state.distance UpdateDistance
    , ExprInput.viewWithClear True anglePlaceholder state.angle UpdateAngle
    ]
        |> Tool.view callbacks data state point



---- COMPUTATIONS


point : Data -> State -> Maybe Point
point data state =
    let
        cursorPosition =
            data.cursorPosition
                |> Maybe.map (\{ x, y } -> vec2 (toFloat x) (toFloat y))

        anchorId =
            state
                |> PointMenu.selectedPoint 0
                |> Maybe.map Tuple.first

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
    Maybe.map3 Point.distance anchorId distance angle


anchorPosition : Data -> State -> Maybe Vec2
anchorPosition data state =
    state
        |> PointMenu.selectedPoint 0
        |> Maybe.map Tuple.first
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
