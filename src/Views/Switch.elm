module Views.Switch exposing (view)

import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events


view : List String -> Int -> (Int -> msg) -> Html msg
view choices state updateState =
    let
        viewState index title =
            Html.div
                [ Attributes.class "tool__switch-choice"
                , Attributes.classList
                    [ ( "tool__switch-choice--selected", index == state ) ]
                , Events.onClick (updateState index)
                ]
                [ Html.text title ]
    in
    choices
        |> List.indexedMap viewState
        |> Html.div
            [ Attributes.class "tool__switch-container" ]
