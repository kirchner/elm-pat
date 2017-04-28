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
import Tools.AddAbsolute as AddAbsolute
import Tools.AddRelative as AddRelative
import Tools.Select as Select


type alias Model =
    { store : PointStore
    , nextId : Id
    , tool : Tool
    , viewPort : ViewPort
    }


type Tool
    = AddAbsolute AddAbsolute.State
    | AddRelative AddRelative.State
    | Select Select.State
    | None


toolName : Tool -> String
toolName tool =
    case tool of
        AddAbsolute _ ->
            "absolute"

        AddRelative _ ->
            "relative"

        Select _ ->
            "select"

        None ->
            "none"


allTools : List Tool
allTools =
    [ AddAbsolute AddAbsolute.init
    , AddRelative AddRelative.init
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
                Just (Absolute v) ->
                    { model
                        | tool =
                            AddAbsolute (AddAbsolute.fromStore model.store id)
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


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
