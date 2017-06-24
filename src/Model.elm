module Model
    exposing
        ( Drag
        , Model
        , File
        , Tool(..)
        , defaultModel
        )

{- internal -}

import Dict exposing (Dict)
import Expr
    exposing
        ( E
        , parse
        , parseVariable
        )
import FileBrowser exposing (FileBrowser)
import Keyboard.Extra as Keyboard exposing (Key)
import Piece exposing (Piece)
import Point exposing (Point)
import Store exposing (Id, Store)
import Tools.Absolute as Absolute
import Tools.Between as Between
import Tools.CircleIntersection as CircleIntersection
import Tools.Distance as Distance
import Tools.ExtendPiece as ExtendPiece
import Tools.Relative as Relative
import Types exposing (..)
import UndoList exposing (UndoList)


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
    , fileBrowser : FileBrowser
    , undoList : UndoList File
    }


type alias File =
    { store : Store Point
    , pieceStore : Store Piece
    , variables : Dict String E
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
        { offset =
            { x = 0, y = 0 }
        , width = 640
        , height = 640
        , zoom = 1
        }
    , drag = Nothing
    , cursorPosition = Nothing
    , focusedPoint = Nothing
    , pressedKeys = []
    , selectedPoints = []
    , fileBrowser = FileBrowser.defaultModel
    , undoList =
          UndoList.fresh
          { store = Store.empty
          , pieceStore = Store.empty
          , variables = Dict.empty
          , selectedPoints = []
          }
    }


type Tool
    = Absolute Absolute.State
    | Relative Relative.State
    | Distance Distance.State
    | Between Between.State
    | ExtendPiece ExtendPiece.State
    | CircleIntersection CircleIntersection.State
    | None


type alias Drag =
    { start : Position
    , current : Position
    }
