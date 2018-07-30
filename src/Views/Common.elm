module Views.Common
    exposing
        ( iconBig
        , iconSmall
        )

import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events


iconBig : String -> msg -> Html msg
iconBig name callback =
    Html.button
        [ Attributes.class "icon-button"
        , Attributes.class "icon-button--big"
        , Attributes.tabindex -1
        , Events.onClick callback
        ]
        [ Html.i
            [ Attributes.class "icon"
            , Attributes.class "icon--big"
            , Attributes.class "material-icons"
            ]
            [ Html.text name ]
        ]


iconSmall : String -> msg -> Html msg
iconSmall name callback =
    Html.button
        [ Attributes.class "icon-button"
        , Attributes.class "icon-button--small"
        , Attributes.tabindex -1
        ]
        [ Html.i
            [ Attributes.class "icon"
            , Attributes.class "icon--small"
            , Attributes.class "material-icons"
            , Events.onClick callback
            ]
            [ Html.text name ]
        ]
