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
import Keyboard.Extra exposing (Key)
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
        model.pressedKeys
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


viewToolInfo : ViewPort -> Dict String E -> PointStore -> Maybe Position -> List Key -> Tool -> Maybe (Html Msg)
viewToolInfo viewPort variables store cursorPosition pressedKeys tool =
    let
        data =
            { store = store
            , variables = variables
            , viewPort = viewPort
            , cursorPosition = cursorPosition
            , focusedPoint = Nothing
            , pressedKeys = pressedKeys
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
                    [ Relative.view callbacks (UpdateTool << Relative) data state ]

        Distance state ->
            Just <|
                Html.div
                    [ class [ Container, ContainerTopLeft ] ]
                    [ Distance.view callbacks (UpdateTool << Distance) data state ]

        Select _ ->
            Nothing



{- canvas -}


viewCanvas : Model -> Html Msg
viewCanvas model =
    Canvas.view
        (drawTool model.viewPort
            model.variables
            model.store
            model.cursorPosition
            model.focusedPoint
            model.pressedKeys
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
    -> Maybe Id
    -> List Key
    -> Tool
    -> Svg Msg
drawTool viewPort variables store cursorPosition focusedPoint pressedKeys tool =
    let
        data =
            { store = store
            , variables = variables
            , viewPort = viewPort
            , cursorPosition = cursorPosition
            , focusedPoint = focusedPoint
            , pressedKeys = pressedKeys
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
            Relative.svg callbacks (UpdateTool << Relative) data state

        Distance state ->
            Distance.svg callbacks (UpdateTool << Distance) data state

        Select state ->
            Select.svg callbacks (UpdateTool << Select) data state
