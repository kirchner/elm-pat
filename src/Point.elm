module Point exposing (..)

-- external

import Dict exposing (Dict)
import Math.Vector2 exposing (..)


type Point
    = Origin OriginInfo
    | ADPoint ADPointInfo
    | DDPoint DDPointInfo


position : Dict PointId Point -> Point -> Vec2
position points point =
    case point of
        Origin info ->
            info.position

        ADPoint info ->
            vec2 0 0

        DDPoint info ->
            let
                anchorPosition =
                    Maybe.withDefault (vec2 0 0) <|
                        Maybe.map (position points) <|
                            Dict.get info.anchor points
            in
                add anchorPosition <|
                    vec2
                        info.horizontalDistance
                        info.verticalDistance


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
