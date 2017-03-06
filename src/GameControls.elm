module GameControls exposing (main)

import Agenda exposing (..)
import AnimationFrame
import Html exposing (Html)
import Html.Events as Events
import Task
import Time exposing (Time)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }


init : ( Model, Cmd Msg )
init =
    ( defaultModel
    , Cmd.batch
        [ Task.perform Tick Time.now ]
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ AnimationFrame.times Tick
        ]



{- model -}


type alias Model =
    { currentTime : Time
    , controlTime : Maybe Time
    , combo : Agenda Action String
    , status : Maybe String
    }


defaultModel =
    { currentTime = 0 * Time.millisecond
    , controlTime = Nothing
    , combo = allCombos
    , status = Nothing
    }


type Control
    = A
    | B
    | C
    | D


type Action
    = Action Control Time


untimedAction : Control -> Agenda Action ()
untimedAction control =
    try ("press " ++ (toString control))
        (\(Action c _) ->
            if c == control then
                Just (succeed ())
            else
                Nothing
        )


timedAction : Control -> Time -> Time -> Agenda Action ()
timedAction control coolDownTime duration =
    try
        ("wait "
            ++ (toString coolDownTime)
            ++ " milliseconds, then press "
            ++ (toString control)
            ++ " within "
            ++ (toString duration)
            ++ " milliseconds"
        )
        (\(Action c time) ->
            if (c == control) && (time >= coolDownTime) && (time <= coolDownTime + duration) then
                Just (succeed ())
            else
                Nothing
        )


combo1 : Agenda Action String
combo1 =
    succeed "combo1"
        |. untimedAction A
        |. timedAction B 1000 2000
        |. timedAction C 2000 1000


combo2 : Agenda Action String
combo2 =
    succeed "combo2"
        |. untimedAction B


allCombos : Agenda Action String
allCombos =
    oneOf
        [ combo1
        , combo2
        ]



{- msg -}


type Msg
    = NoOp
    | Tick Time
    | Press Control



{- update -}


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        Tick currentTime ->
            { model | currentTime = currentTime } ! []

        Press control ->
            case model.controlTime of
                Nothing ->
                    let
                        result =
                            run model.combo (Action control 0)
                    in
                        case result of
                            Err nextCombo ->
                                { model
                                    | controlTime = Just model.currentTime
                                    , combo = nextCombo
                                }
                                    ! []

                            Ok (Just string) ->
                                { model
                                    | controlTime = Nothing
                                    , combo = allCombos
                                    , status = Just string
                                }
                                    ! []

                            Ok Nothing ->
                                { model
                                    | controlTime = Nothing
                                    , combo = allCombos
                                }
                                    ! []

                Just controlTime ->
                    let
                        timeDifference =
                            model.currentTime - controlTime

                        result =
                            run model.combo (Action control timeDifference)
                    in
                        case result of
                            Err nextCombo ->
                                { model
                                    | controlTime = Just model.currentTime
                                    , combo = nextCombo
                                }
                                    ! []

                            Ok (Just string) ->
                                { model
                                    | controlTime = Nothing
                                    , combo = allCombos
                                    , status = Just string
                                }
                                    ! []

                            Ok Nothing ->
                                { model
                                    | controlTime = Nothing
                                    , combo = allCombos
                                }
                                    ! []



{- view -}


view : Model -> Html Msg
view model =
    let
        controlButton control =
            Html.button
                [ Events.onClick <| Press control ]
                [ Html.text (toString control) ]
    in
        Html.div []
            [ Html.div [] <|
                List.map controlButton [ A, B, C, D ]
            , Html.p [] [ Html.text <| getDescription model.combo ]
            , Html.p []
                [ Html.text <|
                    "time difference = "
                        ++ (case model.controlTime of
                                Just time ->
                                    toString (model.currentTime - time)

                                Nothing ->
                                    "..."
                           )
                ]
            , Html.p []
                [ Html.text <|
                    "status: "
                        ++ Maybe.withDefault "..." model.status
                ]
            ]
