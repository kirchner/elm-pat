module Styles.PointTable
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
    | CellId
    | CellCoordinate
    | CellType
    | CellAction
    | IconButton
    | Icon


{ id, class, classList } =
    withNamespace "point-table__"


css =
    let
        class =
            Css.class
    in
    (stylesheet << namespace "point-table__")
        [ class Table
            [ color (hex base0)
            , backgroundColor (hex base2)
            , property "pointer-events" "auto"
            , fontFamily monospace
            , fontSize (rem 1)
            , lineHeight (rem 1)
            , borderCollapse collapse
            , children
                [ tr
                    [ children
                        [ th
                            [ paddingLeft (rem 0.3)
                            , paddingRight (rem 0.3)
                            , paddingTop (rem 0.2)
                            , paddingBottom (rem 0.2)
                            , borderBottom3 (px 1) solid (hex base02)
                            ]
                        , td
                            [ paddingLeft (rem 0.3)
                            , paddingRight (rem 0.3)
                            , paddingTop (rem 0.1)
                            , paddingBottom (rem 0.1)
                            ]
                        ]
                    ]
                ]
            ]
        , class CellId
            [ width (rem 1)
            , borderRight3 (px 1) solid (hex base02)
            , textAlign right
            ]
        , class CellCoordinate
            [ width (rem 3)
            , textAlign right
            ]
        , class CellType
            [ width (rem 6)
            , textAlign center
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
        ]



{- helpers -}


rem =
    Css.rem
