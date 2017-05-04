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
import Tools.Absolute as Absolute
import Tools.Relative as Relative
import Tools.Select as Select
import Types
    exposing
        ( ViewPort
        , PointStore
        )
import View.Canvas as Canvas
import SharedStyles exposing (..)


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
        Html.div
            [ id ToolBar ]
            (allTools |> List.map button)


viewToolInfo : ViewPort -> PointStore -> Tool -> Html Msg
viewToolInfo viewPort store tool =
    case tool of
        Absolute state ->
            Absolute.view (addAbsoluteConfig viewPort) state

        Relative state ->
            Relative.view (addRelativeConfig viewPort) state store

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
        Absolute state ->
            Absolute.svg (addAbsoluteConfig viewPort) state

        Relative state ->
            Relative.svg (addRelativeConfig viewPort) state store

        Select state ->
            Select.svg (selectConfig viewPort) state store

        None ->
            Svg.g [] []



{- tool configurations -}


addAbsoluteConfig : ViewPort -> Absolute.Config Msg
addAbsoluteConfig viewPort =
    { addPoint = AddPoint
    , updatePoint = UpdatePoint
    , stateUpdated = UpdateTool << Absolute
    , viewPort = viewPort
    }


addRelativeConfig : ViewPort -> Relative.Config Msg
addRelativeConfig viewPort =
    { addPoint = AddPoint
    , updatePoint = UpdatePoint
    , stateUpdated = UpdateTool << Relative
    , viewPort = viewPort
    }


selectConfig : ViewPort -> Select.Config Msg
selectConfig viewPort =
    { selectPoint = SelectPoint
    , stateUpdated = UpdateTool << Select
    , viewPort = viewPort
    }
