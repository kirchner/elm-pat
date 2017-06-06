module View exposing (view)

import Dict exposing (Dict)
import Editor
    exposing
        ( Model
        , Msg(..)
        , Tool(..)
        , allTools
        , getViewPort
        , toolDescription
        , toolName
        )
import Expr exposing (..)
import Html exposing (Html)
import Html.Attributes as Html
import Html.Events as Events
import Math.Vector2 exposing (..)
import Styles.Colors exposing (..)
import Styles.Editor
    exposing
        ( Class(..)
        , class
        , classList
        )
import Svg exposing (Svg)
import Tools.Absolute as Absolute
import Tools.Distance as Distance
import Tools.Relative as Relative
import Tools.Select as Select
import Types
    exposing
        ( Id
        , Point
        , PointStore
        , Position
        , ViewPort
        )
import View.Canvas as Canvas
import Views.PointTable as PointTable
import Views.ToolBox as ToolBox
import Views.VariableTable as VariableTable


{- main view -}


view : Model -> Html Msg
view model =
    [ Just <|
        Html.div
            [ class [ Container, ContainerTopLeftLeft ] ]
            [ ToolBox.view ]
    , viewToolInfo model.viewPort
        model.variables
        model.store
        model.cursorPosition
        model.tool
    , Just <|
        Html.div
            [ class [ Container, ContainerBottomLeft ] ]
            [ PointTable.view model.variables model.store ]
    , Just <|
        Html.div
            [ class [ Container, ContainerBottomRight ] ]
            [ VariableTable.view model.variables model.newName model.newValue ]
    , Just <| viewCanvas model
    ]
        |> List.filterMap identity
        |> Html.div
            [ class [ Main ]
            , classList [ ( MouseMove, model.drag /= Nothing ) ]
            ]



{- tool box -}


viewToolInfo : ViewPort -> Dict String E -> PointStore -> Maybe Position -> Tool -> Maybe (Html Msg)
viewToolInfo viewPort variables store cursorPosition tool =
    let
        data =
            { store = store
            , variables = variables
            , viewPort = viewPort
            , cursorPosition = cursorPosition
            , focusedPoint = Nothing
            }

        callbacks =
            { addPoint = AddPoint
            , updateCursorPosition = UpdateCursorPosition
            , focusPoint = FocusPoint
            }
    in
    case tool of
        Absolute state ->
            Just <|
                Html.div
                    [ class [ Container, ContainerTopLeft ] ]
                    [ Absolute.view callbacks (UpdateTool << Absolute) data state ]

        Relative state ->
            Just <|
                Html.div
                    [ class [ Container, ContainerTopLeft ] ]
                    [ Relative.view (addRelativeConfig viewPort) state store ]

        Distance state ->
            Just <|
                Html.div
                    [ class [ Container, ContainerTopLeft ] ]
                    [ Distance.view (addDistanceConfig viewPort) state store ]

        Select _ ->
            Nothing

        None ->
            Nothing



{- canvas -}


viewCanvas : Model -> Html Msg
viewCanvas model =
    Canvas.view
        (drawTool model.viewPort
            model.variables
            model.store
            model.cursorPosition
            model.tool
        )
        DragStart
        (getViewPort model.viewPort model.drag)
        model.store
        model.variables


drawTool :
    ViewPort
    -> Dict String E
    -> PointStore
    -> Maybe Position
    -> Tool
    -> Svg Msg
drawTool viewPort variables store cursorPosition tool =
    let
        data =
            { store = store
            , variables = variables
            , viewPort = viewPort
            , cursorPosition = cursorPosition
            , focusedPoint = Nothing
            }

        callbacks =
            { addPoint = AddPoint
            , updateCursorPosition = UpdateCursorPosition
            , focusPoint = FocusPoint
            }
    in
    case tool of
        Absolute state ->
            Absolute.svg callbacks (UpdateTool << Absolute) data state

        Relative state ->
            Relative.svg (addRelativeConfig viewPort) state store variables

        Distance state ->
            Distance.svg (addDistanceConfig viewPort) state store variables

        Select state ->
            Select.svg (selectConfig viewPort) state store variables

        None ->
            Svg.g [] []



{- tool configurations -}


addRelativeConfig : ViewPort -> Relative.Config Msg
addRelativeConfig viewPort =
    { addPoint = AddPoint
    , updatePoint = UpdatePoint
    , stateUpdated = UpdateTool << Relative
    , viewPort = viewPort
    }


addDistanceConfig : ViewPort -> Distance.Config Msg
addDistanceConfig viewPort =
    { addPoint = AddPoint
    , updatePoint = UpdatePoint
    , stateUpdated = UpdateTool << Distance
    , viewPort = viewPort
    }


selectConfig : ViewPort -> Select.Config Msg
selectConfig viewPort =
    { selectPoint = SelectPoint
    , stateUpdated = UpdateTool << Select
    , viewPort = viewPort
    }
