module Views.VariableTable exposing (view)

import Data.Expr as Expr exposing (E)
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import Views.Common as Common
import Views.Textfields as Textfields


view :
    { setName : String -> String -> msg
    , setValue : String -> String -> msg
    , setNewName : String -> msg
    , setNewValue : String -> msg
    , add : msg
    , onFocus : msg
    , onBlur : msg
    }
    -> Dict String E
    -> Maybe String
    -> Maybe E
    -> Html msg
view { setName, setValue, setNewName, setNewValue, add, onFocus, onBlur } variables newName newValue =
    Html.table
        [ Attributes.class "variable-table__table" ]
        ((variables
            |> Dict.toList
            |> List.map
                (viewVariable
                    { setName = setName
                    , setValue = setValue
                    , onFocus = onFocus
                    , onBlur = onBlur
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
                        [ Html.div
                            [ Attributes.class "tool__value-container"
                            , Attributes.classList
                                [ ( "tool__value-container--bad", newName == Nothing ) ]
                            ]
                            [ Html.input
                                [ Attributes.class "tool__textfield"
                                , Attributes.classList
                                    [ ( "tool__textfield--bad", newName == Nothing ) ]
                                , Events.onInput setNewName
                                , Attributes.placeholder "name"
                                ]
                                []
                            ]
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
                        [ Html.div
                            [ Attributes.class "tool__value-container"
                            , Attributes.classList
                                [ ( "tool__value-container--bad", newName == Nothing ) ]
                            ]
                            [ Html.input
                                [ Attributes.class "tool__textfield"
                                , Attributes.classList
                                    [ ( "tool__textfield--bad", newValue == Nothing ) ]
                                , Events.onInput setNewValue
                                , Attributes.placeholder "value"
                                ]
                                []
                            ]
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
    , onFocus : msg
    , onBlur : msg
    }
    -> Dict String E
    -> ( String, E )
    -> Html msg
viewVariable { setName, setValue, onFocus, onBlur } variables ( name, expr ) =
    Html.tr
        []
        [ Html.td
            [ Attributes.class "variable-table__cell"
            , Attributes.class "variable-table__cell--name"
            ]
            [ Textfields.input ("variable-table__name--" ++ name)
                { onDelete = setName name ""
                , onInput = setName name
                , onFocus = Just onFocus
                , onBlur = Just onBlur
                }
                (Just "name")
                name
            ]
        , cellSign "="
        , Html.td
            [ Attributes.class "variable-table__cell"
            , Attributes.class "variable-table__cell--formula"
            ]
            [ Textfields.input ("variable-table__value--" ++ name)
                { onDelete = setValue name ""
                , onInput = setValue name
                , onFocus = Just onFocus
                , onBlur = Just onBlur
                }
                (Just "value")
                (Expr.print expr)
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
