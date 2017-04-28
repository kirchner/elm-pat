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
        , allTools
        , Msg(..)
        )
import Tools.AddAbsolute as AddAbsolute
import Tools.AddRelative as AddRelative
import Tools.Select as Select
import Types exposing (..)
import View.Canvas as Canvas


{- main view -}


view : Model -> Html Msg
view model =
    Html.div []
        [ viewToolBox
        , viewToolInfo model.viewPort model.store model.tool
        , viewCanvas model
        ]



{- tool box -}


viewToolBox : Html Msg
viewToolBox =
    let
        button tool =
            Html.button
                [ Events.onClick (UpdateTool tool) ]
                [ Html.text (toolName tool) ]
    in
        Html.div [] (allTools |> List.map button)


viewToolInfo : ViewPort -> PointStore -> Tool -> Html Msg
viewToolInfo viewPort store tool =
    case tool of
        AddAbsolute state ->
            AddAbsolute.view (addAbsoluteConfig viewPort) state

        AddRelative state ->
            AddRelative.view (addRelativeConfig viewPort) state store

        Select _ ->
            Html.div [] []

        None ->
            Html.div [] []



{- canvas -}


viewCanvas : Model -> Html Msg
viewCanvas model =
    Canvas.view
        (drawTool model.viewPort model.store model.tool)
        model.viewPort
        model.store


drawTool : ViewPort -> PointStore -> Tool -> Svg Msg
drawTool viewPort store tool =
    case tool of
        AddAbsolute state ->
            AddAbsolute.svg (addAbsoluteConfig viewPort) state

        AddRelative state ->
            AddRelative.svg (addRelativeConfig viewPort) state store

        Select state ->
            Select.svg (selectConfig viewPort) state store

        None ->
            Svg.g [] []



{- tool configurations -}


addAbsoluteConfig : ViewPort -> AddAbsolute.Config Msg
addAbsoluteConfig viewPort =
    { addPoint = AddPoint
    , updatePoint = UpdatePoint
    , stateUpdated = UpdateTool << AddAbsolute
    , viewPort = viewPort
    }


addRelativeConfig : ViewPort -> AddRelative.Config Msg
addRelativeConfig viewPort =
    { addPoint = AddPoint
    , stateUpdated = UpdateTool << AddRelative
    , viewPort = viewPort
    }


selectConfig : ViewPort -> Select.Config Msg
selectConfig viewPort =
    { selectPoint = SelectPoint
    , stateUpdated = UpdateTool << Select
    , viewPort = viewPort
    }
