module Update exposing (update)

-- external

import Dict
import Material


-- internal

import Agenda exposing (run)
import Model
    exposing
        ( Msg(..)
        , Model
        )
import Tools
    exposing
        ( Tool
            ( PointTool
            , CutTool
            , BoundaryTool
            )
        )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Mdl mdlMsg ->
            Material.update Mdl mdlMsg model

        UpdateWindowSize newSize ->
            { model
                | windowSize = newSize
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
