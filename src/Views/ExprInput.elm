module Views.ExprInput
    exposing
        ( view
        , viewWithClear
        )

import Data.Expr as Expr exposing (E)
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import Views.Common as Views


view : String -> Maybe E -> (String -> msg) -> Html msg
view name e callback =
    let
        deleteIcon =
            if e /= Nothing then
                [ Html.div
                    [ Attributes.class "tool__icon-container" ]
                    [ Views.iconSmall "delete" (callback "") ]
                ]
            else
                []
    in
    Html.div
        [ Attributes.class "tool__value-container" ]
        ([ Html.input
            [ Events.onInput callback
            , Attributes.placeholder
                (e
                    |> Maybe.map Expr.print
                    |> Maybe.withDefault name
                )
            , Attributes.class "tool__textfield"
            ]
            []
         ]
            ++ deleteIcon
        )


viewWithClear : Bool -> String -> Maybe E -> (String -> msg) -> Html msg
viewWithClear autoFocus name e callback =
    let
        deleteIcon =
            if e /= Nothing then
                [ Html.div
                    [ Attributes.class "tool__icon-container" ]
                    [ Views.iconSmall "delete" (callback "") ]
                ]
            else
                []
    in
    Html.div
        [ Attributes.class "tool__value-container" ]
        ([ Html.input
            [ Events.onInput callback
            , Attributes.placeholder
                (e
                    |> Maybe.map Expr.print
                    |> Maybe.withDefault name
                )
            , Attributes.autofocus autoFocus
            , Attributes.class "tool__textfield"
            ]
            []
         ]
            ++ deleteIcon
        )
