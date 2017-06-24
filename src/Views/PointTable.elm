module Views.PointTable exposing (view)

import Dict exposing (..)
import Editor exposing (Msg(..))
import Expr exposing (..)
import Html exposing (..)
import Html.Attributes as Html
import Html.Events exposing (..)
import Math.Vector2 exposing (..)
import Point exposing (Point)
import Store exposing (Id, Store)
import Styles.PointTable
    exposing
        ( Class(..)
        , class
        )
import Tools.Common exposing (Data)
import Views.Common exposing (iconSmall)


view : Data -> Html Msg
view data =
    table
        [ class [ Table ] ]
        (tr
            []
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

            --, th
            --    [ class [ CellAction ] ]
            --    []
            , th
                [ class [ CellAction ] ]
                []
            ]
            :: (data.store
                    |> Store.toList
                    |> List.map (viewPointEntry data)
               )
        )


viewPointEntry : Data -> ( Id Point, Point ) -> Html Msg
viewPointEntry data ( id, point ) =
    let
        v =
            Point.position data.store data.variables point

        x =
            v
                |> Maybe.map getX
                |> Maybe.map (\x -> toFloat (floor (100 * x)) / 100)
                |> Maybe.map toString
                |> Maybe.withDefault ""

        y =
            v
                |> Maybe.map getY
                |> Maybe.map (\y -> toFloat (floor (100 * y)) / 100)
                |> Maybe.map toString
                |> Maybe.withDefault ""

        isSelected =
            List.member id data.selectedPoints

        isSelectedLast =
            Just id == List.head data.selectedPoints
    in
    tr
        [ class
            ([ Just Row
             , if isSelected then
                Just RowSelected
               else
                Nothing
             , if isSelectedLast then
                Just RowSelectedLast
               else
                Nothing
             ]
                |> List.filterMap identity
            )
        ]
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
            [ text (printPoint data.variables point) ]

        --, td
        --    [ class [ CellAction ] ]
        --    [ iconSmall "edit" (SelectPoint id) ]
        , td
            [ class [ CellAction ] ]
            [ iconSmall "delete" (DeletePoint id) ]
        ]


printPoint : Dict String E -> Point -> String
printPoint variables point =
    case point of
        Point.Absolute _ _ ->
            "absolute"

        Point.Relative _ _ _ ->
            "relative"

        Point.Distance _ _ _ ->
            "distance"

        _ ->
            toString point
