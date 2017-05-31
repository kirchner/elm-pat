module Styles.ToolBox
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
    = Container


{ id, class, classList } =
    withNamespace "tool-box__"


css =
    let
        class =
            Css.class
    in
    (stylesheet << namespace "tool-box__")
        [ class Container
            [ displayFlex
            , flexFlow1 column
            , property "pointer-events" "auto"
            ]
        ]



{- helpers -}


rem =
    Css.rem
