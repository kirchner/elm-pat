module Editor
    exposing
        ( Flags
        , Msg(..)
        , Ports
        , allTools
        , callbacks
        , data
        , getViewPort
        , init
        , subscriptions
        , toolDescription
        , toolName
        , update
        )

{- internal -}

import Dict exposing (Dict)
import Expr
    exposing
        ( E
        , parse
        , parseVariable
        )
import File exposing (File)
import FileBrowser exposing (FileBrowser)
import Http
import Json.Decode exposing (Value)
import Keyboard.Extra as Keyboard exposing (Key)
import Model exposing (..)
import Mouse
import Piece exposing (Piece)
import Point exposing (Point)
import Store exposing (Id, Store)
import Task
import Tools.Absolute as Absolute
import Tools.Between as Between
import Tools.Common
    exposing
        ( Callbacks
        , Data
        )
import Tools.Distance as Distance
import Tools.Relative as Relative
import Types exposing (..)
import Window


-- TODO: move most? of this to Model:


data : Model -> Data
data model =
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
    { addPoint = AddPoint
    , updateCursorPosition = UpdateCursorPosition
    , focusPoint = FocusPoint
    , selectPoint = SelectPoint
    , clearSelection = ClearSelection
    , extendPiece = ExtendPieceMsg
    }


toolName : Tool -> String
toolName tool =
    case tool of
        Absolute _ ->
            "absolute"

        Relative _ ->
            "relative"

        Distance _ ->
            "distance"

        Between _ ->
            "between"

        ExtendPiece _ ->
            "extend piece"

        None ->
            "none"


toolDescription : Tool -> String
toolDescription tool =
    case tool of
        Absolute _ ->
            "add a point given by absolute coordinates"

        Relative _ ->
            "relative"

        Distance _ ->
            "distance"

        Between _ ->
            "between"

        ExtendPiece _ ->
            "extend piece"

        None ->
            "none"


allTools : Data -> List Tool
allTools data =
    [ Absolute Absolute.init
    , Relative (Relative.init data)
    , Distance (Distance.init data)
    , Between (Between.init data)
    ]


type Msg
    = UpdateTool Tool
    | AddPoint Point
    | UpdatePoint (Id Point) Point
    | DeletePoint (Id Point)
    | ValueUpdated String
    | NameUpdated String
    | AddVariable
    | Resize Window.Size
    | DragStart Position
    | DragAt Position
    | DragStop Position
    | UpdateCursorPosition (Maybe Position)
    | FocusPoint (Maybe (Id Point))
    | KeyMsg Keyboard.Msg
    | KeyDown Keyboard.Key
    | SelectPoint (Maybe (Id Point))
    | ClearSelection
    | ExtendPieceMsg (Id Piece) (Id Point) (Maybe (Id Point))
    | FileBrowserMsg FileBrowser.Msg
    | ClearSession
    | RestoreSession File
    | LoadRemoteFile String
    | LoadRemoteFileError Http.Error


type alias Flags =
    { file0 : Maybe Value
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        restoredModel =
            case flags.file0 of
                Just file ->
                    File.restore file defaultModel

                Nothing ->
                    defaultModel
    in
    restoredModel ! [ Task.perform Resize Window.size ]


type alias Ports =
    { autofocus : () -> Cmd Msg
    , serialize : Value -> Cmd Msg
    }


update : Ports -> Msg -> Model -> ( Model, Cmd Msg )
update ports msg model =
    updateAutoFocus ports model
        >> updateStorage ports model
    <|
        case msg of
            LoadRemoteFile url ->
                let
                    handle =
                        Result.map RestoreSession
                            >> Result.mapError LoadRemoteFileError
                            >> (\result ->
                                    case result of
                                        Ok x ->
                                            x

                                        Err x ->
                                            x
                               )
                in
                model ! [ Http.send handle (Http.get url File.decode) ]

            RestoreSession file ->
                File.load_ file model ! []

            LoadRemoteFileError httpError ->
                let
                    _ =
                        Debug.log "loadRemoteFileError" httpError
                in
                model ! []

            ClearSession ->
                update ports (RestoreSession File.defaultFile) model

            FileBrowserMsg fileBrowserMsg ->
                { model | fileBrowser = FileBrowser.update fileBrowserMsg model.fileBrowser } ! []

            UpdateTool tool ->
                { model | tool = tool } ! []

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
                    , tool = None
                    , cursorPosition = Nothing
                    , focusedPoint = Nothing
                    , selectedPoints = [ id ]
                }
                    ! []

            UpdatePoint id point ->
                { model
                    | store = Store.update id (\_ -> Just point) model.store
                    , tool = None
                }
                    ! []

            DeletePoint id ->
                { model
                    | store = Store.remove id model.store
                }
                    ! []

            NameUpdated s ->
                { model
                    | newName = parseVariable s
                }
                    ! []

            ValueUpdated s ->
                { model
                    | newValue = parse s
                }
                    ! []

            AddVariable ->
                case ( model.newName, model.newValue ) of
                    ( Just name, Just value ) ->
                        { model
                            | variables =
                                Dict.insert name value model.variables
                            , newName = Nothing
                            , newValue = Nothing
                        }
                            ! []

                    _ ->
                        model ! []

            Resize size ->
                { model
                    | viewPort =
                        { x = size.width // -2
                        , y = size.height // -2
                        , width = size.width
                        , height = size.height
                        }
                }
                    ! []

            DragStart position ->
                { model
                    | drag = Just (Drag position position)
                }
                    ! []

            DragAt position ->
                { model
                    | drag =
                        model.drag |> Maybe.map (\{ start } -> Drag start position)
                }
                    ! []

            DragStop position ->
                let
                    selectedPoints =
                        case model.drag of
                            Just drag ->
                                if drag.start == drag.current then
                                    []
                                else
                                    model.selectedPoints

                            Nothing ->
                                model.selectedPoints
                in
                { model
                    | drag = Nothing
                    , viewPort = getViewPort model.viewPort model.drag
                    , selectedPoints = selectedPoints
                }
                    ! []

            UpdateCursorPosition position ->
                { model
                    | cursorPosition =
                        position |> Maybe.map (svgToCanvas model.viewPort)
                }
                    ! []

            FocusPoint id ->
                { model | focusedPoint = id } ! []

            KeyMsg keyMsg ->
                { model
                    | pressedKeys =
                        Keyboard.update keyMsg model.pressedKeys
                }
                    ! []

            KeyDown key ->
                case key of
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
                                { model | pieceStore = pieceStore } ! []

                            Nothing ->
                                model ! []

                    Keyboard.CharA ->
                        { model | tool = Absolute Absolute.init } ! []

                    Keyboard.CharB ->
                        { model | tool = Between (Between.init (data model)) } ! []

                    Keyboard.CharE ->
                        { model
                            | tool =
                                if List.member Keyboard.Shift model.pressedKeys then
                                    Distance (Distance.init (data model))
                                else
                                    Relative (Relative.init (data model))
                        }
                            ! []

                    Keyboard.Escape ->
                        { model
                            | tool = None
                            , cursorPosition = Nothing
                        }
                            ! []

                    _ ->
                        model ! []

            SelectPoint maybeId ->
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
                                ! []
                        else
                            { model | selectedPoints = [ id ] } ! []

                    Nothing ->
                        model ! []

            ClearSelection ->
                { model | selectedPoints = [] } ! []

            ExtendPieceMsg pieceId id maybeNewId ->
                case maybeNewId of
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
                            , tool = None
                        }
                            ! []

                    Nothing ->
                        { model | tool = None } ! []


updateAutoFocus : Ports -> Model -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
updateAutoFocus ports oldModel ( model, cmd ) =
    ( model
    , if (oldModel.tool == None) && (model.tool /= None) then
        Cmd.batch [ ports.autofocus (), cmd ]
      else
        cmd
    )


updateStorage : Ports -> Model -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
updateStorage ports _ ( model, cmds ) =
    ( model, Cmd.batch [ ports.serialize (File.store model), cmds ] )


getViewPort : ViewPort -> Maybe Drag -> ViewPort
getViewPort oldViewPort drag =
    case drag of
        Nothing ->
            oldViewPort

        Just { start, current } ->
            { oldViewPort
                | x = oldViewPort.x - (current.x - start.x)
                , y = oldViewPort.y - (current.y - start.y)
            }


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.drag of
        Nothing ->
            Sub.batch
                [ Window.resizes Resize
                , Keyboard.subscriptions
                    |> Sub.map KeyMsg
                , Keyboard.downs KeyDown
                ]

        Just _ ->
            Sub.batch
                [ Window.resizes Resize
                , Mouse.moves DragAt
                , Mouse.ups DragStop
                , Keyboard.subscriptions
                    |> Sub.map KeyMsg
                ]
