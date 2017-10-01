module Data.ViewPort
    exposing
        ( ViewPort
        , canvasToSvg
        , default
        , resize
        , setZoom
        , svgToCanvas
        , virtualHeight
        , virtualWidth
        )

import Data.Position exposing (Position)


type alias ViewPort =
    { offset : { x : Int, y : Int }
    , width : Int
    , height : Int
    , zoom : Float
    }


default : ViewPort
default =
    { offset =
        { x = 0, y = 0 }
    , width = 640
    , height = 640
    , zoom = 1
    }


resize : Int -> Int -> ViewPort -> ViewPort
resize width height viewPort =
    { viewPort
        | width = width
        , height = height
    }


setZoom : Float -> ViewPort -> ViewPort
setZoom zoom viewPort =
    { viewPort | zoom = zoom }


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
