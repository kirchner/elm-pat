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
    | Row
    | RowSelected
    | RowSelectedLast
    | CellId
    | CellName
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
                [ property "pointer-events" "auto"
                , fontFamily monospace
                , fontSize (px 12)
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
                                , borderBottom3 (px 1) solid (hex base3)
                                , fontWeight bold
                                ]
                            , td
                                [ paddingLeft (rem 0.3)
                                , paddingRight (rem 0.3)
                                , paddingTop (rem 0.5)
                                , paddingBottom (rem 0.5)
                                ]
                            ]
                        ]
                    ]
                ]
            , class RowSelected
                [ color (hex yellow)
                ]
            , class RowSelectedLast
                [ color (hex orange)
                ]
            , class CellId
                [ width (rem 1)
                , borderRight3 (px 1) solid (hex base3)
                , textAlign right
                ]
            , class CellName
                [ width (rem 5)
                , textAlign left
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
