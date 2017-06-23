module Piece exposing (Piece)

import Dict exposing (Dict)
import Types exposing (..)


type Piece
    = Piece {}


fromList : PointStore -> Dict String Id -> List Id -> Maybe Piece
fromList store variables points =
    Debug.crash "implement fromList"


toList : Piece -> List Id
toList piece =
    Debug.crash "implement toList"


insertAfter : PointStore -> Dict String Id -> Id -> Id -> Piece -> Piece
insertAfter store variables new reference piece =
    Debug.crash "implement insertAfter"


insertBefore : PointStore -> Dict String Id -> Id -> Id -> Piece -> Piece
insertBefore store variables new reference piece =
    Debug.crash "implement insertBefore"
