module EditorCss exposing (..)

import Css exposing (..)
import Css.Elements exposing (body, button, div)
import Css.Namespace exposing (namespace)
import SharedStyles
    exposing
        ( ToolbarClass(..)
        , toolbarNamespace
        )
import View.Colors exposing (..)


css =
    (stylesheet << namespace toolbarNamespace.name)
        [ body
            [ fontFamily sansSerif
            , padding zero
            , margin zero
            ]
        , class ToolbarMain
            [ displayFlex
            , flexFlow1 row
            , property "pointer-events" "auto"
            ]
        , class ToolbarButtonWrapper
            [ position relative
            , hover
                [ Css.descendants
                    [ class ToolbarTooltip
                        [ opacity (num 1)
                        , property "visibility" "visible"
                        , transforms
                            [ translateX (pct -50)
                            , scale3d 1 1 1
                            ]
                        ]
                    ]
                ]
            ]
        , class ToolbarButton
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
        , class ToolbarTooltip
            [ display inlineBlock
            , property "visibility" "invisible"
            , opacity (num 0)
            , transforms
                [ translateX (pct -50)
                , scale3d 0 0 1
                ]
            , property "transition"
                ("opacity 150ms ease-in-out"
                    ++ ", transform 150ms ease-in-out"
                )
            , position absolute
            , top (pct 100)
            , left (pct 50)
            , marginTop (Css.rem 0.5)
            , padding (Css.rem 0.2)
            , color (hex base0)
            , backgroundColor (hex base2)
            , fontSize smaller
            , borderRadius (px 2)
            ]
        , class ToolTextfield
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
        , class ToolbarRow
            [ displayFlex
            , flexFlow1 row
            --, justifyContent flexStart
            , width (Css.rem 10)
            , alignItems stretch
            ]
        , class ToolbarColumn
            [ padding (Css.rem 0.2)
            , fontFamily monospace
            , fontSize (Css.rem 1)
            , lineHeight (Css.rem 1)
            ]
        , class ToolbarIconButton
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
            , position relative
            ]
        ]
