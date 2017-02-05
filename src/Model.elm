module Model exposing (..)

-- external

import Dict exposing (Dict)
import Math.Vector2 exposing (..)
import Window


-- internal

import Point exposing (..)
import Tool exposing (..)


-- MSG


type Msg
    = NoOp
    | UpdateWindowSize Window.Size
    | AddOrigin OriginInfo
    | FocusPoint PointId
    | UnFocusPoint PointId
    | InitTool Tool
    | DoStep Step



-- MODEL


type alias Model =
    { windowSize : Window.Size
    , offset : Vec2
    , points : Dict PointId Point
    , pointId : PointId
    , focusedPointId : Maybe PointId
    , selectedTool : Maybe Tool
    , agenda : Agenda
    , result : Agenda
    }


defaultModel : Model
defaultModel =
    { windowSize =
        { width = 640
        , height = 400
        }
    , offset =
        vec2 -320 -200
        --, points = Dict.empty
        --, pointId = defaultId
    , points =
        Dict.fromList
            [ ( 0, Origin { position = vec2 40 40 } )
            ]
    , pointId = 1
    , focusedPointId = Nothing
    , selectedTool = Nothing
    , agenda = []
    , result = []
    }


finishTool : Model -> Model
finishTool model =
    let
        newPoint =
            model.selectedTool
                |> Maybe.andThen (pointFrom model.points model.result)
    in
        case newPoint of
            Just point ->
                { model
                    | points = Dict.insert model.pointId point model.points
                    , pointId = model.pointId + 1
                    , selectedTool = Nothing
                    , agenda = []
                    , result = []
                }

            Nothing ->
                model



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        UpdateWindowSize newSize ->
            { model
                | windowSize = newSize
            }
                ! []

        AddOrigin info ->
            { model
                | points = Dict.insert model.pointId (Origin info) model.points
                , pointId = nextId model.pointId
                , selectedTool = Nothing
            }
                ! []

        FocusPoint id ->
            { model
                | focusedPointId = Just id
            }
                ! []

        UnFocusPoint id ->
            if model.focusedPointId == (Just id) then
                { model
                    | focusedPointId = Nothing
                }
                    ! []
            else
                model ! []

        InitTool tool ->
            { model
                | selectedTool = Just tool
                , agenda = agenda tool
            }
                ! []

        DoStep step ->
            let
                newAgenda =
                    Maybe.withDefault [] <| List.tail model.agenda

                newResult =
                    model.result ++ [ step ]
            in
                finishTool
                    { model
                        | agenda = newAgenda
                        , result = newResult
                    }
                    ! []
