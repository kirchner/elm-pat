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
import Point


type Piece
    = Piece { points : List Point.Id }


fromList : Point.Store -> Dict String E -> List Point.Id -> Maybe Piece
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


toList : Piece -> List Point.Id
toList (Piece piece) =
    piece.points


next : Point.Id -> Piece -> Maybe Point.Id
next id (Piece piece) =
    nextHelper Point.firstId id piece.points


nextHelper : Point.Id -> Point.Id -> List Point.Id -> Maybe Point.Id
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


insertAfter : Point.Store -> Dict String E -> Point.Id -> Point.Id -> Piece -> Piece
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


insertBefore : Point.Store -> Dict String E -> Point.Id -> Point.Id -> Piece -> Piece
insertBefore store variables new reference piece =
    Debug.crash "implement insertBefore"
