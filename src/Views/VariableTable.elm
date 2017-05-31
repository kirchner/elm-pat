module Views.VariableTable exposing (view)

import Dict exposing (..)
import Editor exposing (Msg(..))
import Expr exposing (..)
import Html exposing (..)
import Html.Attributes as Html
import Html.Events exposing (..)
import Math.Vector2 exposing (..)
import Styles.VariableTable
    exposing
        ( Class(..)
        , class
        , classList
        )
import Types
    exposing
        ( Id
        , Point
        , PointStore
        )
import Views.Common exposing (iconSmall)


view : Dict String E -> Maybe String -> Maybe E -> Html Msg
view variables newName newValue =
    table
        [ class [ Table ] ]
        ((variables
            |> Dict.toList
            |> List.map (viewVariable variables)
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


viewVariable : Dict String E -> ( String, E ) -> Html Msg
viewVariable variables ( name, expr ) =
    tr
        []
        [ td
            [ class [ CellName ] ]
            [ text name ]
        , cellSign "="
        , td
            [ class [ CellFormula ] ]
            [ expr
                |> Expr.print
                |> text
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
