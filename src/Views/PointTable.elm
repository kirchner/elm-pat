module Views.PointTable exposing (view)

import Dict exposing (..)
import Editor exposing (Msg(..))
import Expr exposing (..)
import Html exposing (..)
import Html.Attributes as Html
import Html.Events as Html
import Math.Vector2 exposing (..)
import Tools.Styles
import Point exposing (Point)
import Store exposing (Id, Store)
import Styles.PointTable
    exposing
        ( Class(..)
        , class
        )
import Tools.Common exposing (Data)
import Views.Common exposing (iconSmall)
import Json.Encode as Json


type alias Callbacks =
    { setName : Id Point -> String -> Msg
    , selectPoint : Id Point -> Msg
    , deselectPoint : Id Point -> Msg
    }


view : Callbacks -> Data -> Html Msg
view callbacks data =
    table
        [ class [ Table ] ]
        (tr
            []
            [ th
                [ class [ CellId ] ]
                [ text "#" ]
            , th
                [ class [ CellId ] ] -- <- TODO
                [ text "o" ]
            , th
                [ class [ CellName ] ]
                [ text "name" ]
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
                    |> List.map (viewPointEntry callbacks data)
               )
        )


viewPointEntry : Callbacks -> Data -> ( Id Point, Point ) -> Html Msg
viewPointEntry callbacks data ( id, point ) =
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
            [ text (id |> Store.toInt |> toString) ]
        , td
            [ class [ CellId ] ] -- <- TODO
            [ a 
              [ Html.onClick ((if isSelected then callbacks.deselectPoint else callbacks.selectPoint) id)
              ]
              [ i
                [ Html.class "material-icons"
                ]
                [ text <|
                  if isSelected then "radio_button_checked" else "radio_button_unchecked"
                ]
              ]
            ]
        , td
            [ class [ CellName ] ]
            [ let
                  deleteIcon =
                    Html.div
                      [ Tools.Styles.class [ Tools.Styles.IconContainer ] ]
                      [ iconSmall "delete" (callbacks.setName id "") ]
              in
              Html.div
                  [ Tools.Styles.class [ Tools.Styles.ValueContainer ] ]
                  ([ Html.input
                      [ Html.onInput (callbacks.setName id)
                      , Html.placeholder (Point.name point)
                      , Html.value (Point.name point) -- TODO: broken
                      , Tools.Styles.class [ Tools.Styles.Textfield ]
                      ]
                      []
                   , deleteIcon
                   ]
                  )
            ]
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
    let
        handlers =
            { withAbsolute = \_ _ _ -> "absolute"
            , withRelative = \_ _ _ _ -> "relative"
            , withDistance = \_ _ _ _ -> "distance"
            , withBetween = \_ _ _ _ -> "between"
            , withCircleIntersection = \_ _ _ _ _ _ -> "circleIntersection"
            }
    in
    Point.dispatch handlers point
