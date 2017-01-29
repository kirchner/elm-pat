module Point exposing (..)

-- external

import Math.Vector2 exposing (..)


type Point
    = Origin OriginInfo
    | ADPoint ADPointInfo
    | DDPoint DDPointInfo


position : Point -> Vec2
position point =
    case point of
        Origin info ->
            info.position

        ADPoint info ->
            vec2 0 0

        DDPoint info ->
            vec2 0 0


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
