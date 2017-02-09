module Boundary
    exposing
        ( Boundary
        , boundary
        , fromList
        , toList
        , BoundaryId
        , defaultId
        )

-- internal

import Point exposing (..)


type Boundary
    = Boundary
        { first : PointId
        , second : PointId
        , rest : List PointId
        }


boundary : PointId -> PointId -> List PointId -> Boundary
boundary first second rest =
    Boundary
        { first = first
        , second = second
        , rest = rest
        }


fromList : List PointId -> Maybe Boundary
fromList points =
    case points of
        first :: second :: rest ->
            Just <|
                Boundary
                    { first = first
                    , second = second
                    , rest = rest
                    }

        _ ->
            Nothing


toList : Boundary -> List PointId
toList (Boundary info) =
    info.first :: info.second :: info.rest


type alias BoundaryId =
    Int


defaultId : BoundaryId
defaultId =
    0
