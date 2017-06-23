module Editor
    exposing
        ( Model
        , Msg(..)
        , Tool(..)
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
import Keyboard.Extra as Keyboard exposing (Key)
import Math.Vector2 exposing (..)
import Mouse
import Piece exposing (Piece)
import Set exposing (Set)
import Task
import Tools.Absolute as Absolute
import Tools.Common
    exposing
        ( Callbacks
        , Data
        )
import Tools.Distance as Distance
import Tools.ExtendPiece as ExtendPiece
import Tools.Relative as Relative
import Types exposing (..)
import Window


type alias Model =
    { store : PointStore
    , nextId : Id
    , pieceStore : Dict Int Piece
    , nextPieceId : Int
    , variables : Dict String E
    , newName : Maybe String
    , newValue : Maybe E
    , tool : Tool
    , viewPort : ViewPort
    , drag : Maybe Drag
    , cursorPosition : Maybe Position
    , focusedPoint : Maybe Id
    , pressedKeys : List Key
    , selectedPoints : List Id
    }


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


type Tool
    = Absolute Absolute.State
    | Relative Relative.State
    | Distance Distance.State
    | ExtendPiece ExtendPiece.State
    | None


toolName : Tool -> String
toolName tool =
    case tool of
        Absolute _ ->
            "absolute"

        Relative _ ->
            "relative"

        Distance _ ->
            "distance"

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

        ExtendPiece _ ->
            "extend piece"

        None ->
            "none"


allTools : Data -> List Tool
allTools data =
    [ Absolute Absolute.init
    , Relative (Relative.init data)
    , Distance (Distance.init data)
    ]


type alias Drag =
    { start : Position
    , current : Position
    }


type Msg
    = UpdateTool Tool
    | AddPoint Point
    | UpdatePoint Id Point
    | DeletePoint Id
    | ValueUpdated String
    | NameUpdated String
    | AddVariable
    | Resize Window.Size
    | DragStart Position
    | DragAt Position
    | DragStop Position
    | UpdateCursorPosition (Maybe Position)
    | FocusPoint (Maybe Id)
    | KeyMsg Keyboard.Msg
    | KeyDown Keyboard.Key
    | SelectPoint (Maybe Id)
    | ClearSelection
    | ExtendPieceMsg Int Id (Maybe Id)


init : ( Model, Cmd Msg )
init =
    { store = emptyStore
    , nextId = firstId
    , pieceStore = Dict.empty
    , nextPieceId = 0
    , variables = Dict.empty
    , newName = Nothing
    , newValue = Nothing
    , tool = None
    , viewPort =
        { x = -320
        , y = -320
        , width = 640
        , height = 640
        }
    , drag = Nothing
    , cursorPosition = Nothing
    , focusedPoint = Nothing
    , pressedKeys = []
    , selectedPoints = []
    }
        ! [ Task.perform Resize Window.size ]


type alias Ports =
    { autofocus : () -> Cmd Msg
    }


update : Ports -> Msg -> Model -> ( Model, Cmd Msg )
update ports msg model =
    updateAutoFocus ports model <|
    case msg of
        UpdateTool tool ->
            { model | tool = tool } ! []

        AddPoint point ->
            { model
                | store = Dict.insert model.nextId point model.store
                , nextId = model.nextId + 1
                , tool = None
                , cursorPosition = Nothing
                , focusedPoint = Nothing
                , selectedPoints = [ model.nextId ]
            }
                ! []

        UpdatePoint id point ->
            { model
                | store = Dict.update id (\_ -> Just point) model.store
                , tool = None
            }
                ! []

        DeletePoint id ->
            { model
                | store = Dict.remove id model.store
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
                                    Dict.insert model.nextPieceId piece model.pieceStore
                                )
                    of
                        Just pieceStore ->
                            { model
                                | pieceStore = pieceStore
                                , nextPieceId = model.nextPieceId + 1
                            }
                                ! []

                        Nothing ->
                            model ! []

                _ ->
                    { model
                        | tool =
                            case key of
                                Keyboard.CharA ->
                                    Absolute Absolute.init

                                Keyboard.CharE ->
                                    if List.member Keyboard.Shift model.pressedKeys then
                                        Distance (Distance.init (data model))
                                    else
                                        Relative (Relative.init (data model))

                                Keyboard.Escape ->
                                    None

                                _ ->
                                    model.tool
                    }
                        ! []

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
                            Dict.update pieceId updatePiece model.pieceStore
                        , tool = None
                    }
                        ! []

                Nothing ->
                    { model | tool = None } ! []


updateAutoFocus ports oldModel ( model, cmd ) =
    ( model ,
      if (oldModel.tool == None) && (model.tool /= None) then
          Cmd.batch [ ports.autofocus (), cmd ]
      else
          cmd
    )


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
