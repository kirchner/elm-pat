module Views.Textfields exposing (input)

import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import Views.Common as Common


input :
    String
    ->
        { onDelete : msg
        , onInput : String -> msg
        , onFocus : Maybe msg
        , onBlur : Maybe msg
        }
    -> Maybe String
    -> String
    -> Html msg
input id { onDelete, onInput, onFocus, onBlur } placeholder value =
    let
        deleteIcon =
            if value /= "" then
                Html.div
                    [ Attributes.class "tool__textfield-icon-container" ]
                    [ Common.iconSmall "delete" onDelete ]
            else
                Html.text ""
    in
    Html.div
        [ Attributes.class "tool__value-container" ]
        [ Html.input
            ([ Just (Attributes.id id)
             , Just (Attributes.class "tool__textfield")
             , Just (Events.onInput onInput)
             , onFocus |> Maybe.map Events.onFocus
             , onBlur |> Maybe.map Events.onBlur
             , placeholder |> Maybe.map Attributes.placeholder
             , Just (Attributes.defaultValue value)
             ]
                |> List.filterMap identity
            )
            []
        , deleteIcon
        ]
