module Tools.Select exposing (..)

import Dict exposing (Dict)
import Keyboard.Extra as Keyboard
import Set exposing (Set)
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg
import Svg.Extra as Svg
import Tools.Common as Tools
    exposing
        ( Callbacks
        , Data
        , svgSelectPoint
        , viewPointSelect
        )
import Types exposing (..)


type alias State =
    { selectedPoints : Set Id
    }


init : Set Id -> State
init selectedPoints =
    { selectedPoints = selectedPoints
    }



{- svg -}


svg : Callbacks msg -> (State -> msg) -> Data -> State -> Svg msg
svg callbacks updateState data state =
    let
        selectPoint maybeId =
            case maybeId of
                Just id ->
                    if List.member Keyboard.Shift data.pressedKeys then
                        { state
                            | selectedPoints = Set.insert id state.selectedPoints
                        }
                            |> updateState
                    else
                        { state
                            | selectedPoints = Set.singleton id
                        }
                            |> updateState

                Nothing ->
                    updateState state

        clearSelection =
            { state | selectedPoints = Set.empty }
                |> updateState
    in
    Svg.g []
        [ viewSelectedPoints data state
        , svgClearSelection clearSelection data state
        , svgSelectPoint callbacks.focusPoint selectPoint data
        ]


viewSelectedPoints : Data -> State -> Svg msg
viewSelectedPoints data state =
    state.selectedPoints
        |> Set.toList
        |> List.filterMap (viewSelectedPoint data)
        |> Svg.g []


viewSelectedPoint : Data -> Id -> Maybe (Svg msg)
viewSelectedPoint data id =
    let
        pointPosition =
            Dict.get id data.store
                |> Maybe.andThen (position data.store data.variables)
    in
    case pointPosition of
        Just position ->
            Just <|
                Svg.g []
                    [ Svg.drawPoint position
                    , Svg.drawSelector position
                    ]

        Nothing ->
            Nothing


svgClearSelection : msg -> Data -> State -> Svg msg
svgClearSelection clearSelection data state =
    Svg.rect
        [ Svg.x (toString data.viewPort.x)
        , Svg.y (toString data.viewPort.y)
        , Svg.width (toString data.viewPort.width)
        , Svg.height (toString data.viewPort.height)
        , Svg.fill "transparent"
        , Svg.strokeWidth "0"
        , Svg.onClick clearSelection
        ]
        []
