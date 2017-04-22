module Editor
    exposing
        ( Model
        , canvasToSvg
        , svgToCanvas
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

import Callback exposing (..)
import Types exposing (..)
import Tools.AddAbsolute as AddAbsolute
import Tools.AddRelative as AddRelative


type alias Model =
    { mousePosition : Position
    , store : PointStore
    , nextId : Id
    , center : Position
    , addAbsolute : AddAbsolute.Model
    , addRelative : AddRelative.Model
    , selectedTool : Maybe Tool
    }


canvasToSvg : Model -> Position -> Position
canvasToSvg model p =
    { x = p.x - model.center.x
    , y = p.y - model.center.y
    }


svgToCanvas : Model -> Position -> Position
svgToCanvas model p =
    { x = p.x + model.center.x
    , y = p.y + model.center.y
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
    = UpdateMouse Position
    | SelectTool Tool
    | Handle (Maybe Callback)
    | AddAbsoluteMsg AddAbsolute.Msg
    | AddRelativeMsg AddRelative.Msg


init : ( Model, Cmd Msg )
init =
    { mousePosition = { x = 0, y = 0 } -- FIXME: get actual coordinates
    , store = emptyStore
    , nextId = firstId
    , center = { x = -320, y = -320 }
    , addAbsolute = AddAbsolute.init
    , addRelative = AddRelative.init
    , selectedTool = Nothing
    }
        ! []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateMouse p ->
            { model | mousePosition = p } ! []

        SelectTool tool ->
            { model | selectedTool = Just tool } ! []

        Handle callback ->
            (handle callback model) ! []

        AddAbsoluteMsg msg ->
            let
                ( newAddAbsolute, callback ) =
                    AddAbsolute.update msg model.addAbsolute
            in
                (handle callback { model | addAbsolute = newAddAbsolute }) ! []

        AddRelativeMsg msg ->
            { model | addRelative = AddRelative.update msg model.addRelative } ! []


handle : Maybe Callback -> Model -> Model
handle callback model =
    case callback of
        Just (AddPoint point) ->
            { model
                | store = Dict.insert model.nextId point model.store
                , nextId = model.nextId + 1
            }

        _ ->
            model


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
