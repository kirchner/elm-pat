module Tools.Styles exposing (..)

import Css exposing (..)
import Css.Namespace exposing (namespace)
import Html.CssHelpers exposing (withNamespace)
import Styles.Colors exposing (..)


{- css -}


type Class
    = ToolBox
    | ValueContainer
    | Textfield
    | IconContainer
    | Button
    | MenuContainer
    | MenuTextfield
    | MenuList
    | MenuItem
    | MenuItemSelected
    | SwitchContainer
    | SwitchChoice
    | SwitchChoiceSelected


{ id, class, classList } =
    withNamespace "tool__"


css =
    (stylesheet << namespace "tool__")
        [ Css.class ToolBox
            [ backgroundColor (hex base2)
            , property "pointer-events" "auto"
            , displayFlex
            ]
        , Css.class ValueContainer
            [ position relative
            , displayFlex
            , paddingLeft (rem 0.3)
            , paddingRight (rem 0.3)
            , margin (px 2)
            , border zero
            , hover
                [ margin zero
                , border3 (px 2) solid (hex base0)
                ]
            ]
        , Css.class Textfield
            [ borderColor transparent
            , fontFamily monospace
            , fontSize (px 12)
            , lineHeight (rem 1)
            , width (rem 20)
            , backgroundColor transparent
            , focus
                [ outline none ]
            ]
        , Css.class IconContainer
            [ position absolute
            , right (rem 0.3)
            , height (pct 100)
            , displayFlex
            , flexFlow1 column
            , justifyContent spaceAround
            ]
        , Css.class Button
            [ textAlign center
            , width (rem 10)
            , height (rem 2)
            , lineHeight (rem 2)
            , color (hex base0)
            , backgroundColor (hex base03)
            , cursor pointer
            , hover
                [ backgroundColor (hex base02) ]
            ]
        , Css.class MenuContainer
            [ position absolute
            , left (px -2)
            , top (pct 100)
            , maxHeight (rem 6)
            , width (pct 100)
            , margin zero
            , border3 (px 2) solid (hex base0)
            ]
        , Css.class MenuTextfield
            [ width (rem 10) ]
        , Css.class MenuList
            [ width (pct 100)
            , backgroundColor (hex base2)
            , listStyle none
            , padding zero
            , margin zero
            , fontFamily monospace
            , fontSize (rem 1)
            , lineHeight (rem 1)
            ]
        , Css.class MenuItem
            [ padding (rem 0.2) ]
        , Css.class MenuItemSelected
            [ backgroundColor (hex base3)
            ]
        , Css.class SwitchContainer
            [ displayFlex
            , alignItems stretch
            , position relative
            , paddingLeft (rem 0.3)
            , paddingRight (rem 0.3)
            ]
        , Css.class SwitchChoice
            [ fontFamily monospace
            , fontSize (rem 1)
            , lineHeight (rem 1)
            , displayFlex
            , alignItems center
            , justifyContent spaceAround
            , width (rem 2)
            , margin (px 2)
            , border zero
            , hover
                [ margin zero
                , border3 (px 2) solid (hex base0)
                ]
            ]
        , Css.class SwitchChoiceSelected
            [ backgroundColor (hex base0)
            , color (hex base2)
            , margin zero
            , border3 (px 2) solid (hex base0)
            ]
        ]


rem =
    Css.rem
