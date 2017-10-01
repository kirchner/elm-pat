module Tools.ExtendPiece
    exposing
        ( State
        , init
        , svg
        )

import Data.Piece as Piece exposing (..)
import Data.Point as Point exposing (Point)
import Data.Position as Position
import Data.Store as Store exposing (Id, Store)
import Svg exposing (Svg)
import Svgs.Extra as Extra
import Svgs.SelectPoint as SelectPoint
import Svgs.UpdateMouse as UpdateMouse
import Tools.Callbacks exposing (Callbacks)
import Tools.Data exposing (Data)


type alias State =
    { piece : Id Piece
    , segment : Id Point
    }


init : Id Piece -> Id Point -> State
init piece segment =
    { piece = piece
    , segment = segment
    }


svg : Callbacks msg -> Data -> State -> Svg msg
svg callbacks data state =
    [ lineSegments data state
    , Just (UpdateMouse.svg Nothing callbacks.updateCursorPosition data)
    , Just <|
        SelectPoint.svg callbacks.focusPoint
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
        , Store.get state.piece data.pieceStore
            |> Maybe.andThen (Piece.next state.segment)
        )
    of
        ( Just position, _, Just next ) ->
            let
                a =
                    Point.positionById data.store data.variables state.segment

                b =
                    Position.toVec position

                c =
                    Point.positionById data.store data.variables next
            in
            case ( a, c ) of
                ( Just a, Just c ) ->
                    Just <|
                        Svg.g []
                            [ Extra.drawLineSegment a b
                            , Extra.drawLineSegment b c
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
                            [ Extra.drawLineSegment a b
                            , Extra.drawLineSegment b c
                            ]

                _ ->
                    Nothing

        _ ->
            Nothing
