module Types
    exposing
        ( Id
        , Point(..)
        , PointStore
        , Position
        , Ratio
        , ViewPort
        , absolute
        , canvasToSvg
        , emptyStore
        , equals
        , firstId
        , position
        , positionById
        , relative
        , svgToCanvas
        , toVec
        , vec
        )

import Dict exposing (Dict)
import Expr exposing (..)
import Math.Vector2 exposing (..)


type alias Position =
    { x : Int
    , y : Int
    }


toVec : Position -> Vec2
toVec p =
    vec2 (toFloat p.x) (toFloat p.y)



{- point -}


type Point
    = Absolute E E
    | Relative Id E E
    | Between Id Id Ratio


type alias Ratio =
    Float


absolute : Vec2 -> Point
absolute v =
    Absolute (Number (getX v)) (Number (getY v))


relative : Id -> Vec2 -> Point
relative id v =
    Relative id (Number (getX v)) (Number (getY v))



{- point store -}


type alias PointStore =
    Dict Id Point


type alias Id =
    Int


emptyStore : PointStore
emptyStore =
    Dict.empty


firstId : Id
firstId =
    0



{- helpers -}


positionById : PointStore -> Dict String E -> Id -> Maybe Vec2
positionById store variables id =
    Dict.get id store
        |> Maybe.andThen (position store variables)


position : PointStore -> Dict String E -> Point -> Maybe Vec2
position store variables point =
    let
        lookUp id =
            Dict.get id store
                |> Maybe.andThen (position store variables)
    in
    case point of
        Absolute x y ->
            Maybe.map2 vec2
                (compute variables x)
                (compute variables y)

        Relative id p q ->
            Maybe.map3 (\v p q -> v |> add (vec2 p q))
                (lookUp id)
                (compute variables p)
                (compute variables q)

        Between idA idB ratio ->
            Maybe.map2
                (\v w -> sub w v |> scale ratio |> add w)
                (lookUp idA)
                (lookUp idB)


type alias ViewPort =
    { x : Int
    , y : Int
    , width : Int
    , height : Int
    }


canvasToSvg : ViewPort -> Position -> Position
canvasToSvg viewPort p =
    { x = p.x - viewPort.x
    , y = p.y - viewPort.y
    }


svgToCanvas : ViewPort -> Position -> Position
svgToCanvas viewPort p =
    { x = p.x + viewPort.x
    , y = p.y + viewPort.y
    }


vec : Int -> Int -> Vec2
vec x y =
    vec2 (toFloat x) (toFloat y)


equals : Maybe a -> a -> Bool
equals maybe a =
    case maybe of
        Just b ->
            if a == b then
                True
            else
                False

        _ ->
            False
