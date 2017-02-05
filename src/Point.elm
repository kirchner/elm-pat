module Point exposing (..)

-- external

import Dict exposing (Dict)
import Math.Vector2 exposing (..)


type Point
    = Origin OriginInfo
    | ADPoint ADPointInfo
    | DDPoint DDPointInfo


position : Dict PointId Point -> PointId -> Maybe Vec2
position points id =
    case Dict.get id points of
        Just (Origin info) ->
            Just info.position

        Just (ADPoint info) ->
            let
                anchorPosition =
                    position points info.anchor

                delta =
                    scale (-1 * info.distance) <|
                        vec2 (cos info.angle) (sin info.angle)
            in
                Maybe.map (add delta) anchorPosition

        Just (DDPoint info) ->
            let
                anchorPosition =
                    position points info.anchor

                delta =
                    vec2
                        info.horizontalDistance
                        info.verticalDistance
            in
                Maybe.map (add delta) anchorPosition

        Nothing ->
            Nothing


type alias PointId =
    Int


defaultId : PointId
defaultId =
    0


nextId : PointId -> PointId
nextId =
    (+) 1


type alias OriginInfo =
    { position : Vec2
    }


type alias ADPointInfo =
    { anchor : PointId
    , angle : Float
    , distance : Float
    }


type alias DDPointInfo =
    { anchor : PointId
    , horizontalDistance : Float
    , verticalDistance : Float
    }
