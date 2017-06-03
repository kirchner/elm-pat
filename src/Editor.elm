module Editor
    exposing
        ( Model
        , Msg(..)
        , Tool(..)
        , allTools
        , init
        , subscriptions
        , toolDescription
        , toolName
        , update
        , getViewPort
        )

{- internal -}

import Dict exposing (Dict)
import Expr
    exposing
        ( E
        , parse
        , parseVariable
        )
import Math.Vector2 exposing (..)
import Mouse
import Task
import Tools.Absolute as Absolute
import Tools.Relative as Relative
import Tools.Select as Select
import Tools.Distance as Distance
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
    }


type Tool
    = Absolute Absolute.State
    | Relative Relative.State
    | Distance Distance.State
    | Select Select.State
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

        Select _ ->
            "select"

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

        Select _ ->
            "select"

        None ->
            "none"


allTools : List Tool
allTools =
    [ Absolute Absolute.init
    , Relative Relative.init
    , Distance Distance.init
    , Select Select.init
    ]


type alias Drag =
    { start : Position
    , current : Position
    }


type Msg
    = UpdateTool Tool
    | AddPoint Point
    | SelectPoint Id
    | UpdatePoint Id Point
    | DeletePoint Id
    | ValueUpdated String
    | NameUpdated String
    | AddVariable
    | Resize Window.Size
    | DragStart Position
    | DragAt Position
    | DragStop Position


init : ( Model, Cmd Msg )
init =
    { store = emptyStore
    , nextId = firstId
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
                , tool = None
            }
                ! []

        SelectPoint id ->
            case Dict.get id model.store of
                Just (Types.Absolute x y) ->
                    { model
                        | tool = Absolute (Absolute.initWith id x y)
                    }
                        ! []

                Just (Types.Relative anchor p q) ->
                    { model
                        | tool = Relative (Relative.initWith id anchor p q)
                    }
                        ! []

                _ ->
                    { model | tool = None } ! []

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
            { model
                | drag = Nothing
                , viewPort = getViewPort model.viewPort model.drag
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
                [ Window.resizes Resize ]

        Just _ ->
            Sub.batch
                [ Window.resizes Resize
                , Mouse.moves DragAt
                , Mouse.ups DragStop
                ]
