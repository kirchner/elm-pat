module View exposing (view)

import Html exposing (Html)
import Html.Events as Events
import Svg exposing (Svg)


{- internal -}

import Editor
    exposing
        ( Model
        , Tool(..)
        , toolName
        , Msg(..)
        )
import Tools.AddAbsolute as AddAbsolute
import Tools.AddRelative as AddRelative
import Types exposing (..)
import View.Canvas as Canvas


view : Model -> Html Msg
view model =
    let
        divs =
            [ Just viewToolBox
            , model.selectedTool |> Maybe.map (viewToolInfo model)
            , Just (viewCanvas model)
            ]
    in
        Html.div [] (List.filterMap identity divs)


viewToolBox : Html Msg
viewToolBox =
    let
        tools =
            [ TAddAbsolute
            , TAddRelative
            ]

        button tool =
            Html.button
                [ Events.onClick (SelectTool tool) ]
                [ Html.text (toolName tool) ]
    in
        Html.div []
            (tools |> List.map button)


viewToolInfo : Model -> Tool -> Html Msg
viewToolInfo model tool =
    case tool of
        TAddAbsolute ->
            AddAbsolute.view
                { addPoint = AddPoint
                , stateUpdated = UpdateAddAbsolute
                , viewPort = model.viewPort
                }
                model.addAbsolute

        TAddRelative ->
            AddRelative.view
                { addPoint = AddPoint
                , stateUpdated = UpdateAddRelative
                , viewPort = model.viewPort
                }
                model.addRelative
                model.store


viewCanvas : Model -> Html Msg
viewCanvas model =
    Canvas.view
        (drawTool model)
        model.viewPort
        model.store


drawTool : Model -> Svg Msg
drawTool model =
    case model.selectedTool of
        Just TAddAbsolute ->
            AddAbsolute.svg
                { addPoint = AddPoint
                , stateUpdated = UpdateAddAbsolute
                , viewPort = model.viewPort
                }
                model.addAbsolute

        Just TAddRelative ->
            AddRelative.svg
                { addPoint = AddPoint
                , stateUpdated = UpdateAddRelative
                , viewPort = model.viewPort
                }
                model.addRelative
                model.store

        Nothing ->
            Svg.g [] []
