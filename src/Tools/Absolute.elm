module Tools.Absolute
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
import Data.Position exposing (Position)
import Dict exposing (Dict)
import Html exposing (Html)
import Math.Vector2 exposing (..)
import Maybe.Extra as Maybe
import Styles.Colors as Colors exposing (..)
import Svg exposing (Svg)
import Svg.Lazy as Svg
import Svgs.Extra as Extra
import Svgs.UpdateMouse as UpdateMouse
import Tools.Callbacks exposing (Callbacks)
import Tools.Data exposing (Data)
import Views.ExprInput as ExprInput
import Views.Tool as Tool


type alias State =
    { x : Maybe E
    , y : Maybe E
    }


init : State
init =
    { x = Nothing
    , y = Nothing
    }



---- UPDATE


type Msg
    = UpdateX String
    | UpdateY String


update : Msg -> State -> State
update msg state =
    case msg of
        UpdateX string ->
            { state | x = parse string }

        UpdateY string ->
            { state | y = parse string }



---- SVG


svg : Callbacks msg -> (State -> msg) -> Data -> State -> Svg msg
svg callbacks updateState data state =
    let
        addPoint =
            point data state |> Maybe.map callbacks.addPoint
    in
    [ Svg.lazy3 draw data.variables data.cursorPosition state
    , UpdateMouse.svg addPoint callbacks.updateCursorPosition data.viewPort
    ]
        |> Svg.g []


draw : Dict String E -> Maybe Position -> State -> Svg msg
draw variables cursorPosition state =
    [ newPoint variables cursorPosition state
    , horizontalLine variables state
    , verticalLine variables state
    ]
        |> List.filterMap identity
        |> Svg.g []


newPoint : Dict String E -> Maybe Position -> State -> Maybe (Svg msg)
newPoint variables cursorPosition state =
    let
        draw x y =
            Svg.g []
                [ Extra.drawPoint Colors.red (vec2 x y)
                , Extra.drawSelector Extra.Solid Colors.red (vec2 x y)
                ]

        xState =
            state.x |> Maybe.andThen (compute variables)

        yState =
            state.y |> Maybe.andThen (compute variables)

        xCursor =
            cursorPosition
                |> Maybe.map (\{ x, y } -> toFloat x)

        yCursor =
            cursorPosition
                |> Maybe.map (\{ x, y } -> toFloat y)

        x =
            xCursor |> Maybe.or xState

        y =
            yCursor |> Maybe.or yState
    in
    Maybe.map2 draw x y


horizontalLine : Dict String E -> State -> Maybe (Svg msg)
horizontalLine variables state =
    state.y
        |> Maybe.andThen (compute variables)
        |> Maybe.map Extra.drawHorizontalLine


verticalLine : Dict String E -> State -> Maybe (Svg msg)
verticalLine variables state =
    state.x
        |> Maybe.andThen (compute variables)
        |> Maybe.map Extra.drawVerticalLine



---- VIEW


view : Callbacks msg -> Data -> State -> Html Msg
view callbacks data state =
    [ ExprInput.view "x-coordinate" state.x UpdateX
    , ExprInput.view "y-coordinate" state.y UpdateY
    ]
        |> Tool.view callbacks data state point



---- COMPUTATIONS


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
    Maybe.map2 Point.absolute x y
