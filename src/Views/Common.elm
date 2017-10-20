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
        ]
        [ Html.i
            [ Attributes.class "icon"
            , Attributes.class "icon--big"
            , Attributes.class "material-icons"
            , Events.onClick callback
            ]
            [ Html.text name ]
        ]


iconSmall : String -> msg -> Html msg
iconSmall name callback =
    Html.button
        [ Attributes.class "icon-button"
        , Attributes.class "icon-button--small"
        ]
        [ Html.i
            [ Attributes.class "icon"
            , Attributes.class "icon--small"
            , Attributes.class "material-icons"
            , Events.onClick callback
            ]
            [ Html.text name ]
        ]
