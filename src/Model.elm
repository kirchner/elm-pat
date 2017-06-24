module Model
    exposing
        ( Model
        , defaultModel
        , Tool(..)
        , Drag
        )

{- internal -}

import Dict exposing (Dict)
import Expr
    exposing
        ( E
        , parse
        , parseVariable
        )
import Keyboard.Extra as Keyboard exposing (Key)
import Math.Vector2 exposing (..)
import Mouse
import Piece exposing (Piece)
import Point exposing (Point)
import Set exposing (Set)
import Task
import Tools.Absolute as Absolute
import Tools.Common
    exposing
        ( Callbacks
        , Data
        )
import Tools.Distance as Distance
import Tools.ExtendPiece as ExtendPiece
import Tools.Relative as Relative
import Types exposing (..)
import Window
import Store exposing (Id, Store)


type alias Model =
    { store : Store Point
    , pieceStore : Store Piece
    , variables : Dict String E
    , newName : Maybe String
    , newValue : Maybe E
    , tool : Tool
    , viewPort : ViewPort
    , drag : Maybe Drag
    , cursorPosition : Maybe Position
    , focusedPoint : Maybe (Id Point)
    , pressedKeys : List Key
    , selectedPoints : List (Id Point)
    }


defaultModel : Model
defaultModel =
    { store = Store.empty
    , pieceStore = Store.empty
    , variables = Dict.empty
    , newName = Nothing
    , newValue = Nothing
    , tool = None
    , viewPort =
        { x = -320
        , y = -320
        , width = 640
        , height = 640
        }
    , drag = Nothing
    , cursorPosition = Nothing
    , focusedPoint = Nothing
    , pressedKeys = []
    , selectedPoints = []
    }


type Tool
    = Absolute Absolute.State
    | Relative Relative.State
    | Distance Distance.State
    | ExtendPiece ExtendPiece.State
    | None


type alias Drag =
    { start : Position
    , current : Position
    }
