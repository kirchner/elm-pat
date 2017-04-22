module Tools.AddRelative
    exposing
        ( Model
        , draw
        , Msg
        , init
        , update
        , view
        )

import Dict
import Html exposing (Html)
import Html.Events as Events
import Input.Number
import Svg exposing (Svg)


{- internal -}

import Svg.Extra as Svg
import Types exposing (..)


type alias Model =
    { id : Maybe Id
    , x : Maybe Int
    , y : Maybe Int
    }


init : Model
init =
    { id = Nothing
    , x = Nothing
    , y = Nothing
    }


draw : Model -> PointStore -> Position -> Svg msg
draw model store p =
    let
        anchorPosition =
            model.id
                |> Maybe.andThen (flip Dict.get store)
                |> Maybe.andThen (position store)
    in
        case ( anchorPosition, model.x, model.y ) of
            ( Just position, Nothing, Nothing ) ->
                Svg.g []
                    [ Svg.drawSelector position ]

            _ ->
                Svg.g [] []


type Msg
    = UpdateId Id
    | UpdateX (Maybe Int)
    | UpdateY (Maybe Int)


update : Msg -> Model -> Model
update msg model =
    case msg of
        UpdateId newId ->
            { model | id = Just newId }

        UpdateX newX ->
            { model | x = newX }

        UpdateY newY ->
            { model | y = newY }


view : Model -> PointStore -> Html Msg
view model store =
    let
        option (id, point) =
            Html.option
                [ Events.onClick (UpdateId id) ]
                [ Html.text (text point) ]

        text point =
            case position store point of
                Just v ->
                    "point at " ++ (toString v)

                Nothing ->
                    Debug.crash "invalid point"
    in
        Html.div []
            [ Html.div []
                [ Html.text "id:"
                , Html.select []
                    (Dict.toList store
                        |> List.map option
                    )
                ]
            , Html.div []
                [ Html.text "x:"
                , Input.Number.input
                    (Input.Number.defaultOptions UpdateX)
                    []
                    model.x
                ]
            , Html.div []
                [ Html.text "y:"
                , Input.Number.input
                    (Input.Number.defaultOptions UpdateY)
                    []
                    model.y
                ]
            , Html.button []
                [ Html.text "add" ]
            ]
