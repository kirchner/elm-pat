module Model exposing (..)

-- external

import Dict exposing (Dict)
import Math.Vector2 exposing (..)
import Window


-- internal

import Boundary exposing (..)
import Cut exposing (..)
import Point exposing (..)
import Tools exposing (..)
import ToolCombiner


-- MSG


type Msg
    = NoOp
    | UpdateWindowSize Window.Size
    | AddOrigin OriginInfo
    | FocusPoint PointId
    | UnFocusPoint PointId
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
    , focusedPointId : Maybe PointId
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
    , focusedPointId = Nothing
    , selectedPoints = []
    , selectedTool = Nothing
    }


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
                        nextTool =
                            stepPointTool toolMsg tool
                    in
                        case nextTool of
                            ToolCombiner.Tool _ ->
                                { model
                                    | selectedTool = Just (PointTool nextTool)
                                }
                                    ! []

                            ToolCombiner.Succeed point ->
                                { model
                                    | points = Dict.insert model.pointId point model.points
                                    , pointId = model.pointId + 1
                                    , selectedTool = Nothing
                                }
                                    ! []

                Just (CutTool tool) ->
                    let
                        nextTool =
                            stepCutTool toolMsg tool
                    in
                        case nextTool of
                            ToolCombiner.Tool _ ->
                                { model
                                    | selectedTool = Just (CutTool nextTool)
                                }
                                    ! []

                            ToolCombiner.Succeed cut ->
                                { model
                                    | cuts = Dict.insert model.cutId cut model.cuts
                                    , cutId = model.cutId + 1
                                    , selectedTool = Nothing
                                }
                                    ! []

                Just (BoundaryTool tool) ->
                    let
                        nextTool =
                            stepBoundaryTool toolMsg tool
                    in
                        case nextTool of
                            ToolCombiner.Tool _ ->
                                { model
                                    | selectedTool = Just (BoundaryTool nextTool)
                                }
                                    ! []

                            ToolCombiner.Succeed boundary ->
                                { model
                                    | boundaries = Dict.insert model.boundaryId boundary model.boundaries
                                    , boundaryId = model.boundaryId + 1
                                    , selectedTool = Nothing
                                }
                                    ! []

                Nothing ->
                    model ! []
