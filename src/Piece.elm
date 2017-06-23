module Piece exposing (Piece)

import Dict exposing (Dict)
import Expr exposing (..)
import Types exposing (..)


type Piece
    = Piece { points : List Id }


fromList : PointStore -> Dict String E -> List Id -> Maybe Piece
fromList store variables points =
    let
        positions =
            points
                |> List.filterMap (positionById store variables)
    in
    if List.length positions < List.length points then
        Nothing
    else
        Debug.crash "implement fromList"


toList : Piece -> List Id
toList piece =
    Debug.crash "implement toList"


insertAfter : PointStore -> Dict String E -> Id -> Id -> Piece -> Piece
insertAfter store variables new reference piece =
    Debug.crash "implement insertAfter"


insertBefore : PointStore -> Dict String E -> Id -> Id -> Piece -> Piece
insertBefore store variables new reference piece =
    Debug.crash "implement insertBefore"
