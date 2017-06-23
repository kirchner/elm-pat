module Svg.Extra
    exposing
        ( ArcConfig
        , StrokeStyle(..)
        , defaultArcConfig
        , drawAngleArc
        , drawArrow
        , drawHorizontalLine
        , drawLineSegment
        , drawLineSegmentWith
        , drawPoint
        , drawRectArrow
        , drawSelector
        , drawVerticalLine
        , label
        , translate
        , translate2
        )

import FormatNumber
import Math.Vector2 exposing (..)
import Styles.Colors as Colors
import Svg as Svg_
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg


drawPoint : String -> Vec2 -> Svg msg
drawPoint color v =
    Svg.circle
        [ Svg.cx (toString (getX v))
        , Svg.cy (toString (getY v))
        , Svg.r "3.5"
        , Svg.strokeWidth "0"
        , Svg.fill color
        ]
        []


type StrokeStyle
    = Dashed
    | Solid


drawSelector : StrokeStyle -> String -> Vec2 -> Svg msg
drawSelector strokeStyle color v =
    Svg.circle
        [ Svg.cx (toString (getX v))
        , Svg.cy (toString (getY v))
        , Svg.r "7"
        , Svg.strokeWidth "1"
        , Svg.stroke color
        , Svg.fill "none"
        , case strokeStyle of
            Dashed ->
                Svg.strokeDasharray "5, 5"

            Solid ->
                Svg.strokeDasharray "none"
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


drawLineSegment : Vec2 -> Vec2 -> Svg msg
drawLineSegment v w =
    Svg.line
        [ Svg.x1 (toString (getX v))
        , Svg.y1 (toString (getY v))
        , Svg.x2 (toString (getX w))
        , Svg.y2 (toString (getY w))
        , Svg.strokeWidth "1"
        , Svg.stroke Colors.blue
        ]
        []


drawLineSegmentWith : msg -> Vec2 -> Vec2 -> Svg msg
drawLineSegmentWith callback v w =
    Svg.g []
        [ Svg.line
            [ Svg.x1 (toString (getX v))
            , Svg.y1 (toString (getY v))
            , Svg.x2 (toString (getX w))
            , Svg.y2 (toString (getY w))
            , Svg.strokeWidth "1"
            , Svg.stroke Colors.blue
            ]
            []
        , Svg.line
            [ Svg.x1 (toString (getX v))
            , Svg.y1 (toString (getY v))
            , Svg.x2 (toString (getX w))
            , Svg.y2 (toString (getY w))
            , Svg.strokeWidth "4"
            , Svg.stroke "transparent"
            , Svg.onClick callback
            ]
            []
        ]


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


translate u =
    translate2 (getX u) (getY u)


translate2 x y =
    "translate(" ++ toString x ++ "," ++ toString y ++ ")"


type alias ArcConfig =
    { radius : Float
    , label : Bool
    }


defaultArcConfig =
    { radius = 65
    , label = True
    }


drawAngleArc : ArcConfig -> Vec2 -> Vec2 -> Svg msg
drawAngleArc config anchorPosition pointPosition =
    let
        v =
            sub pointPosition anchorPosition

        radians =
            -(atan2 (getY v) (getX v))

        a =
            vec2 (cos radians) -(sin radians)
                |> scale config.radius

        ( x, y ) =
            ( getX a, getY a )

        format =
            FormatNumber.format
                { decimals = 2
                , thousandSeparator = " "
                , decimalSeparator = "."
                }
    in
    Svg.g
        [ Svg.transform (translate anchorPosition)
        ]
        [ Svg_.path
            [ Svg.d <|
                String.join " "
                    [ "M0,0"
                    , "h" ++ toString config.radius
                    , "A" ++ toString config.radius ++ "," ++ toString config.radius
                    , if radians < 0 then
                        "0 0,1"
                      else
                        "0 0,0"
                    , toString (floor x) ++ "," ++ toString (floor y)
                    , "z"
                    ]
            , Svg.stroke Colors.base0
            , Svg.fill "transparent"
            ]
            []
        , label
            [ Svg.transform (translate (vec2 10 -10))
            ]
            [ Svg.text (format (180 * radians / Basics.pi))
            ]
        ]


label : List (Svg.Attribute m) -> List (Svg m) -> Svg m
label options =
    Svg.text_
        (Svg.fontSize "14px"
            :: Svg.color Colors.base0
            :: options
        )
