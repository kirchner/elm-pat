module Styles.FileBrowser
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
import Styles.Common as Common


type Class
    = FileBrowser
    | FileBrowserFileLinkWrapper
    | FileBrowserFileLink


{ id, class, classList } =
    withNamespace "file-browser__"


css =
    let
        class =
            Css.class
    in
    (stylesheet << namespace "file-browser__")
        [
          class FileBrowser
            [ position relative
            ]

        , class FileBrowserFileLink
            [ position relative
            , backgroundColor (hex base3)
            , color (hex base1)
            , cursor pointer
            , padding (rem 0.2)
            , margin (rem 0.05)
            , hover
              [ backgroundColor (hex base2)
              , color (hex base1)
              ]
            ]

        , class FileBrowserFileLinkWrapper
            [ displayFlex
            , flexFlow1 column
            , alignItems stretch
            , width (rem 16)
            ]
        ]



{- helpers -}


rem =
    Css.rem
