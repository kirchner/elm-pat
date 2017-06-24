module Types
    exposing
        ( Position
        , ViewPort
        , canvasToSvg
        , equals
        , svgToCanvas
        , toVec
        , vec
        , virtualHeight
        , virtualWidth
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
    { offset : { x : Int, y : Int }
    , width : Int
    , height : Int
    , zoom : Float
    }


virtualWidth : ViewPort -> Int
virtualWidth viewPort =
    toFloat viewPort.width * viewPort.zoom |> floor


virtualHeight : ViewPort -> Int
virtualHeight viewPort =
    toFloat viewPort.height * viewPort.zoom |> floor


canvasToSvg : ViewPort -> Position -> Position
canvasToSvg viewPort p =
    { x = p.x - viewPort.offset.x + (viewPort.width // 2)
    , y = p.y - viewPort.offset.y + (viewPort.height // 2)
    }


svgToCanvas : ViewPort -> Position -> Position
svgToCanvas viewPort p =
    let
        px =
            viewPort.zoom * toFloat p.x |> floor

        py =
            viewPort.zoom * toFloat p.y |> floor
    in
    { x = px + viewPort.offset.x - (virtualWidth viewPort // 2)
    , y = py + viewPort.offset.y - (virtualHeight viewPort // 2)
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
