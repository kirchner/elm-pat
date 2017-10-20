module Views.PointTable exposing (view)

import Data.Expr exposing (E)
import Data.Point as Point exposing (Point)
import Data.Store as Store exposing (Id, Store)
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import Math.Vector2 exposing (..)
import Tools.Data exposing (Data)
import Views.Common as Common


type alias Callbacks msg =
    { setName : Id Point -> String -> msg
    , selectPoint : Id Point -> msg
    , deselectPoint : Id Point -> msg
    , deletePoint : Id Point -> msg
    }


view : Callbacks msg -> Data -> Html msg
view callbacks data =
    Html.table
        [ Attributes.class "point-table__table" ]
        (Html.tr
            []
            [ Html.th
                [ Attributes.class "point-table__cell"
                , Attributes.class "point-table__cell--id"
                ]
                []
            , Html.th
                [ Attributes.class "point-table__cell"
                , Attributes.class "point-table__cell--id"
                ]
                [ Html.text "#" ]
            , Html.th
                [ Attributes.class "point-table__cell"
                , Attributes.class "point-table__cell--name"
                ]
                [ Html.text "name" ]
            , Html.th
                [ Attributes.class "point-table__cell"
                , Attributes.class "point-table__cell--coordinate"
                ]
                [ Html.text "x" ]
            , Html.th
                [ Attributes.class "point-table__cell"
                , Attributes.class "point-table__cell--coordinate"
                ]
                [ Html.text "y" ]
            , Html.th
                [ Attributes.class "point-table__cell"
                , Attributes.class "point-table__cell--type"
                ]
                []

            --, th
            --    [ class [ CellAction ] ]
            --    []
            , Html.th
                [ Attributes.class "point-table__cell"
                , Attributes.class "point-table__cell--action"
                ]
                []
            ]
            :: (data.store
                    |> Store.toList
                    |> List.map (viewPointEntry callbacks data)
               )
        )


viewPointEntry : Callbacks msg -> Data -> ( Id Point, Point ) -> Html msg
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
    Html.tr
        [ Attributes.class "point-table__row"
        , Attributes.classList
            [ ( "point-table__selected", isSelected )
            , ( "point-table__selected-last", isSelectedLast )
            ]
        ]
        [ Html.td
            [ Attributes.class "point-table__cell"
            , Attributes.class "point-table__cell--id"
            ]
            [ Html.button
                [ Events.onClick
                    ((if isSelected then
                        callbacks.deselectPoint
                      else
                        callbacks.selectPoint
                     )
                        id
                    )
                , Attributes.class "icon-button"
                , Attributes.class "icon-button--small"
                ]
                [ Html.i
                    [ Attributes.class "icon"
                    , Attributes.class "icon--small"
                    , Attributes.class "material-icons"
                    , Attributes.style
                        [ ( "cursor", "pointer" ) ]
                    ]
                    [ Html.text <|
                        if isSelected then
                            "radio_button_checked"
                        else
                            "radio_button_unchecked"
                    ]
                ]
            ]
        , Html.td
            [ Attributes.class "point-table__cell"
            , Attributes.class "point-table__cell--id"
            ]
            [ Html.text (id |> Store.toInt |> toString) ]
        , Html.td
            [ Attributes.class "point-table__cell"
            , Attributes.class "point-table__cell--name"
            ]
            [ let
                deleteIcon =
                    Html.div
                        [ Attributes.class "tool__textfield-icon-container" ]
                        [ Common.iconSmall "delete" (callbacks.setName id "") ]
              in
              Html.div
                [ Attributes.class "tool__value-container" ]
                [ Html.input
                    [ Attributes.class "tool__textfield"
                    , Events.onInput (callbacks.setName id)
                    , Attributes.placeholder (Point.name point)
                    , Attributes.value (Point.name point) -- TODO: broken
                    ]
                    []
                , deleteIcon
                ]
            ]
        , Html.td
            [ Attributes.class "point-table__cell"
            , Attributes.class "point-table__cell--coordinate"
            ]
            [ Html.text x ]
        , Html.td
            [ Attributes.class "point-table__cell"
            , Attributes.class "point-table__cell--coordinate"
            ]
            [ Html.text y ]
        , Html.td
            [ Attributes.class "point-table__cell"
            , Attributes.class "point-table__cell--type"
            ]
            [ Html.text (printPoint data.variables point) ]

        --, td
        --    [ class [ CellAction ] ]
        --    [ Common.iconSmall "edit" (SelectPoint id) ]
        , Html.td
            [ Attributes.class "point-table__cell"
            , Attributes.class "point-table__cell--action"
            ]
            [ Common.iconSmall "delete" (callbacks.deletePoint id) ]
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
