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
import Point exposing (Point)
import Store exposing (Id, Store)
import Types exposing (..)


type Piece
    = Piece { points : List (Id Point) }


fromList : Store Point -> Dict String E -> List (Id Point) -> Maybe Piece
fromList store variables points =
    let
        positions =
            points
                |> List.filterMap (Point.positionById store variables)

        pointCount =
            List.length points
    in
    if (pointCount == 0) || (List.length positions < pointCount) then
        Nothing
    else
        -- TODO: check for self intersections
        Just <| Piece { points = points }


toList : Piece -> List (Id Point)
toList (Piece piece) =
    piece.points


next : Id Point -> Piece -> Maybe (Id Point)
next id (Piece piece) =
    nextHelper id id piece.points


nextHelper : Id Point -> Id Point -> List (Id Point) -> Maybe (Id Point)
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


insertAfter : Store Point -> Dict String E -> Id Point -> Id Point -> Piece -> Piece
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


insertBefore : Store Point -> Dict String E -> Id Point -> Id Point -> Piece -> Piece
insertBefore store variables new reference piece =
    Debug.crash "implement insertBefore"
