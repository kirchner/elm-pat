module Tools.Common
    exposing
        ( Callbacks
        , Data
        , exprInput
        , exprInput_
        , svgSelectPoint
        , svgUpdateMouse
        , view
        )

import Dict exposing (Dict)
import Events
import Expr exposing (..)
import Html exposing (Html, map)
import Html.Attributes as Html
import Html.Events as Html
import Keyboard.Extra exposing (Key)
import Math.Vector2 exposing (..)
import Maybe.Extra as Maybe
import Piece exposing (..)
import Point exposing (Point)
import Store exposing (Id, Store)
import Styles.Colors as Colors
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg
import Svg.Extra as Svg
import Tools.Styles exposing (..)
import Types exposing (..)
import Views.Common exposing (iconSmall)


type alias Data =
    { store : Store Point
    , pieceStore : Store Piece
    , variables : Dict String E
    , viewPort : ViewPort
    , cursorPosition : Maybe Position
    , focusedPoint : Maybe (Id Point)
    , pressedKeys : List Key
    , selectedPoints : List (Id Point)
    }


type alias Callbacks msg =
    { addPoint : Point -> msg
    , updateCursorPosition : Maybe Position -> msg
    , focusPoint : Maybe (Id Point) -> msg
    , selectPoint : Maybe (Id Point) -> msg
    , clearSelection : msg
    , extendPiece : Id Piece -> Id Point -> Maybe (Id Point) -> msg
    }



{- svgs -}


svgUpdateMouse : Maybe msg -> (Maybe Position -> msg) -> Data -> Svg msg
svgUpdateMouse mouseClicked updateCursorPosition data =
    Svg.rect
        ([ Svg.x (toString data.viewPort.x)
         , Svg.y (toString data.viewPort.y)
         , Svg.width (toString data.viewPort.width)
         , Svg.height (toString data.viewPort.height)
         , Svg.fill "transparent"
         , Svg.strokeWidth "0"
         , Events.onMove (updateCursorPosition << Just)
         , Svg.onMouseOut (updateCursorPosition Nothing)
         ]
            ++ (mouseClicked
                    |> Maybe.map Svg.onClick
                    |> Maybe.toList
               )
        )
        []


svgSelectPoint :
    (Maybe (Id Point) -> msg)
    -> (Maybe (Id Point) -> msg)
    -> Data
    -> Svg msg
svgSelectPoint focusPoint selectPoint data =
    Store.toList data.store
        |> List.filterMap (pointSelector_ focusPoint selectPoint data)
        |> Svg.g []


pointSelector_ :
    (Maybe (Id Point) -> msg)
    -> (Maybe (Id Point) -> msg)
    -> Data
    -> ( Id Point, Point )
    -> Maybe (Svg msg)
pointSelector_ focusPoint selectPoint data ( id, point ) =
    let
        draw v =
            Svg.g []
                [ Svg.circle
                    [ Svg.cx (toString (getX v))
                    , Svg.cy (toString (getY v))
                    , Svg.r "5"
                    , Svg.fill "transparent"
                    , Svg.strokeWidth "0"
                    , Svg.onClick (selectPoint (Just id))
                    , Svg.onMouseOver (focusPoint (Just id))
                    , Svg.onMouseOut (focusPoint Nothing)
                    ]
                    []
                , if id |> equals data.focusedPoint then
                    Svg.drawSelector Svg.Solid Colors.red v
                  else
                    Svg.g [] []
                ]
    in
    Point.position data.store data.variables point
        |> Maybe.map draw


drawCursor : Vec2 -> Svg msg
drawCursor position =
    let
        ( x, y ) =
            toTuple position
    in
    Svg.g []
        [ Svg.drawPoint Colors.base0 (vec2 x y)
        , Svg.drawSelector Svg.Solid Colors.base1 (vec2 x y)
        ]



{- views -}


view :
    Callbacks msg
    -> Data
    -> state
    -> (Data -> state -> Maybe Point)
    -> List (Html msg)
    -> Html msg
view callbacks data state point elements =
    let
        addPoint =
            point data state |> Maybe.map callbacks.addPoint

        button =
            case addPoint of
                Just callback ->
                    [ iconSmall "add" callback ]

                Nothing ->
                    []
    in
    Html.div
        [ class [ ToolBox ] ]
        elements


exprInput : String -> Maybe E -> (String -> msg) -> Html msg
exprInput name e callback =
    let
        deleteIcon =
            if e /= Nothing then
                [ Html.div
                    [ class [ IconContainer ] ]
                    [ iconSmall "delete" (callback "") ]
                ]
            else
                []
    in
    Html.div
        [ class [ ValueContainer ] ]
        ([ Html.input
            [ Html.onInput callback
            , Html.placeholder
                (e
                    |> Maybe.map print
                    |> Maybe.withDefault name
                )
            , class [ Textfield ]
            ]
            []
         ]
            ++ deleteIcon
        )


exprInput_ : Bool -> String -> Maybe E -> (String -> msg) -> Html msg
exprInput_ autoFocus name e callback =
    let
        deleteIcon =
            if e /= Nothing then
                [ Html.div
                    [ class [ IconContainer ] ]
                    [ iconSmall "delete" (callback "") ]
                ]
            else
                []
    in
    Html.div
        [ class [ ValueContainer ] ]
        ([ Html.input
            [ Html.onInput callback
            , Html.placeholder
                (e
                    |> Maybe.map print
                    |> Maybe.withDefault name
                )
            , Html.autofocus autoFocus
            , class [ Textfield ]
            ]
            []
         ]
            ++ deleteIcon
        )
