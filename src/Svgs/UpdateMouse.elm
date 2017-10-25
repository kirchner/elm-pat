module Svgs.UpdateMouse exposing (svg)

import Data.Position exposing (Position)
import Data.ViewPort as ViewPort exposing (ViewPort)
import Events
import Maybe.Extra as Maybe
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg
import Tools.Data exposing (Data)


svg : Maybe msg -> (Maybe Position -> msg) -> ViewPort -> Svg msg
svg mouseClicked updateCursorPosition viewPort =
    Svg.rect
        ([ Svg.x (toString (viewPort.offset.x - (ViewPort.virtualWidth viewPort // 2)))
         , Svg.y (toString (viewPort.offset.y - (ViewPort.virtualHeight viewPort // 2)))
         , Svg.width (toString (ViewPort.virtualWidth viewPort))
         , Svg.height (toString (ViewPort.virtualHeight viewPort))
         , Svg.fill "transparent"
         , Svg.strokeWidth "0"
         , Events.onMove (updateCursorPosition << Just)
         , Svg.onMouseOut (updateCursorPosition Nothing)
         ]
            ++ (mouseClicked
                    |> Maybe.map Svg.onClick
                    |> Maybe.toList
               )
        )
        []
