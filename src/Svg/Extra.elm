module Svg.Extra
    exposing
        ( drawPoint
        , drawSelector
        , drawArrow
        , drawRectArrow
        , drawVerticalLine
        , drawHorizontalLine
        )

import Math.Vector2 exposing (..)
import Svg exposing (Svg)
import Svg.Attributes as Svg


{- internal -}

import View.Colors as Colors


drawPoint : Vec2 -> Svg msg
drawPoint v =
    Svg.circle
        [ Svg.cx (toString (getX v))
        , Svg.cy (toString (getY v))
        , Svg.r "1"
        , Svg.strokeWidth "0"
        , Svg.fill Colors.base0
        ]
        []


drawSelector : Vec2 -> Svg msg
drawSelector v =
    Svg.circle
        [ Svg.cx (toString (getX v))
        , Svg.cy (toString (getY v))
        , Svg.r "5"
        , Svg.strokeWidth "1"
        , Svg.stroke Colors.base1
        , Svg.fill "none"
        ]
        []


drawArrow : Vec2 -> Vec2 -> Svg msg
drawArrow v w =
    Svg.line
        [ Svg.x1 (toString (getX v))
        , Svg.y1 (toString (getY v))
        , Svg.x2 (toString (getX w))
        , Svg.y2 (toString (getY w))
        , Svg.strokeWidth "1"
        , Svg.stroke Colors.base1
        , Svg.strokeDasharray "5, 5"
        ]
        []


drawRectArrow : Vec2 -> Vec2 -> Svg msg
drawRectArrow v w =
    Svg.g []
        [ drawArrow v (vec2 (getX w) (getY v))
        , drawArrow (vec2 (getX w) (getY v)) w
        ]


drawHorizontalLine : Float -> Svg msg
drawHorizontalLine y =
    Svg.line
        [ Svg.x1 "-1000"
        , Svg.y1 (toString y)
        , Svg.x2 "1000"
        , Svg.y2 (toString y)
        , Svg.strokeWidth "1"
        , Svg.stroke Colors.base1
        , Svg.strokeDasharray "5, 5"
        ]
        []


drawVerticalLine : Float -> Svg msg
drawVerticalLine x =
    Svg.line
        [ Svg.x1 (toString x)
        , Svg.y1 "-1000"
        , Svg.x2 (toString x)
        , Svg.y2 "1000"
        , Svg.strokeWidth "1"
        , Svg.stroke Colors.base1
        , Svg.strokeDasharray "5, 5"
        ]
        []
