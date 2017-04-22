module View exposing (view)

import Html exposing (Html)
import Html.Events as Events
import Svg exposing (Svg)


{- internal -}

import Editor
    exposing
        ( Model
        , svgToCanvas
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
            Html.map AddAbsoluteMsg (AddAbsolute.view model.addAbsolute)

        TAddRelative ->
            Html.map AddRelativeMsg (AddRelative.view model.addRelative model.store)


viewCanvas : Model -> Html Msg
viewCanvas model =
    let
        moveCallback p =
            UpdateMouse p
    in
        Canvas.view
            (clickCallback model)
            moveCallback
            (drawTool model)
            model.center
            model.store


clickCallback : Model -> Position -> Msg
clickCallback model p =
    case model.selectedTool of
        Just TAddAbsolute ->
            Handle <|
                AddAbsolute.callback
                    model.addAbsolute
                    (svgToCanvas model p)

        Just TAddRelative ->
            Handle Nothing

        Nothing ->
            Handle Nothing


drawTool : Model -> Svg Msg
drawTool model =
    case model.selectedTool of
        Just TAddAbsolute ->
            AddAbsolute.draw
                model.addAbsolute
                (svgToCanvas model model.mousePosition)

        Just TAddRelative ->
            AddRelative.draw
                model.addRelative
                model.store
                (svgToCanvas model model.mousePosition)

        Nothing ->
            Svg.g [] []
