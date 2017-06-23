module Piece
    exposing
        ( Piece
        , fromList
        , insertAfter
        , insertBefore
        , toList
        )

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

        pointCount =
            List.length points
    in
    if (pointCount == 0) || (List.length positions < pointCount) then
        Nothing
    else
        -- TODO: check for self intersections
        Just <| Piece { points = points }


toList : Piece -> List Id
toList (Piece piece) =
    piece.points


insertAfter : PointStore -> Dict String E -> Id -> Id -> Piece -> Piece
insertAfter store variables new reference piece =
    Debug.crash "implement insertAfter"


insertBefore : PointStore -> Dict String E -> Id -> Id -> Piece -> Piece
insertBefore store variables new reference piece =
    Debug.crash "implement insertBefore"
