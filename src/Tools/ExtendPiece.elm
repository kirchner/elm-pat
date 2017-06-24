module Tools.ExtendPiece
    exposing
        ( State
        , init
        , svg
        )

import Dict
import Piece exposing (..)
import Point exposing (Point)
import Styles.Colors as Colors
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg
import Svg.Extra as Svg
import Tools.Common as Tools
    exposing
        ( Callbacks
        , Data
        , svgSelectPoint
        , svgUpdateMouse
        )
import Types exposing (..)


type alias State =
    { piece : Int
    , segment : Int
    }


init : Int -> Int -> State
init piece segment =
    { piece = piece
    , segment = segment
    }


svg : Callbacks msg -> Data -> State -> Svg msg
svg callbacks data state =
    [ lineSegments data state
    , Just (svgUpdateMouse Nothing callbacks.updateCursorPosition data)
    , Just <|
        svgSelectPoint callbacks.focusPoint
            (callbacks.extendPiece state.piece state.segment)
            data
    ]
        |> List.filterMap identity
        |> Svg.g []


lineSegments : Data -> State -> Maybe (Svg msg)
lineSegments data state =
    case
        ( data.cursorPosition
        , data.focusedPoint
            |> Maybe.andThen (Point.positionById data.store data.variables)
        , Dict.get state.piece data.pieceStore
            |> Maybe.andThen (Piece.next state.segment)
        )
    of
        ( Just position, _, Just next ) ->
            let
                a =
                    Point.positionById data.store data.variables state.segment

                b =
                    toVec position

                c =
                    Point.positionById data.store data.variables next
            in
            case ( a, c ) of
                ( Just a, Just c ) ->
                    Just <|
                        Svg.g []
                            [ Svg.drawLineSegment a b
                            , Svg.drawLineSegment b c
                            ]

                _ ->
                    Nothing

        ( Nothing, Just b, Just next ) ->
            let
                a =
                    Point.positionById data.store data.variables state.segment

                c =
                    Point.positionById data.store data.variables next
            in
            case ( a, c ) of
                ( Just a, Just c ) ->
                    Just <|
                        Svg.g []
                            [ Svg.drawLineSegment a b
                            , Svg.drawLineSegment b c
                            ]

                _ ->
                    Nothing

        _ ->
            Nothing
