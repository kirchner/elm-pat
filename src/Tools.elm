module Tools exposing (..)

-- external

import Dict exposing (..)
import Math.Vector2 exposing (..)


-- internal

import Boundary exposing (Boundary)
import Cut exposing (..)
import Point exposing (..)
import ToolCombiner exposing (..)


-- point tool


type Tool
    = PointTool (ToolCombiner.Tool Msg Point)
    | CutTool (ToolCombiner.Tool Msg Cut)
    | BoundaryTool (ToolCombiner.Tool Msg Boundary)


stepPointTool : Msg -> ToolCombiner.Tool Msg Point -> Result Tool Point
stepPointTool msg tool =
    Result.mapError PointTool <|
        ToolCombiner.step msg tool


stepCutTool : Msg -> ToolCombiner.Tool Msg Cut -> Result Tool Cut
stepCutTool msg tool =
    Result.mapError CutTool <|
        ToolCombiner.step msg tool


stepBoundaryTool : Msg -> ToolCombiner.Tool Msg Boundary -> Result Tool Boundary
stepBoundaryTool msg tool =
    Result.mapError BoundaryTool <|
        ToolCombiner.step msg tool



-- msg


type Msg
    = InputPosition Vec2
    | SelectPoint PointId
    | NoOp



-- steps


positionTool : ToolCombiner.Tool Msg Vec2
positionTool =
    Tool positionAction


positionAction : Msg -> Result (ToolCombiner.Tool Msg Vec2) Vec2
positionAction msg =
    case msg of
        InputPosition v ->
            Ok v

        _ ->
            Err positionTool



--positionStep : Msg -> Maybe (Step Msg Vec2)
--positionStep msg =
--    case msg of
--        InputPosition v ->
--            Just (Done v)
--
--        _ ->
--            Nothing


selectPointTool : ToolCombiner.Tool Msg PointId
selectPointTool =
    Tool selectPointAction


selectPointAction : Msg -> Result (ToolCombiner.Tool Msg PointId) PointId
selectPointAction msg =
    case msg of
        SelectPoint id ->
            Ok id

        _ ->
            Err selectPointTool



--selectPointStep : Msg -> Maybe (Step Msg PointId)
--selectPointStep msg =
--    case msg of
--        SelectPoint id ->
--            Just (Done id)
--
--        _ ->
--            Nothing
-- origin tool


pointFromOriginTool : Tool
pointFromOriginTool =
    PointTool <|
        succeed pointFromOrigin
            |= positionTool


pointFromOrigin : Vec2 -> Point
pointFromOrigin v =
    Origin { position = v }



-- dd point tool


pointFromDDPointTool : Dict PointId Point -> Tool
pointFromDDPointTool points =
    PointTool <|
        succeed (pointFromDDPoint points)
            |= selectPointTool
            |= positionTool


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
            |= selectPointTool
            |= positionTool


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
            |= selectPointTool
            |= selectPointTool


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
            |= selectPointTool
            |= selectPointTool



--|= (zeroOrMore selectPointTool)


boundaryFromPoints : PointId -> PointId -> Boundary
boundaryFromPoints first second =
    Boundary.boundary first second []



--boundaryFromPoints : PointId -> PointId -> List PointId -> Boundary
--boundaryFromPoints =
--    Boundary.boundary
