module Piece
    exposing
        ( Piece
        , fromList
        , insertAfter
        , insertBefore
        , next
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


next : Id -> Piece -> Maybe Id
next id (Piece piece) =
    nextHelper firstId id piece.points


nextHelper : Id -> Id -> List Id -> Maybe Id
nextHelper firstId id points =
    case points of
        first :: second :: rest ->
            if id == first then
                Just second
            else
                nextHelper firstId id (second :: rest)

        last :: [] ->
            if id == last then
                Just firstId
            else
                Nothing

        _ ->
            Nothing


insertAfter : PointStore -> Dict String E -> Id -> Id -> Piece -> Piece
insertAfter store variables new reference (Piece piece) =
    -- TODO: check for self intersections
    let
        newPoints =
            piece.points
                |> List.foldl insert []

        insert id list =
            if id == reference then
                new :: id :: list
            else
                id :: list
    in
    Piece { points = newPoints }


insertBefore : PointStore -> Dict String E -> Id -> Id -> Piece -> Piece
insertBefore store variables new reference piece =
    Debug.crash "implement insertBefore"
