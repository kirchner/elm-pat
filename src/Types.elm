module Types
    exposing
        ( ViewPort
        , Position
        , canvasToSvg
        , equals
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
