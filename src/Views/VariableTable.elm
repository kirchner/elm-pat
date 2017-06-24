module Views.VariableTable exposing (view)

import Dict exposing (..)
import Editor exposing (Msg(..))
import Expr exposing (..)
import Html exposing (..)
import Html.Attributes as Html
import Html.Events exposing (..)
import Styles.VariableTable
    exposing
        ( Class(..)
        , class
        , classList
        )
import Views.Common exposing (iconSmall)
import Tools.Styles


type alias Callbacks =
    { setVariableName : String -> String -> Msg
    , setVariableValue : String -> String -> Msg
    }


view : Callbacks -> Dict String E -> Maybe String -> Maybe E -> Html Msg
view callbacks variables newName newValue =
    table
        [ class [ Table ] ]
        ((variables
            |> Dict.toList
            |> List.map (viewVariable callbacks variables)
         )
            ++ [ tr
                    []
                    [ th
                        [ class [ CellName ] ]
                        [ input
                            [ onInput NameUpdated
                            , Html.placeholder "name"
                            , class [ Input ]
                            , classList
                                [ ( InputBad, newName == Nothing ) ]
                            ]
                            []
                        ]
                    , th
                        [ class [ CellSign ] ]
                        [ text "=" ]
                    , th
                        [ class [ CellFormula ] ]
                        [ input
                            [ onInput ValueUpdated
                            , Html.placeholder "value"
                            , class [ Input ]
                            , classList
                                [ ( InputBad, newValue == Nothing ) ]
                            ]
                            []
                        ]
                    , th
                        [ class [ CellSign ] ]
                        []
                    , th
                        [ class [ CellValue ] ]
                        []
                    , th
                        [ class [ CellAction ] ]
                        [ iconSmall "add" AddVariable ]
                    ]
               ]
        )


viewVariable : Callbacks -> Dict String E -> ( String, E ) -> Html Msg
viewVariable callbacks variables ( name, expr ) =
    tr
        []
        [ td
            [ class [ CellName ] ]
            [ let
                  deleteIcon =
                    div
                      [ Tools.Styles.class [ Tools.Styles.IconContainer ] ]
                      [ iconSmall "delete" (callbacks.setVariableName name "") ]
              in
              Html.div
                  [ Tools.Styles.class [ Tools.Styles.ValueContainer ] ]
                  ([ Html.input
                      [ onInput (callbacks.setVariableName name)
                      , Html.placeholder name
                      , Html.value name -- TODO: broken
                      , Tools.Styles.class [ Tools.Styles.Textfield ]
                      ]
                      []
                   , deleteIcon
                   ]
                  )
            ]


        , cellSign "="
        , td
            [ class [ CellFormula ] ]
            [ let
                  deleteIcon =
                    div
                      [ Tools.Styles.class [ Tools.Styles.IconContainer ] ]
                      [ iconSmall "delete" (callbacks.setVariableValue name "") ]
              in
              Html.div
                  [ Tools.Styles.class [ Tools.Styles.ValueContainer ] ]
                  ([ Html.input
                      [ onInput (callbacks.setVariableValue name)
                      , Html.placeholder (Expr.print expr)
                      , Html.value (Expr.print expr) -- TODO: broken
                      , Tools.Styles.class [ Tools.Styles.Textfield ]
                      ]
                      []
                   , deleteIcon
                   ]
                  )
            ]
        , cellSign "="
        , td
            [ class [ CellValue ] ]
            [ expr
                |> Expr.compute variables
                |> Maybe.map toString
                |> Maybe.withDefault ""
                |> text
            ]
        , td
            [ class [ CellAction ] ]
            []
        ]


cellSign : String -> Html msg
cellSign sign =
    td
        [ class [ CellSign ] ]
        [ text sign ]
