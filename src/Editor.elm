module Editor
    exposing
        ( Model
        , Msg(..)
        , Tool(..)
        , allTools
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
import Keyboard.Extra exposing (Key)
import Math.Vector2 exposing (..)
import Mouse
import Set
import Task
import Tools.Absolute as Absolute
import Tools.Distance as Distance
import Tools.Relative as Relative
import Tools.Select as Select
import Types exposing (..)
import Window


type alias Model =
    { store : PointStore
    , nextId : Id
    , variables : Dict String E
    , newName : Maybe String
    , newValue : Maybe E
    , tool : Tool
    , viewPort : ViewPort
    , drag : Maybe Drag
    , cursorPosition : Maybe Position
    , focusedPoint : Maybe Id
    , pressedKeys : List Key
    }


type Tool
    = Absolute Absolute.State
    | Relative Relative.State
    | Distance Distance.State
    | Select Select.State


toolName : Tool -> String
toolName tool =
    case tool of
        Absolute _ ->
            "absolute"

        Relative _ ->
            "relative"

        Distance _ ->
            "distance"

        Select _ ->
            "select"


toolDescription : Tool -> String
toolDescription tool =
    case tool of
        Absolute _ ->
            "add a point given by absolute coordinates"

        Relative _ ->
            "relative"

        Distance _ ->
            "distance"

        Select _ ->
            "select"


allTools : List Tool
allTools =
    [ Absolute Absolute.init
    , Relative Relative.init
    , Distance Distance.init
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
    | KeyMsg Keyboard.Extra.Msg


init : ( Model, Cmd Msg )
init =
    { store = emptyStore
    , nextId = firstId
    , variables = Dict.empty
    , newName = Nothing
    , newValue = Nothing
    , tool = Select (Select.init Set.empty)
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
    }
        ! [ Task.perform Resize Window.size ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateTool tool ->
            { model | tool = tool } ! []

        AddPoint point ->
            { model
                | store = Dict.insert model.nextId point model.store
                , nextId = model.nextId + 1
                , tool = Select (Select.init Set.empty)
                , cursorPosition = Nothing
                , focusedPoint = Nothing
            }
                ! []

        UpdatePoint id point ->
            { model
                | store = Dict.update id (\_ -> Just point) model.store
                , tool = Select (Select.init Set.empty)
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
            { model
                | drag = Nothing
                , viewPort = getViewPort model.viewPort model.drag
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
                    Keyboard.Extra.update keyMsg model.pressedKeys
            }
                ! []


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
                , Keyboard.Extra.subscriptions
                    |> Sub.map KeyMsg
                ]

        Just _ ->
            Sub.batch
                [ Window.resizes Resize
                , Mouse.moves DragAt
                , Mouse.ups DragStop
                , Keyboard.Extra.subscriptions
                    |> Sub.map KeyMsg
                ]
