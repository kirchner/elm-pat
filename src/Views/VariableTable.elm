module Views.VariableTable exposing (view)

import Data.Expr as Expr exposing (E)
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import Views.Common as Common


view :
    { setName : String -> String -> msg
    , setValue : String -> String -> msg
    , setNewName : String -> msg
    , setNewValue : String -> msg
    , add : msg
    }
    -> Dict String E
    -> Maybe String
    -> Maybe E
    -> Html msg
view { setName, setValue, setNewName, setNewValue, add } variables newName newValue =
    Html.table
        [ Attributes.class "variable-table__table" ]
        ((variables
            |> Dict.toList
            |> List.map
                (viewVariable
                    { setName = setName
                    , setValue = setValue
                    }
                    variables
                )
         )
            ++ [ Html.tr
                    []
                    [ Html.th
                        [ Attributes.class "variable-table__cell"
                        , Attributes.class "variable-table__cell--name"
                        ]
                        [ Html.input
                            [ Attributes.class "variable-table__input"
                            , Attributes.classList
                                [ ( "variable-table__input--bad", newName == Nothing ) ]
                            , Events.onInput setNewName
                            , Attributes.placeholder "name"
                            ]
                            []
                        ]
                    , Html.th
                        [ Attributes.class "variable-table__cell"
                        , Attributes.class "variable-table__cell--sign"
                        ]
                        [ Html.text "=" ]
                    , Html.th
                        [ Attributes.class "variable-table__cell"
                        , Attributes.class "variable-table__cell--formular"
                        ]
                        [ Html.input
                            [ Attributes.class "variable-table__input"
                            , Attributes.classList
                                [ ( "variable-table__input--bad", newName == Nothing ) ]
                            , Events.onInput setNewValue
                            , Attributes.placeholder "value"
                            ]
                            []
                        ]
                    , Html.th
                        [ Attributes.class "variable-table__cell"
                        , Attributes.class "variable-table__cell--sign"
                        ]
                        []
                    , Html.th
                        [ Attributes.class "variable-table__cell"
                        , Attributes.class "variable-table__cell--value"
                        ]
                        []
                    , Html.th
                        [ Attributes.class "variable-table__cell"
                        , Attributes.class "variable-table__cell--action"
                        ]
                        [ Common.iconSmall "add" add ]
                    ]
               ]
        )


viewVariable :
    { setName : String -> String -> msg
    , setValue : String -> String -> msg
    }
    -> Dict String E
    -> ( String, E )
    -> Html msg
viewVariable { setName, setValue } variables ( name, expr ) =
    Html.tr
        []
        [ Html.td
            [ Attributes.class "variable-table__cell"
            , Attributes.class "variable-table__cell--name"
            ]
            [ let
                deleteIcon =
                    Html.div
                        [ Attributes.class "tool__icon-container" ]
                        [ Common.iconSmall "delete" (setName name "") ]
              in
              Html.div
                [ Attributes.class "tool__icon-container" ]
                [ Html.input
                    [ Attributes.class "tool__textfield"
                    , Events.onInput (setName name)
                    , Attributes.placeholder name
                    , Attributes.value name -- TODO: broken
                    ]
                    []
                , deleteIcon
                ]
            ]
        , cellSign "="
        , Html.td
            [ Attributes.class "variable-table__cell"
            , Attributes.class "variable-table__cell--formula"
            ]
            [ let
                deleteIcon =
                    Html.div
                        [ Attributes.class "tool__icon-container" ]
                        [ Common.iconSmall "delete" (setValue name "") ]
              in
              Html.div
                [ Attributes.class "tool__value-container" ]
                [ Html.input
                    [ Attributes.class "tool__textfield"
                    , Events.onInput (setValue name)
                    , Attributes.placeholder (Expr.print expr)
                    , Attributes.value (Expr.print expr) -- TODO: broken
                    ]
                    []
                , deleteIcon
                ]
            ]
        , cellSign "="
        , Html.td
            [ Attributes.class "variable-table__cell"
            , Attributes.class "variable-table__cell--value"
            ]
            [ expr
                |> Expr.compute variables
                |> Maybe.map toString
                |> Maybe.withDefault ""
                |> Html.text
            ]
        , Html.td
            [ Attributes.class "variable-table__cell"
            , Attributes.class "variable-table__cell--action"
            ]
            []
        ]


cellSign : String -> Html msg
cellSign sign =
    Html.td
        [ Attributes.class "variable-table__cell"
        , Attributes.class "variable-table__cell--sign"
        ]
        [ Html.text sign ]
