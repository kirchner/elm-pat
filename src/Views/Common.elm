module Views.Common
    exposing
        ( iconBig
        , iconSmall
        )

import Html exposing (..)
import Html.Attributes as Html
import Html.Events exposing (..)
import Styles.Common
    exposing
        ( Class(..)
        , class
        )


iconBig : String -> msg -> Html msg
iconBig name callback =
    div
        [ class [ IconButtonBig ] ]
        [ i
            [ Html.class "material-icons"
            , onClick callback
            , class [ IconBig ]
            ]
            [ text name ]
        ]


iconSmall : String -> msg -> Html msg
iconSmall name callback =
    div
        [ class [ IconButtonSmall ] ]
        [ i
            [ Html.class "material-icons"
            , onClick callback
            , class [ IconSmall ]
            ]
            [ text name ]
        ]
