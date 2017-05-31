module Styles.Common
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
    = IconButtonBig
    | IconBig
    | IconButtonSmall
    | IconSmall


{ id, class, classList } =
    withNamespace "common__"


css =
    let
        class =
            Css.class
    in
    (stylesheet << namespace "common__")
        [ class IconButtonBig
            [ width (rem 3)
            , height (rem 3)
            , borderRadius (px 4)
            , color (hex base0)
            , backgroundColor transparent
            , cursor pointer
            , hover
                [ backgroundColor (hex base3) ]
            , displayFlex
            , justifyContent center
            , alignItems center
            ]
        , class IconBig
            [ important (fontSize (rem 2.5))
            , important (lineHeight (rem 2.5))
            ]
        , class IconButtonSmall
            [ width (rem 1)
            , height (rem 1)
            , borderRadius (px 4)
            , color (hex base0)
            , backgroundColor transparent
            , cursor pointer
            , hover
                [ backgroundColor (hex base3) ]
            , displayFlex
            , justifyContent center
            , alignItems center
            ]
        , class IconSmall
            [ important (fontSize (rem 1))
            , important (lineHeight (rem 1))
            ]
        ]



{- helpers -}


rem =
    Css.rem
