module Tools.Styles exposing (..)

import Css exposing (..)
import Css.Namespace exposing (namespace)
import Html.CssHelpers exposing (withNamespace)
import Styles.Colors exposing (..)


{- css -}


type Class
    = ToolBox
    | ValueContainer
    | Textfield
    | IconContainer
    | Button


{ id, class, classList } =
    withNamespace "tool__"


css =
    (stylesheet << namespace "tool__")
        [ Css.class ToolBox
            [ backgroundColor (hex base2)
            , property "pointer-events" "auto"
            , displayFlex
            ]
        , Css.class ValueContainer
            [ position relative
            , displayFlex
            , paddingLeft (rem 0.3)
            , paddingRight (rem 0.3)
            , margin (px 2)
            , border zero
            , hover
                [ margin zero
                , border3 (px 2) solid (hex base3)
                ]
            ]
        , Css.class Textfield
            [ borderColor transparent
            , fontFamily monospace
            , fontSize (rem 1)
            , lineHeight (rem 1)
            , width (rem 20)
            , backgroundColor transparent
            , focus
                [ outline none ]
            ]
        , Css.class IconContainer
            [ position absolute
            , right (rem 0.3)
            , height (pct 100)
            , displayFlex
            , flexFlow1 column
            , justifyContent spaceAround
            ]
        , Css.class Button
            [ textAlign center
            , width (rem 10)
            , height (rem 2)
            , lineHeight (rem 2)
            , color (hex base0)
            , backgroundColor (hex base03)
            , cursor pointer
            , hover
                [ backgroundColor (hex base02) ]
            ]
        ]


rem =
    Css.rem
