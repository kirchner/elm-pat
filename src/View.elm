module View exposing (view)

import Editor
    exposing
        ( Msg(..)
        , allTools
        , callbacks
        , data
        , getViewPort
        , toolDescription
        , toolName
        )
import FileBrowser exposing (FileBrowser)
import Html exposing (Html)
import Model exposing (Model, Tool(..))
import Styles.Editor
    exposing
        ( Class(..)
        , class
        , classList
        )
import Svg exposing (Svg)
import Tools.Absolute as Absolute
import Tools.Between as Between
import Tools.CircleIntersection as CircleIntersection
import Tools.Common
    exposing
        ( Callbacks
        , Data
        )
import Tools.Distance as Distance
import Tools.ExtendPiece as ExtendPiece
import Tools.Relative as Relative
import View.Canvas as Canvas
import Views.PointTable as PointTable
import Views.ToolBox as ToolBox
import Views.VariableTable as VariableTable


{- main view -}


view : Model -> Html Msg
view model =
    let
        data =
            Editor.data model
    in
    [ Just <|
        Html.div
            [ class [ Container, ContainerTopLeftLeft ] ]
            [ ToolBox.view data ]
    , Just <|
        Html.div
            [ class [ Container, ContainerTopRight ] ]
            [ FileBrowser.view
                { lift = FileBrowserMsg
                , clearSession = Just ClearSession
                , loadRemoteFile = Just LoadRemoteFile
                , restoreSession = Just RestoreSession
                , undo = Just Undo
                , redo = Just Redo
                , dumpFile0 = Just DumpFile0
                }
                model.undoList
            ]
    , viewToolInfo callbacks data model.tool
    , Just <|
        Html.div
            [ class [ Container, ContainerBottomLeft ] ]
            [ PointTable.view { setName = SetPointName } data ]
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


viewToolInfo : Callbacks Msg -> Data -> Tool -> Maybe (Html Msg)
viewToolInfo callbacks data tool =
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

        Between state ->
            Just <|
                Html.div
                    [ class [ Container, ContainerTopLeft ] ]
                    [ Between.view callbacks (UpdateTool << Between) data state ]

        CircleIntersection state ->
            Just <|
                Html.div
                    [ class [ Container, ContainerTopLeft ] ]
                    [ CircleIntersection.view callbacks (UpdateTool << CircleIntersection) data state ]


        ExtendPiece _ ->
            Nothing

        None ->
            Nothing



{- canvas -}


viewCanvas : Model -> Html Msg
viewCanvas model =
    Canvas.view
        (drawTool callbacks (data model) model.tool)
        DragStart
        FocusPoint
        SelectPoint
        (\id segment ->
            UpdateTool
                (ExtendPiece
                    (ExtendPiece.init id
                        segment
                    )
                )
        )
        Zoom
        (data model)
        model.pieceStore


drawTool : Callbacks Msg -> Data -> Tool -> Svg Msg
drawTool callbacks data tool =
    case tool of
        Absolute state ->
            Absolute.svg callbacks (UpdateTool << Absolute) data state

        Relative state ->
            Relative.svg callbacks (UpdateTool << Relative) data state

        Distance state ->
            Distance.svg callbacks (UpdateTool << Distance) data state

        Between state ->
            Between.svg callbacks (UpdateTool << Between) data state

        CircleIntersection state ->
            CircleIntersection.svg callbacks (UpdateTool << CircleIntersection) data state

        ExtendPiece state ->
            ExtendPiece.svg callbacks data state

        None ->
            Svg.g [] []
