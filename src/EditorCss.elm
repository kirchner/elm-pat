module EditorCss exposing (..)

import Css exposing (..)
import Css.Colors exposing (..)
import Css.Elements exposing (button)
import Css.Namespace exposing (namespace)
import SharedStyles
    exposing
        ( CssClasses(..)
        , CssIds(..)
        , editorNamespace
        )


css =
    (stylesheet << namespace editorNamespace.name)
        [ button
            [ padding (px 5)
            , fontFamily inherit
            , padding2 (em 0.5) (em 1)
            , color (rgba 0 0 0 0.8)
            , border3 (px 1) solid (rgba 0 0 0 0)
            , backgroundColor blue
            , textDecoration none
            , borderRadius (px 2)
            ]
        , id ToolBox
            [ padding (px 30)
            , width (pct 100)
            ]
        ]
