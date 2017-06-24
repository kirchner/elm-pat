module Types
    exposing
        ( Position
        , ViewPort
        , canvasToSvg
        , equals
        , svgToCanvas
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


type alias ViewPort =
    { offset : { x  : Int, y : Int }
    , width : Int
    , height : Int
    , zoom : Float
    }


canvasToSvg : ViewPort -> Position -> Position
canvasToSvg viewPort p =
    { x = p.x - viewPort.offset.x + (viewPort.width // 2)
    , y = p.y - viewPort.offset.y + (viewPort.height // 2)
    }


svgToCanvas : ViewPort -> Position -> Position
svgToCanvas viewPort p =
    { x = p.x + viewPort.offset.x - (viewPort.width // 2)
    , y = p.y + viewPort.offset.y - (viewPort.height // 2)
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
