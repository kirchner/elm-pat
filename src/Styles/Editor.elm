module Styles.Editor
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
    = Main
    | MouseMove
    | Container
    | ContainerTopLeftLeft
    | ContainerTopLeft
    | ContainerBottomLeft
    | ContainerBottomRight
    | ContainerTopRight


{ id, class, classList } =
    withNamespace "editor__"


css =
    let
        class =
            Css.class
    in
    (stylesheet << namespace "editor__")
        [ body
            [ margin zero
            , overflow hidden
            ]
        , class Main
            [ position relative ]
        , class MouseMove
            [ cursor move ]
        , class Container
            [ padding (rem 0.3)
            , borderRadius (px 4)
            , color (hex base0)
            , backgroundColor (hex base2)
            , property "pointer-events" "auto"
            ]
        , class ContainerTopLeftLeft
            [ position absolute
            , top (rem 1)
            , left (rem 1)
            ]
        , class ContainerTopLeft
            [ position absolute
            , top (rem 1)
            , left (rem 5)
            ]
        , class ContainerTopRight
            [ position absolute
            , right (rem 1)
            , top (rem 1)
            ]
        , class ContainerBottomLeft
            [ position absolute
            , bottom (rem 1)
            , left (rem 1)
            ]
        , class ContainerBottomRight
            [ position absolute
            , bottom (rem 1)
            , right (rem 1)
            ]
        ]



{- helpers -}


rem =
    Css.rem
