module Tools exposing (..)

-- external

import Dict exposing (..)
import Math.Vector2 exposing (..)


-- internal

import Agenda exposing (..)
import Boundary exposing (Boundary)
import Cut exposing (..)
import Point exposing (..)


-- point tool


type Tool
    = PointTool (Agenda Msg Point)
    | CutTool (Agenda Msg Cut)
    | BoundaryTool (Agenda Msg Boundary)



-- msg


type Msg
    = InputPosition Vec2
    | SelectPoint PointId
    | NoOp



-- steps


inputPosition : Agenda Msg Vec2
inputPosition =
    try updateInputPosition


updateInputPosition : Msg -> Maybe (Agenda Msg Vec2)
updateInputPosition msg =
    case msg of
        InputPosition v ->
            Just <| succeed v

        _ ->
            Nothing


selectPoint : Agenda Msg PointId
selectPoint =
    try updateSelectPoint


updateSelectPoint : Msg -> Maybe (Agenda Msg PointId)
updateSelectPoint msg =
    case msg of
        SelectPoint id ->
            Just <| succeed id

        _ ->
            Nothing



-- origin tool


pointFromOriginTool : Tool
pointFromOriginTool =
    PointTool <|
        succeed pointFromOrigin
            |= inputPosition


pointFromOrigin : Vec2 -> Point
pointFromOrigin v =
    Origin { position = v }



-- dd point tool


pointFromDDPointTool : Dict PointId Point -> Tool
pointFromDDPointTool points =
    PointTool <|
        succeed (pointFromDDPoint points)
            |= selectPoint
            |= inputPosition


pointFromDDPoint : Dict PointId Point -> PointId -> Vec2 -> Point
pointFromDDPoint points anchorId v =
    let
        anchorPosition =
            Maybe.withDefault (vec2 0 0) <|
                position points anchorId
    in
        DDPoint
            { anchor = anchorId
            , horizontalDistance =
                (getX v) - (getX anchorPosition)
            , verticalDistance =
                (getY v) - (getY anchorPosition)
            }



-- ad point tool


pointFromADPointTool : Dict PointId Point -> Tool
pointFromADPointTool points =
    PointTool <|
        succeed (pointFromADPoint points)
            |= selectPoint
            |= inputPosition


pointFromADPoint : Dict PointId Point -> PointId -> Vec2 -> Point
pointFromADPoint points anchorId v =
    let
        anchorPosition =
            Maybe.withDefault (vec2 0 0) <|
                position points anchorId
    in
        ADPoint
            { anchor = anchorId
            , angle =
                atan2
                    (getY <| sub anchorPosition v)
                    (getX <| sub anchorPosition v)
            , distance = length (sub anchorPosition v)
            }



-- cut tool


cutFromPointPointTool : Tool
cutFromPointPointTool =
    CutTool <|
        succeed cutFromPointPoint
            |= selectPoint
            |= selectPoint


cutFromPointPoint : PointId -> PointId -> Cut
cutFromPointPoint anchorA anchorB =
    { anchorA = anchorA
    , anchorB = anchorB
    }



-- boundary tool


boundaryFromPointsTool : Tool
boundaryFromPointsTool =
    BoundaryTool <|
        succeed boundaryFromPoints
            |= selectPoint
            |= selectPoint
            |= (zeroOrMore selectPoint)


boundaryFromPoints : PointId -> PointId -> List PointId -> Boundary
boundaryFromPoints =
    Boundary.boundary
