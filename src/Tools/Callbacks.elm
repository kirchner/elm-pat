module Tools.Callbacks exposing (..)

import Data.Piece exposing (Piece)
import Data.Point exposing (Point)
import Data.Position exposing (Position)
import Data.Store exposing (Id)


type alias Callbacks msg =
    { addPoint : Point -> msg
    , updateCursorPosition : Maybe Position -> msg
    , focusPoint : Maybe (Id Point) -> msg
    , selectPoint : Maybe (Id Point) -> msg
    , clearSelection : msg
    , extendPiece : Id Piece -> Id Point -> Maybe (Id Point) -> msg
    }
