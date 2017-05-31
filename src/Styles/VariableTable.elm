module Styles.VariableTable
    exposing
        ( Class(..)
        , class
        , classList
        , css
        , id
        )

import Css exposing (..)
import Css.Elements exposing (..)
import Css.Namespace exposing (..)
import Html.CssHelpers exposing (withNamespace)
import Styles.Colors exposing (..)


type Class
    = Table
    | CellSign
    | CellName
    | CellFormula
    | CellValue
    | CellAction
    | IconButton
    | Icon
    | Input
    | InputBad


{ id, class, classList } =
    withNamespace "variable-table__"


css =
    let
        class =
            Css.class
    in
    (stylesheet << namespace "variable-table__")
        [ class Table
            [ property "pointer-events" "auto"
            , fontFamily monospace
            , fontSize (px 16)
            , lineHeight (rem 1)
            , borderCollapse collapse
            , children
                [ tr
                    [ children
                        [ th
                            [ paddingLeft (rem 0.3)
                            , paddingRight (rem 0.3)
                            , paddingTop (rem 0.5)
                            , paddingBottom (rem 0.5)
                            , borderTop3 (px 1) solid (hex base3)
                            ]
                        , td
                            [ paddingLeft (rem 0.3)
                            , paddingRight (rem 0.3)
                            , paddingTop (rem 0.5)
                            , paddingBottom (rem 0.5)
                            , verticalAlign top
                            ]
                        ]
                    ]
                ]
            ]
        , class CellSign
            [ width (rem 2)
            , textAlign center
            ]
        , class CellName
            [ width (rem 5)
            , textAlign right
            ]
        , class CellFormula
            [ width (rem 8)
            , textAlign left
            ]
        , class CellValue
            [ width (rem 3)
            , textAlign left
            ]
        , class CellAction
            [ width (rem 1)
            , textAlign center
            ]
        , class IconButton
            [ width (rem 1)
            , height (rem 1)
            , borderRadius (pct 50)
            , color (hex base0)
            , backgroundColor transparent
            , cursor pointer
            , hover
                [ backgroundColor (hex base3) ]
            , position relative
            ]
        , class Icon
            [ important (fontSize (rem 0.6))
            , important (lineHeight (rem 0.6))
            , position absolute
            , top (pct 50)
            , left (pct 50)
            , transform (translate2 (pct -50) (pct -50))
            ]
        , class Input
            [ backgroundColor (hex base03)
            , borderColor transparent
            , border zero
            , fontFamily monospace
            , fontSize (px 16)
            , lineHeight (rem 1)
            , width (rem 6)
            , backgroundColor transparent
            , color (hex base0)
            , focus
                [ outline none
                , borderColor (hex base02)
                ]
            ]
        , class InputBad
            [ color (hex red) ]
        ]



{- helpers -}


rem =
    Css.rem
