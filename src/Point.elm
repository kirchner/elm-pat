module Point
    exposing
        ( Point
            ( Origin
            , ADPoint
            , DDPoint
            )
        , origin
        , adPoint
        , ddPoint
        , position
        , unsafePosition
        , PointId
        , defaultId
        , nextId
        )

-- external

import Dict exposing (Dict)
import Math.Vector2 exposing (..)


type Point
    = Origin OriginInfo
    | ADPoint ADPointInfo
    | DDPoint DDPointInfo


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


origin : Vec2 -> Point
origin p =
    Origin
        { position = p }


adPoint : Dict PointId Point -> PointId -> Vec2 -> Point
adPoint points id q =
    let
        p =
            unsafePosition points id
    in
        ADPoint
            { anchor = id
            , angle =
                atan2
                    (getY <| sub p q)
                    (getX <| sub p q)
            , distance = length (sub p q)
            }


ddPoint : Dict PointId Point -> PointId -> Vec2 -> Point
ddPoint points id q =
    let
        p =
            unsafePosition points id
    in
        DDPoint
            { anchor = id
            , horizontalDistance =
                (getX q) - (getX p)
            , verticalDistance =
                (getY q) - (getY p)
            }


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


unsafePosition : Dict PointId Point -> PointId -> Vec2
unsafePosition points id =
    case position points id of
        Just p ->
            p

        Nothing ->
            Debug.crash "unknown point id"


type alias PointId =
    Int


defaultId : PointId
defaultId =
    0


nextId : PointId -> PointId
nextId =
    (+) 1
