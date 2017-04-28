module Editor
    exposing
        ( Model
        , Tool(..)
        , toolName
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


type alias Model =
    { store : PointStore
    , nextId : Id
    , addAbsolute : AddAbsolute.State
    , addRelative : AddRelative.State
    , selectedTool : Maybe Tool
    , viewPort : ViewPort
    }


type Tool
    = TAddAbsolute
    | TAddRelative


toolName : Tool -> String
toolName tool =
    case tool of
        TAddAbsolute ->
            "absolute"

        TAddRelative ->
            "relative"


type Msg
    = SelectTool Tool
    | AddPoint Point
    | UpdateAddAbsolute AddAbsolute.State
    | UpdateAddRelative AddRelative.State


init : ( Model, Cmd Msg )
init =
    { store = emptyStore
    , nextId = firstId
    , addAbsolute = AddAbsolute.init
    , addRelative = AddRelative.init
    , selectedTool = Nothing
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
        SelectTool tool ->
            { model | selectedTool = Just tool } ! []

        AddPoint point ->
            { model
                | store = Dict.insert model.nextId point model.store
                , nextId = model.nextId + 1
                , addAbsolute = AddAbsolute.init
                , addRelative = AddRelative.init
                , selectedTool = Nothing
            }
                ! []

        UpdateAddAbsolute state ->
            { model | addAbsolute = state } ! []

        UpdateAddRelative state ->
            { model | addRelative = state } ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
