module Tools.Data exposing (..)

import Data.Expr exposing (E)
import Data.Piece as Piece exposing (Piece)
import Data.Point exposing (Point)
import Data.Position as Position exposing (Position)
import Data.Store as Store exposing (Id, Store)
import Data.ViewPort as ViewPort exposing (ViewPort)
import Dict exposing (Dict)
import Keyboard.Extra exposing (Key)


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
