module Main exposing (main)

import Data.Expr as Expr exposing (E)
import Data.Piece as Piece exposing (Piece)
import Data.Point as Point exposing (Point)
import Data.Position as Position exposing (Position)
import Data.Store as Store exposing (Id, Store)
import Data.ViewPort as ViewPort exposing (ViewPort)
import Dict exposing (Dict)
import FileBrowser exposing (FileBrowser)
import Html exposing (Html)
import Html.Attributes as Attributes
import Http
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Keyboard.Extra as Keyboard exposing (Key)
import Mouse
import Ports
import Svg exposing (Svg)
import Task
import Tools exposing (Tool(..))
import Tools.Callbacks exposing (Callbacks)
import Tools.Data exposing (Data)
import Tools.ExtendPiece as ExtendPiece
import UndoList exposing (UndoList)
import Views.Canvas as Canvas
import Views.Common as Common
import Views.PointTable as PointTable
import Views.VariableTable as VariableTable
import Window


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



---- MODEL


type alias Model =
    { store : Store Point
    , pieceStore : Store Piece
    , variables : Dict String E
    , newName : Maybe String
    , newValue : Maybe E
    , tool : Maybe Tool
    , viewPort : ViewPort
    , drag : Maybe Drag
    , cursorPosition : Maybe Position
    , focusedPoint : Maybe (Id Point)
    , pressedKeys : List Key
    , selectedPoints : List (Id Point)
    , fileBrowser : FileBrowser
    , undoList : UndoList File
    }


type alias File =
    { store : Store Point
    , pieceStore : Store Piece
    , variables : Dict String E
    , selectedPoints : List (Id Point)
    }


defaultModel : Model
defaultModel =
    { store = Store.empty
    , pieceStore = Store.empty
    , variables = Dict.empty
    , newName = Nothing
    , newValue = Nothing
    , tool = Nothing
    , viewPort = ViewPort.default
    , drag = Nothing
    , cursorPosition = Nothing
    , focusedPoint = Nothing
    , pressedKeys = []
    , selectedPoints = []
    , fileBrowser = FileBrowser.defaultModel
    , undoList =
        UndoList.fresh
            { store = Store.empty
            , pieceStore = Store.empty
            , variables = Dict.empty
            , selectedPoints = []
            }
    }


type alias Drag =
    { start : Position
    , current : Position
    }


dataFromModel : Model -> Data
dataFromModel model =
    { store = model.store
    , pieceStore = model.pieceStore
    , variables = model.variables
    , viewPort = getViewPort model.viewPort model.drag
    , cursorPosition = model.cursorPosition
    , focusedPoint = model.focusedPoint
    , pressedKeys = model.pressedKeys
    , selectedPoints = model.selectedPoints
    }


callbacks : Callbacks Msg
callbacks =
    { addPoint = PointsMsg << AddPoint
    , updateCursorPosition = UpdateCursorPosition
    , focusPoint = PointsMsg << Focus
    , selectPoint = PointsMsg << Select
    , clearSelection = PointsMsg ClearSelection
    , extendPiece = ExtendPieceMsg
    }



---- UPDATE


type Msg
    = UpdateTool Tool
    | UpdateCursorPosition (Maybe Position)
    | KeyMsg Keyboard.Msg
    | KeyDown Keyboard.Key
    | ExtendPieceMsg (Id Piece) (Id Point) (Maybe (Id Point))
    | DumpFile0
    | ViewPortMsg ViewPortMsg
    | FileBrowserMsg FileBrowser.Msg
    | SessionsMsg SessionsMsg
    | ToolMsg Tools.Msg
    | PointsMsg PointsMsg
    | VariablesMsg VariablesMsg


type ViewPortMsg
    = Resize Window.Size
    | Zoom Float
    | DragStart Position
    | DragAt Position
    | DragStop Position


type SessionsMsg
    = Clear
    | Restore File
    | LoadRemoteFile String
    | LoadRemoteFileError Http.Error
    | Undo
    | Redo


type PointsMsg
    = AddPoint Point
    | Set (Id Point) Point
    | Delete (Id Point)
    | Focus (Maybe (Id Point))
    | Select (Maybe (Id Point))
    | Deselect (Maybe (Id Point))
    | ClearSelection
    | SetPointName (Id Point) String


type VariablesMsg
    = SetName String String
    | SetValue String String
    | SetNewValue String
    | SetNewName String
    | Add


type alias Flags =
    { file0 : Maybe Value }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        restoredModel =
            case flags.file0 of
                Just file ->
                    restore file defaultModel

                Nothing ->
                    defaultModel
    in
    ( restoredModel
    , Task.perform (ViewPortMsg << Resize) Window.size
    )


type alias Ports =
    { autofocus : () -> Cmd Msg
    , serialize : Value -> Cmd Msg
    , dumpFile0 : () -> Cmd Msg
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        ports =
            { autofocus = Ports.autofocus
            , serialize = Ports.serialize
            , dumpFile0 = Ports.dumpFile0
            }
    in
    updateUndoList ports model msg
        >> updateAutoFocus ports model
        >> updateStorage ports model
    <|
        case msg of
            UpdateCursorPosition position ->
                ( { model
                    | cursorPosition =
                        position
                            |> Maybe.map (ViewPort.svgToCanvas model.viewPort)
                  }
                , Cmd.none
                )

            KeyMsg keyMsg ->
                ( { model
                    | pressedKeys =
                        Keyboard.update keyMsg model.pressedKeys
                  }
                , Cmd.none
                )

            KeyDown key ->
                ( case key of
                    Keyboard.CharP ->
                        case
                            model.selectedPoints
                                |> Piece.fromList model.store model.variables
                                |> Maybe.map
                                    (\piece ->
                                        Store.insert piece model.pieceStore
                                            |> Tuple.second
                                    )
                        of
                            Just pieceStore ->
                                { model | pieceStore = pieceStore }

                            Nothing ->
                                model

                    Keyboard.CharA ->
                        { model
                            | tool =
                                Tools.initAbsolute
                                    |> Just
                        }

                    Keyboard.CharB ->
                        { model
                            | tool =
                                dataFromModel model
                                    |> Tools.initBetween
                                    |> Just
                        }

                    Keyboard.CharE ->
                        { model
                            | tool =
                                if List.member Keyboard.Shift model.pressedKeys then
                                    dataFromModel model
                                        |> Tools.initDistance
                                        |> Just
                                else
                                    dataFromModel model
                                        |> Tools.initRelative
                                        |> Just
                        }

                    Keyboard.Escape ->
                        { model
                            | tool = Nothing
                            , cursorPosition = Nothing
                        }

                    _ ->
                        model
                , Cmd.none
                )

            ExtendPieceMsg pieceId id maybeNewId ->
                ( case maybeNewId of
                    Just newId ->
                        let
                            updatePiece =
                                Maybe.map <|
                                    Piece.insertAfter
                                        model.store
                                        model.variables
                                        newId
                                        id
                        in
                        { model
                            | pieceStore =
                                Store.update pieceId updatePiece model.pieceStore
                            , tool = Nothing
                        }

                    Nothing ->
                        { model | tool = Nothing }
                , Cmd.none
                )

            ToolMsg toolMsg ->
                case model.tool of
                    Just tool ->
                        let
                            ( newTool, toolCmd, maybeMsg ) =
                                Tools.update callbacks toolMsg tool

                            cmd =
                                toolCmd
                                    |> Cmd.map ToolMsg

                            newModel =
                                { model | tool = Just newTool }
                        in
                        case maybeMsg of
                            Just nextMsg ->
                                update nextMsg newModel
                                    |> andDo cmd

                            Nothing ->
                                ( newModel, cmd )

                    Nothing ->
                        ( model, Cmd.none )

            DumpFile0 ->
                ( model
                , ports.dumpFile0 ()
                )

            ViewPortMsg viewPortMsg ->
                let
                    ( newModel, clearSelection ) =
                        updateViewPort viewPortMsg model
                in
                ( { newModel
                    | selectedPoints =
                        if clearSelection then
                            []
                        else
                            model.selectedPoints
                  }
                , Cmd.none
                )

            SessionsMsg sessionsMsg ->
                updateSessions SessionsMsg sessionsMsg model

            PointsMsg pointsMsg ->
                ( updatePoints pointsMsg model
                , Cmd.none
                )

            VariablesMsg variablesMsg ->
                ( updateVariables variablesMsg model
                , Cmd.none
                )

            FileBrowserMsg fileBrowserMsg ->
                ( { model
                    | fileBrowser =
                        FileBrowser.update fileBrowserMsg model.fileBrowser
                  }
                , Cmd.none
                )

            UpdateTool tool ->
                ( { model | tool = Just tool }
                , Cmd.none
                )


type alias WithViewPort r =
    { r
        | viewPort : ViewPort
        , drag : Maybe Drag
    }


updateViewPort : ViewPortMsg -> WithViewPort r -> ( WithViewPort r, Bool )
updateViewPort msg model =
    case msg of
        Resize { width, height } ->
            ( { model
                | viewPort =
                    model.viewPort |> ViewPort.resize width height
              }
            , False
            )

        Zoom factor ->
            let
                newZoom =
                    model.viewPort.zoom
                        |> (+) (factor * 0.005)
                        |> clamp 0.5 5
            in
            ( { model
                | viewPort =
                    model.viewPort |> ViewPort.setZoom newZoom
              }
            , False
            )

        DragStart position ->
            ( { model | drag = Just (Drag position position) }
            , False
            )

        DragAt position ->
            ( { model
                | drag =
                    model.drag
                        |> Maybe.map (\{ start } -> Drag start position)
              }
            , False
            )

        DragStop position ->
            ( { model
                | drag = Nothing
                , viewPort = getViewPort model.viewPort model.drag
              }
            , case model.drag of
                Just drag ->
                    drag.start == drag.current

                Nothing ->
                    False
            )


updateSessions : (SessionsMsg -> msg) -> SessionsMsg -> Model -> ( Model, Cmd msg )
updateSessions lift msg model =
    case msg of
        Undo ->
            ( { model | undoList = UndoList.undo model.undoList }
            , Cmd.none
            )

        Redo ->
            ( { model | undoList = UndoList.redo model.undoList }
            , Cmd.none
            )

        LoadRemoteFile url ->
            let
                handle =
                    Result.map (lift << Restore)
                        >> Result.mapError (lift << LoadRemoteFileError)
                        >> (\result ->
                                case result of
                                    Ok x ->
                                        x

                                    Err x ->
                                        x
                           )
            in
            ( model
            , Http.send handle (Http.get url decode)
            )

        Restore file ->
            let
                newModel =
                    load_ file model
            in
            ( { newModel | undoList = UndoList.fresh (save newModel) }
            , Cmd.none
            )

        LoadRemoteFileError httpError ->
            let
                _ =
                    Debug.log "loadRemoteFileError" httpError
            in
            ( model
            , Cmd.none
            )

        Clear ->
            updateSessions lift (Restore empty) model


type alias WithPoints r =
    { r
        | store : Store Point
        , focusedPoint : Maybe (Id Point)
        , selectedPoints : List (Id Point)
        , tool : Maybe Tool
        , cursorPosition : Maybe Position
        , pressedKeys : List Key
    }


updatePoints : PointsMsg -> WithPoints r -> WithPoints r
updatePoints msg model =
    case msg of
        SetPointName id name ->
            { model
                | store =
                    Store.update id
                        (Maybe.map (Point.setName name))
                        model.store
            }

        AddPoint point ->
            let
                ( id, newStore ) =
                    Store.insert point model.store

                name =
                    "point #" ++ (id |> Store.toInt |> toString)

                storeWithNamedPoint =
                    newStore
                        |> Store.update id (Maybe.map (Point.setName name))
            in
            { model
                | store = storeWithNamedPoint
                , tool = Nothing
                , cursorPosition = Nothing
                , focusedPoint = Nothing
                , selectedPoints = [ id ]
            }

        Set id point ->
            { model
                | store = Store.update id (\_ -> Just point) model.store
                , tool = Nothing
            }

        Delete id ->
            { model | store = Store.remove id model.store }

        Focus id ->
            { model | focusedPoint = id }

        Select maybeId ->
            case maybeId of
                Just id ->
                    if List.member Keyboard.Shift model.pressedKeys then
                        { model
                            | selectedPoints =
                                if List.member id model.selectedPoints then
                                    List.filter ((/=) id) model.selectedPoints
                                else
                                    id :: model.selectedPoints
                        }
                    else
                        { model | selectedPoints = [ id ] }

                Nothing ->
                    model

        Deselect maybeId ->
            case maybeId of
                Just id ->
                    { model
                        | selectedPoints =
                            List.filter ((/=) id) model.selectedPoints
                    }

                Nothing ->
                    model

        ClearSelection ->
            { model | selectedPoints = [] }


type alias WithVariables r =
    { r
        | variables : Dict String E
        , newName : Maybe String
        , newValue : Maybe E
    }


updateVariables : VariablesMsg -> WithVariables r -> WithVariables r
updateVariables msg model =
    case msg of
        SetNewName s ->
            { model | newName = Expr.parseVariable s }

        SetNewValue s ->
            { model | newValue = Expr.parse s }

        Add ->
            case ( model.newName, model.newValue ) of
                ( Just name, Just value ) ->
                    { model
                        | variables =
                            Dict.insert name value model.variables
                        , newName = Nothing
                        , newValue = Nothing
                    }

                _ ->
                    model

        SetName id name ->
            { model
                | variables =
                    case Dict.get id model.variables of
                        Just expr ->
                            model.variables
                                |> Dict.insert name expr
                                |> Dict.remove id

                        Nothing ->
                            model.variables
            }

        SetValue id value ->
            case Expr.parse value of
                Just expr ->
                    { model
                        | variables = Dict.insert id expr model.variables
                    }

                Nothing ->
                    model


andDo : Cmd msg -> ( model, Cmd msg ) -> ( model, Cmd msg )
andDo cmd ( model, cmds ) =
    ( model
    , Cmd.batch [ cmd, cmds ]
    )


updateAutoFocus : Ports -> Model -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
updateAutoFocus ports oldModel ( model, cmd ) =
    ( model
    , if (oldModel.tool == Nothing) && (model.tool /= Nothing) then
        Cmd.batch [ ports.autofocus (), cmd ]
      else
        cmd
    )


updateStorage : Ports -> Model -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
updateStorage ports _ ( model, cmds ) =
    ( model
    , Cmd.batch
        [ ports.serialize (store model)
        , cmds
        ]
    )


updateUndoList : Ports -> Model -> Msg -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
updateUndoList ports _ msg ( model, cmds ) =
    let
        -- messages that definitely do not affect undoList
        blacklist msg =
            case msg of
                UpdateTool _ ->
                    True

                ViewPortMsg _ ->
                    True

                PointsMsg (Focus _) ->
                    True

                FileBrowserMsg _ ->
                    True

                SessionsMsg _ ->
                    True

                _ ->
                    False
    in
    ( { model
        | undoList =
            let
                file =
                    save model
            in
            if not (blacklist msg) && (model.undoList.present /= file) then
                UndoList.new file model.undoList
            else
                model.undoList
      }
    , cmds
    )


getViewPort : ViewPort -> Maybe Drag -> ViewPort
getViewPort oldViewPort drag =
    case drag of
        Nothing ->
            oldViewPort

        Just { start, current } ->
            let
                deltaX =
                    oldViewPort.zoom * toFloat (current.x - start.x) |> floor

                deltaY =
                    oldViewPort.zoom * toFloat (current.y - start.y) |> floor

                offset =
                    { x = oldViewPort.offset.x - deltaX
                    , y = oldViewPort.offset.y - deltaY
                    }
            in
            { oldViewPort | offset = offset }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Window.resizes (ViewPortMsg << Resize)
        , Keyboard.subscriptions
            |> Sub.map KeyMsg
        , case model.drag of
            Nothing ->
                Sub.batch
                    [ Keyboard.downs KeyDown ]

            Just _ ->
                Sub.batch
                    [ Mouse.moves (ViewPortMsg << DragAt)
                    , Mouse.ups (ViewPortMsg << DragStop)
                    ]
        ]



---- VIEW


view : Model -> Html Msg
view model =
    let
        data =
            dataFromModel model
    in
    [ Html.div
        [ Attributes.class "editor__container"
        , Attributes.class "editor__container--top-right"
        ]
        [ viewToolBox data (model.tool /= Nothing) ]
    , Html.div
        [ Attributes.class "editor__container"
        , Attributes.class "editor__container--bottom-right"
        ]
        [ FileBrowser.view
            { lift = FileBrowserMsg
            , clearSession = Just (SessionsMsg Clear)
            , loadRemoteFile = Just (SessionsMsg << LoadRemoteFile)
            , restoreSession = Just (SessionsMsg << Restore)
            , undo = Just (SessionsMsg Undo)
            , redo = Just (SessionsMsg Redo)
            , dumpFile0 = Just DumpFile0
            }
            model.undoList
        ]
    , Html.div
        [ Attributes.class "editor__container"
        , Attributes.class "editor__container--bottom-left"
        ]
        [ PointTable.view
            { setName = \id name -> PointsMsg (SetPointName id name)
            , selectPoint = PointsMsg << Select << Just
            , deletePoint = PointsMsg << Delete
            , deselectPoint = PointsMsg << Deselect << Just
            }
            data
        ]
    , Html.div
        [ Attributes.class "editor__container"
        , Attributes.class "editor__container--top-left"
        ]
        [ VariableTable.view
            { setName = SetName
            , setValue = SetValue
            , setNewName = SetNewName
            , setNewValue = SetNewValue
            , add = Add
            }
            model.variables
            model.newName
            model.newValue
            |> Html.map VariablesMsg
        ]
    , case viewToolInfo data model.tool of
        Just toolInfo ->
            Html.div
                [ Attributes.class "editor__container"
                , Attributes.class "editor__container--top-middle"
                ]
                [ Html.div
                    [ Attributes.class "tool__container" ]
                    [ Html.div
                        [ Attributes.class "tool__heading" ]
                        [ model.tool
                            |> Maybe.map Tools.name
                            |> Maybe.withDefault ""
                            |> Html.text
                        ]
                    , toolInfo
                    ]
                ]

        Nothing ->
            Html.div [] []
    , viewCanvas model
    ]
        |> Html.div
            [ Attributes.class "editor__main"
            , Attributes.classList
                [ ( "editor__main--mouse-move", model.drag /= Nothing ) ]
            ]



-- TOOL BOX


viewToolBox : Data -> Bool -> Html Msg
viewToolBox data toolActive =
    let
        button tool =
            [ Just (Common.iconBig "edit" (UpdateTool tool))
            , if toolActive then
                Nothing
              else
                Just <|
                    Html.div
                        [ Attributes.class "tool__tool-button-info" ]
                        [ tool
                            |> Tools.description
                            |> Html.text
                        ]
            ]
                |> List.filterMap identity
                |> Html.div
                    [ Attributes.class "tool__tool-button-container" ]
    in
    Html.div
        [ Attributes.class "tool__tool-box" ]
        (Tools.all data |> List.map button)



-- TOOL INFO


viewToolInfo : Data -> Maybe Tool -> Maybe (Html Msg)
viewToolInfo data tool =
    tool
        |> Maybe.map (Tools.view callbacks data)
        |> Maybe.map (Html.map ToolMsg)



-- CANVAS


viewCanvas : Model -> Html Msg
viewCanvas model =
    Canvas.view
        { startDrag = ViewPortMsg << DragStart
        , focusPoint = PointsMsg << Focus
        , selectPoint = PointsMsg << Select
        , extendPiece =
            \id segment ->
                UpdateTool
                    (ExtendPiece
                        (ExtendPiece.init id
                            segment
                        )
                    )
        , updateZoom =
            ViewPortMsg << Zoom
        }
        model.pieceStore
        (drawTool callbacks (dataFromModel model) model.tool)
        (dataFromModel model)


drawTool : Callbacks Msg -> Data -> Maybe Tool -> Svg Msg
drawTool callbacks data tool =
    Tools.svg callbacks UpdateTool data tool



---- (DE-)SERIALIZATION


empty : File
empty =
    { store = Store.empty
    , pieceStore = Store.empty
    , variables = Dict.empty
    , selectedPoints = []
    }


load : File -> Model
load file =
    load_ file defaultModel


load_ : File -> Model -> Model
load_ file defaultModel =
    { defaultModel
        | store = file.store
        , pieceStore = file.pieceStore
        , variables = file.variables
        , selectedPoints = file.selectedPoints
    }


save : Model -> File
save model =
    { store = model.store
    , pieceStore = model.pieceStore
    , variables = model.variables
    , selectedPoints = model.selectedPoints
    }


store : Model -> Encode.Value
store =
    save >> encode


restore : Decode.Value -> Model -> Model
restore value defaultModel =
    Decode.decodeValue decode value
        |> Result.map (\file -> load_ file defaultModel)
        |> Result.toMaybe
        |> Maybe.withDefault defaultModel



-- SERIALIZATION


encode : File -> Encode.Value
encode model =
    Encode.object
        [ ( "store", Store.encode Point.encode model.store )
        , ( "pieceStore", Store.encode Piece.encode model.pieceStore )
        , ( "variables", encodeVariables model.variables )
        , ( "selectedPoints", Encode.list (List.map Store.encodeId model.selectedPoints) )
        ]


decode : Decoder File
decode =
    Decode.map4 File
        (Decode.at [ "store" ] (Store.decode Point.decode))
        (Decode.at [ "pieceStore" ] (Store.decode Piece.decode))
        (Decode.at [ "variables" ] decodeVariables)
        (Decode.at [ "selectedPoints" ] (Decode.list Store.decodeId))


encodeVariables : Dict String E -> Encode.Value
encodeVariables variables =
    variables
        |> Dict.map (\id expr -> ( id, Expr.encode expr ))
        |> Dict.values
        |> Encode.object


decodeVariables : Decoder (Dict String E)
decodeVariables =
    Decode.dict Expr.decode
