module Tools exposing (..)

-- external

import Dict exposing (..)
import Math.Vector2 exposing (..)


-- internal

import Cut exposing (..)
import Point exposing (..)
import ToolCombiner exposing (..)


-- point tool


type Tool
    = PointTool (ToolCombiner.Tool Msg Point)
    | CutTool (ToolCombiner.Tool Msg Cut)


stepPointTool : Msg -> ToolCombiner.Tool Msg Point -> Result Tool Point
stepPointTool msg tool =
    Result.mapError PointTool <|
        ToolCombiner.step msg tool


stepCutTool : Msg -> ToolCombiner.Tool Msg Cut -> Result Tool Cut
stepCutTool msg tool =
    Result.mapError CutTool <|
        ToolCombiner.step msg tool



-- msg


type Msg
    = InputPosition Vec2
    | SelectPoint PointId



-- steps


positionTool : ToolCombiner.Tool Msg Vec2
positionTool =
    Tool positionStep


positionStep : Msg -> Maybe (Step Msg Vec2)
positionStep msg =
    case msg of
        InputPosition v ->
            Just (Done v)

        _ ->
            Nothing


selectPointTool : ToolCombiner.Tool Msg PointId
selectPointTool =
    Tool selectPointStep


selectPointStep : Msg -> Maybe (Step Msg PointId)
selectPointStep msg =
    case msg of
        SelectPoint id ->
            Just (Done id)

        _ ->
            Nothing



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


cutFromPointPointTool : Dict PointId Point -> Tool
cutFromPointPointTool points =
    CutTool <|
        succeed (cutFromPointPoint points)
            |= selectPointTool
            |= selectPointTool


cutFromPointPoint : Dict PointId Point -> PointId -> PointId -> Cut
cutFromPointPoint points anchorA anchorB =
    { anchorA = anchorA
    , anchorB = anchorB
    }
