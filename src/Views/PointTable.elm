module Views.PointTable exposing (view)

import Dict exposing (..)
import Editor exposing (Msg(..))
import Expr exposing (..)
import Html exposing (..)
import Html.Attributes as Html
import Html.Events exposing (..)
import Math.Vector2 exposing (..)
import Styles.PointTable
    exposing
        ( Class(..)
        , class
        )
import Types
    exposing
        ( Id
        , Point
        , PointStore
        )
import Views.Common exposing (iconSmall)


view : Dict String E -> PointStore -> Html Msg
view variables store =
    table
        [ class [ Table ] ]
        (tr []
            [ th
                [ class [ CellId ] ]
                [ text "#" ]
            , th
                [ class [ CellCoordinate ] ]
                [ text "x" ]
            , th
                [ class [ CellCoordinate ] ]
                [ text "y" ]
            , th
                [ class [ CellType ] ]
                []
            , th
                [ class [ CellAction ] ]
                []
            , th
                [ class [ CellAction ] ]
                []
            ]
            :: (store
                    |> Dict.toList
                    |> List.map (viewPointEntry variables store)
               )
        )


viewPointEntry : Dict String E -> PointStore -> ( Id, Point ) -> Html Msg
viewPointEntry variables store ( id, point ) =
    let
        v =
            Types.position store variables point

        x =
            v
                |> Maybe.map getX
                |> Maybe.map toString
                |> Maybe.withDefault ""

        y =
            v
                |> Maybe.map getY
                |> Maybe.map toString
                |> Maybe.withDefault ""
    in
    tr []
        [ td
            [ class [ CellId ] ]
            [ text (toString id) ]
        , td
            [ class [ CellCoordinate ] ]
            [ text x ]
        , td
            [ class [ CellCoordinate ] ]
            [ text y ]
        , td
            [ class [ CellType ] ]
            [ text (printPoint variables point) ]
        , td
            [ class [ CellAction ] ]
            [ iconSmall "edit" (SelectPoint id) ]
        , td
            [ class [ CellAction ] ]
            [ iconSmall "delete" (DeletePoint id) ]
        ]


printPoint : Dict String E -> Point -> String
printPoint variables point =
    case point of
        Types.Absolute _ _ ->
            "absolute"

        Types.Relative _ _ _ ->
            "relative"

        _ ->
            toString point
