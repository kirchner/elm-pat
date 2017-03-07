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
    , combo : Agenda Step String
    , successfullCombos : List String
    }


defaultModel =
    { currentTime = 0 * Time.millisecond
    , controlTime = Nothing
    , combo = allCombos
    , successfullCombos = []
    }


type Control
    = A
    | B
    | C
    | D


type Step
    = Action Control
    | CoolDown Time


action : Control -> Agenda Step ()
action control =
    let
        update action =
            case action of
                Action c ->
                    if (c == control) then
                        Just (succeed ())
                    else
                        Nothing

                _ ->
                    Nothing
    in
        try
            ("press " ++ (toString control))
            update


coolDown : Time -> Time -> Agenda Step ()
coolDown coolDownTime duration =
    let
        update action =
            case action of
                CoolDown time ->
                    if
                        (time >= coolDownTime)
                            && (time <= coolDownTime + duration)
                    then
                        Just (succeed ())
                    else
                        Nothing

                _ ->
                    Nothing
    in
        try
            ("wait "
                ++ (toString coolDownTime)
                ++ " milliseconds and press the next control within "
                ++ (toString duration)
                ++ " milliseconds"
            )
            update


combo1 : Agenda Step String
combo1 =
    succeed "combo1"
        |. action A
        |. coolDown 1000 2000
        |. action B
        |. coolDown 2000 1000
        |. action C


combo2 : Agenda Step String
combo2 =
    succeed "combo2"
        |. action B


allCombos : Agenda Step String
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
            let
                result =
                    case model.controlTime of
                        Nothing ->
                            run model.combo (Action control)

                        Just controlTime ->
                            let
                                timeDifference =
                                    model.currentTime - controlTime
                            in
                                runs model.combo
                                    [ (CoolDown timeDifference)
                                    , (Action control)
                                    ]
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
                            , successfullCombos =
                                string :: model.successfullCombos
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
                    "successfull combos: "
                        ++ (toString model.successfullCombos)
                ]
            ]
