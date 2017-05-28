module Tools.Styles exposing (..)

import Css exposing (..)
import Css.Namespace exposing (namespace)
import Html.CssHelpers exposing (withNamespace)
import View.Colors exposing (..)


{- css -}


type Class
    = ToolBox
    | Row
    | Column
    | IconButton
    | Icon
    | Textfield
    | Button
    | VariableName


{ id, class, classList } =
    withNamespace "absolute"


css =
    (stylesheet << namespace "absolute")
        [ Css.class ToolBox
            [ Css.backgroundColor (Css.hex base2)
            , Css.width (Css.rem 10)
            , Css.property "pointer-events" "auto"
            ]
        , Css.class Button
            [ textAlign center
            , width (Css.rem 10)
            , height (Css.rem 2)
            , lineHeight (Css.rem 2)
            , color (hex base0)
            , backgroundColor (hex base03)
            , cursor pointer
            , hover
                [ backgroundColor (hex base02) ]
            ]
        , Css.class Textfield
            [ borderColor transparent
            , fontFamily monospace
            , fontSize (Css.rem 1)
            , lineHeight (Css.rem 1)
            , width (Css.rem 4.8)
            , backgroundColor transparent
            , focus
                [ outline none
                , borderColor (hex base02)
                ]
            ]
        , Css.class Row
            [ displayFlex
            , flexFlow1 row

            --, justifyContent flexStart
            , width (Css.rem 10)
            , alignItems stretch
            ]
        , Css.class Column
            [ displayFlex
            , alignItems baseline
            , padding (Css.rem 0.2)
            , fontFamily monospace
            , fontSize (Css.rem 1)
            , lineHeight (Css.rem 1)
            ]
        , Css.class IconButton
            [ fontSize (Css.rem 1)
            , lineHeight (Css.rem 1)
            , width (Css.rem 1.5)
            , height (Css.rem 1.5)
            , borderRadius (pct 50)
            , color (hex base0)
            , backgroundColor transparent
            , cursor pointer
            , hover
                [ backgroundColor (hex base02)
                ]
            , Css.position Css.relative
            ]
        , Css.class Icon
            [ Css.fontSize (Css.rem 0.9)
            , Css.lineHeight (Css.rem 0.9)
            , Css.position Css.absolute
            , Css.top (Css.pct 50)
            , Css.left (Css.pct 50)
            , Css.transform (Css.translate2 (Css.pct -50) (Css.pct -50))
            ]
        , Css.class VariableName
            [ Css.fontSize (Css.rem 1)
            , Css.lineHeight (Css.rem 1)
            , Css.paddingRight (Css.rem 0.4)
            ]
        ]
