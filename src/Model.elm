module Model exposing (..)

-- external

import Dict exposing (Dict)
import Math.Vector2 exposing (..)
import Window


-- internal

import Agenda exposing (run)
import Boundary exposing (..)
import Cut exposing (..)
import Point exposing (..)
import Tools exposing (..)


-- MSG


type Msg
    = NoOp
    | UpdateWindowSize Window.Size
    | AddOrigin OriginInfo
    | SetFocus Focus
    | UnFocus
    | InitTool Tool
    | AbortTool
    | DoStep Tools.Msg



-- MODEL


type alias Model =
    { windowSize : Window.Size
    , offset : Vec2
    , points : Dict PointId Point
    , pointId : PointId
    , cuts : Dict CutId Cut
    , cutId : CutId
    , boundaries : Dict BoundaryId Boundary
    , boundaryId : BoundaryId
    , focus : Maybe Focus
    , selectedPoints : List PointId
    , selectedTool : Maybe Tool
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
    , cuts = Dict.empty
    , cutId = 0
    , boundaries = Dict.empty
    , boundaryId = 0
    , focus = Nothing
    , selectedPoints = []
    , selectedTool = Nothing
    }


type Focus
    = FPoint PointId
    | FCut CutId
    | FBoundary BoundaryId


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

        SetFocus focus ->
            { model
                | focus = Just focus
            }
                ! []

        UnFocus ->
            { model
                | focus = Nothing
            }
                ! []

        InitTool tool ->
            { model
                | selectedTool = Just tool
            }
                ! []

        AbortTool ->
            { model
                | selectedTool = Nothing
            }
                ! []

        DoStep toolMsg ->
            case model.selectedTool of
                Just (PointTool tool) ->
                    let
                        result =
                            run tool toolMsg
                    in
                        case result of
                            Err nextTool ->
                                { model
                                    | selectedTool = Just (PointTool nextTool)
                                }
                                    ! []

                            Ok point ->
                                { model
                                    | points = Dict.insert model.pointId point model.points
                                    , pointId = model.pointId + 1
                                    , selectedTool = Nothing
                                }
                                    ! []

                Just (CutTool tool) ->
                    let
                        result =
                            run tool toolMsg
                    in
                        case result of
                            Err nextTool ->
                                { model
                                    | selectedTool = Just (CutTool nextTool)
                                }
                                    ! []

                            Ok cut ->
                                { model
                                    | cuts = Dict.insert model.cutId cut model.cuts
                                    , cutId = model.cutId + 1
                                    , selectedTool = Nothing
                                }
                                    ! []

                Just (BoundaryTool tool) ->
                    let
                        result =
                            run tool toolMsg
                    in
                        case result of
                            Err nextTool ->
                                { model
                                    | selectedTool = Just (BoundaryTool nextTool)
                                }
                                    ! []

                            Ok boundary ->
                                { model
                                    | boundaries = Dict.insert model.boundaryId boundary model.boundaries
                                    , boundaryId = model.boundaryId + 1
                                    , selectedTool = Nothing
                                }
                                    ! []

                Nothing ->
                    model ! []
