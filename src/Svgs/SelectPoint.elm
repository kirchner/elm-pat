module Svgs.SelectPoint exposing (svg)

import Data.Point as Point exposing (Point)
import Data.Store as Store exposing (Id)
import Math.Vector2 exposing (..)
import Styles.Colors as Colors
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg
import Svgs.Extra as Extra
import Tools.Data exposing (Data)


svg :
    (Maybe (Id Point) -> msg)
    -> (Maybe (Id Point) -> msg)
    -> Data
    -> Svg msg
svg focusPoint selectPoint data =
    Store.toList data.store
        |> List.filterMap (pointSelector focusPoint selectPoint data)
        |> Svg.g []


pointSelector :
    (Maybe (Id Point) -> msg)
    -> (Maybe (Id Point) -> msg)
    -> Data
    -> ( Id Point, Point )
    -> Maybe (Svg msg)
pointSelector focusPoint selectPoint data ( id, point ) =
    let
        draw v =
            Svg.g []
                [ Svg.circle
                    [ Svg.cx (toString (getX v))
                    , Svg.cy (toString (getY v))
                    , Svg.r "5"
                    , Svg.fill "transparent"
                    , Svg.strokeWidth "0"
                    , Svg.onClick (selectPoint (Just id))
                    , Svg.onMouseOver (focusPoint (Just id))
                    , Svg.onMouseOut (focusPoint Nothing)
                    ]
                    []
                , if id |> equals data.focusedPoint then
                    Extra.drawSelector Extra.Solid Colors.red v
                  else
                    Svg.g [] []
                ]
    in
    Point.position data.store data.variables point
        |> Maybe.map draw



---- HELPER


equals : Maybe a -> a -> Bool
equals maybe a =
    case maybe of
        Just b ->
            if a == b then
                True
            else
                False

        _ ->
            False
