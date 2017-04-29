module Editor
    exposing
        ( Model
        , Tool(..)
        , toolName
        , allTools
        , Msg(..)
        , init
        , update
        , subscriptions
        )

import Dict
import Math.Vector2 exposing (..)


{- internal -}

import Types exposing (..)
import Tools.Absolute as Absolute
import Tools.Relative as Relative
import Tools.Select as Select


type alias Model =
    { store : PointStore
    , nextId : Id
    , tool : Tool
    , viewPort : ViewPort
    }


type Tool
    = Absolute Absolute.State
    | Relative Relative.State
    | Select Select.State
    | None


toolName : Tool -> String
toolName tool =
    case tool of
        Absolute _ ->
            "absolute"

        Relative _ ->
            "relative"

        Select _ ->
            "select"

        None ->
            "none"


allTools : List Tool
allTools =
    [ Absolute Absolute.init
    , Relative Relative.init
    , Select Select.init
    ]


type Msg
    = UpdateTool Tool
    | AddPoint Point
    | SelectPoint Id
    | UpdatePoint Id Point


init : ( Model, Cmd Msg )
init =
    { store = emptyStore
    , nextId = firstId
    , tool = None
    , viewPort =
        { x = -320
        , y = -320
        , width = 640
        , height = 640
        }
    }
        ! []


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
                Just (Types.Absolute v) ->
                    { model | tool = Absolute (Absolute.initWith id v) } ! []

                Just (Types.Relative anchor w) ->
                    { model | tool = Relative (Relative.initWith id anchor w) } ! []

                _ ->
                    { model | tool = None } ! []

        UpdatePoint id point ->
            { model
                | store = Dict.update id (\_ -> Just point) model.store
                , tool = None
            }
                ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
