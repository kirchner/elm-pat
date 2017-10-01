module Data.Position
    exposing
        ( Position
        , toVec
        , vec
        )

import Math.Vector2 exposing (..)


type alias Position =
    { x : Int
    , y : Int
    }


toVec : Position -> Vec2
toVec p =
    vec2 (toFloat p.x) (toFloat p.y)


vec : Int -> Int -> Vec2
vec x y =
    vec2 (toFloat x) (toFloat y)
