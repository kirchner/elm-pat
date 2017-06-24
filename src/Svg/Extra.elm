module Svg.Extra
    exposing
        ( ArcConfig
        , StrokeStyle(..)
        , defaultArcConfig
        , drawAngleArc
        , drawArrow
        , drawHorizontalLine
        , drawLine
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
import Svg exposing (Svg, path)
import Svg.Attributes as Svg
import Svg.Events as Svg
import VirtualDom


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


drawLine : Vec2 -> Vec2 -> Svg msg
drawLine v w =
    let
        delta =
            w
                |> sub v
                |> normalize

        newV =
            delta
                |> scale 100000
                |> add v

        newW =
            delta
                |> scale -100000
                |> add w
    in
    Svg.line
        [ Svg.x1 (toString (getX newV))
        , Svg.y1 (toString (getY newV))
        , Svg.x2 (toString (getX newW))
        , Svg.y2 (toString (getY newW))
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
    let
        line =
            w |> flip sub v

        length =
            line |> Math.Vector2.length

        angle =
            atan2 (getY line) (getX line) * 180 / Basics.pi
    in
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
        , Svg.rect
            [ Svg.x (toString (getX v - 5))
            , Svg.y (toString (getY v - 5))
            , Svg.width (toString (length + 10))
            , Svg.height "10"
            , Svg.strokeWidth "0"
            , Svg.fill "transparent"
            , Svg.onClick callback
            , VirtualDom.attribute "transform-origin"
                (toString (getX v)
                    ++ "px "
                    ++ toString (getY v)
                    ++ "px"
                )
            , Svg.transform ("rotate(" ++ toString angle ++ ")")
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


translate : Vec2 -> String
translate u =
    translate2 (getX u) (getY u)


translate2 : x -> y -> String
translate2 x y =
    "translate(" ++ toString x ++ "," ++ toString y ++ ")"


type alias ArcConfig =
    { radius : Float
    , label : Bool
    }


defaultArcConfig : ArcConfig
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
        [ path
            [ Svg.d <|
                String.join " "
                    [ "M0,0"
                    , "h" ++ toString config.radius
                    , "A" ++ toString config.radius ++ "," ++ toString config.radius
                    , if radians < 0 then
                        "0 0,1"
                      else
                        "0 0,0"
                    , toString x ++ "," ++ toString y
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
