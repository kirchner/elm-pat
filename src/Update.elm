module Update exposing (update)

-- external

import Dict
import Material


-- internal

import Agenda
    exposing
        ( run
        , result
        , error
        )
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
                        nextTool =
                            run tool toolMsg
                    in
                        case result nextTool of
                            Just point ->
                                { model
                                    | points = Dict.insert model.pointId point model.points
                                    , pointId = model.pointId + 1
                                    , selectedTool = Nothing
                                }
                                    ! []

                            Nothing ->
                                if error nextTool then
                                    { model | selectedTool = Nothing } ! []
                                else
                                    { model | selectedTool = Just (PointTool nextTool) } ! []

                Just (CutTool tool) ->
                    let
                        nextTool =
                            run tool toolMsg
                    in
                        case result nextTool of
                            Just cut ->
                                { model
                                    | cuts = Dict.insert model.cutId cut model.cuts
                                    , cutId = model.cutId + 1
                                    , selectedTool = Nothing
                                }
                                    ! []

                            Nothing ->
                                if error nextTool then
                                    { model | selectedTool = Nothing } ! []
                                else
                                    { model | selectedTool = Just (CutTool nextTool) } ! []

                Just (BoundaryTool tool) ->
                    let
                        nextTool =
                            run tool toolMsg
                    in
                        case result nextTool of
                            Just boundary ->
                                { model
                                    | boundaries = Dict.insert model.boundaryId boundary model.boundaries
                                    , boundaryId = model.boundaryId + 1
                                    , selectedTool = Nothing
                                }
                                    ! []

                            Nothing ->
                                if error nextTool then
                                    { model | selectedTool = Nothing } ! []
                                else
                                    { model | selectedTool = Just (BoundaryTool nextTool) } ! []

                Nothing ->
                    model ! []
