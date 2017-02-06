module Tool exposing (..)

-- external

import Dict exposing (..)
import Math.Vector2 exposing (..)


-- internal

import Point exposing (..)


-- tool as a parser


type Tool msg result
    = Tool (msg -> Maybe (Step msg result))
    | Succeed result


type Step msg result
    = Cont (Tool msg result)
    | Done result


step : msg -> Tool msg result -> Result (Tool msg result) result
step msg tool =
    case tool of
        Tool action ->
            case action msg of
                Just (Done result) ->
                    Ok result

                Just (Cont nextTool) ->
                    Err nextTool

                Nothing ->
                    Err (Tool action)

        Succeed result ->
            Ok result


succeed : result -> Tool msg result
succeed result =
    Succeed result


map : (a -> b) -> Tool msg a -> Tool msg b
map func tool =
    case tool of
        Tool action ->
            Tool <|
                \msg ->
                    case action msg of
                        Just (Done result) ->
                            Just (Done (func result))

                        Just (Cont nextTool) ->
                            Just (Cont (map func nextTool))

                        Nothing ->
                            Nothing

        Succeed result ->
            Succeed (func result)


map2 : (a -> b -> c) -> Tool msg a -> Tool msg b -> Tool msg c
map2 func toolA toolB =
    case toolA of
        Tool actionA ->
            Tool <|
                \msg ->
                    case actionA msg of
                        Just (Done resultA) ->
                            Just (Cont (map (func resultA) toolB))

                        Just (Cont nextToolA) ->
                            Just (Cont (map2 func nextToolA toolB))

                        Nothing ->
                            Nothing

        Succeed result ->
            map (func result) toolB


(|=) : Tool msg (a -> b) -> Tool msg a -> Tool msg b
(|=) toolFunc toolArg =
    map2 apply toolFunc toolArg


apply : (a -> b) -> a -> b
apply f a =
    f a



-- msg


type Msg
    = InputPosition Vec2
    | SelectPoint PointId



-- steps


positionStep : Tool Msg Vec2
positionStep =
    Tool <|
        \msg ->
            case msg of
                InputPosition v ->
                    Just (Done v)

                _ ->
                    Nothing


selectPointStep : Tool Msg PointId
selectPointStep =
    Tool <|
        \msg ->
            case msg of
                SelectPoint id ->
                    Just (Done id)

                _ ->
                    Nothing



-- origin tool


pointFromOriginTool : Tool Msg Point
pointFromOriginTool =
    succeed pointFromOrigin
        |= positionStep


pointFromOrigin : Vec2 -> Point
pointFromOrigin v =
    Origin { position = v }



-- dd point tool


pointFromDDPointTool : Dict PointId Point -> Tool Msg Point
pointFromDDPointTool points =
    succeed (pointFromDDPoint points)
        |= selectPointStep
        |= positionStep


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


pointFromADPointTool : Dict PointId Point -> Tool Msg Point
pointFromADPointTool points =
    succeed (pointFromADPoint points)
        |= selectPointStep
        |= positionStep


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
