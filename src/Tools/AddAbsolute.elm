module Tools.AddAbsolute
    exposing
        ( Model
        , init
        , callback
        , draw
        , Msg(..)
        , update
        , view
        )

import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import Input.Number
import Math.Vector2 exposing (..)
import Svg exposing (Svg)


{- internal -}

import Callback exposing (..)
import Svg.Extra as Svg
import Types exposing (..)


{- model -}


type alias Model =
    { x : Maybe Int
    , y : Maybe Int
    }


init : Model
init =
    { x = Nothing
    , y = Nothing
    }



{- canvas -}


callback : Model -> Position -> Maybe Callback
callback model p =
    case ( model.x, model.y ) of
        ( Just x, Just y ) ->
            Just (AddPoint (absolute (vec2 (toFloat x) (toFloat y))))

        ( Just x, Nothing ) ->
            Just (AddPoint (absolute (vec2 (toFloat x) (toFloat p.y))))

        ( Nothing, Just y ) ->
            Just (AddPoint (absolute (vec2 (toFloat p.x) (toFloat y))))

        ( Nothing, Nothing ) ->
            Just (AddPoint (absolute (vec2 (toFloat p.x) (toFloat p.y))))


draw : Model -> Maybe Position -> Svg msg
draw model maybeP =
    case maybeP of
        Just p ->
            case ( model.x, model.y ) of
                ( Just x, Just y ) ->
                    Svg.g []
                        [ Svg.drawPoint (vec2 (toFloat x) (toFloat y))
                        , Svg.drawSelector (vec2 (toFloat x) (toFloat y))
                        ]

                ( Just x, Nothing ) ->
                    Svg.g []
                        [ Svg.drawVerticalLine (toFloat x)
                        , Svg.drawPoint (vec2 (toFloat x) (toFloat p.y))
                        , Svg.drawSelector (vec2 (toFloat x) (toFloat p.y))
                        ]

                ( Nothing, Just y ) ->
                    Svg.g []
                        [ Svg.drawHorizontalLine (toFloat y)
                        , Svg.drawPoint (vec2 (toFloat p.x) (toFloat y))
                        , Svg.drawSelector (vec2 (toFloat p.x) (toFloat y))
                        ]

                ( Nothing, Nothing ) ->
                    Svg.g []
                        [ Svg.drawPoint (vec2 (toFloat p.x) (toFloat p.y))
                        , Svg.drawSelector (vec2 (toFloat p.x) (toFloat p.y))
                        ]

        Nothing ->
            case ( model.x, model.y ) of
                ( Just x, Just y ) ->
                    Svg.g []
                        [ Svg.drawPoint (vec2 (toFloat x) (toFloat y))
                        , Svg.drawSelector (vec2 (toFloat x) (toFloat y))
                        ]

                ( Just x, Nothing ) ->
                    Svg.g []
                        [ Svg.drawVerticalLine (toFloat x) ]

                ( Nothing, Just y ) ->
                    Svg.g []
                        [ Svg.drawHorizontalLine (toFloat y) ]

                ( Nothing, Nothing ) ->
                    Svg.g [] []



{- msg -}


type Msg
    = UpdateX (Maybe Int)
    | UpdateY (Maybe Int)
    | Add Int Int



{- update -}


update : Msg -> Model -> ( Model, Maybe Callback )
update msg model =
    case msg of
        UpdateX newX ->
            ( { model | x = newX }, Nothing )

        UpdateY newY ->
            ( { model | y = newY }, Nothing )

        Add x y ->
            let
                point =
                    absolute (vec2 (toFloat x) (toFloat y))
            in
                ( model, Just (AddPoint point) )



{- view -}


view : Model -> Html Msg
view model =
    let
        buttonAttributes =
            case ( model.x, model.y ) of
                ( Just x, Just y ) ->
                    [ Events.onClick (Add x y)
                    , Attributes.disabled False
                    ]

                _ ->
                    [ Attributes.disabled True ]
    in
        Html.div []
            [ Html.div []
                [ Html.text "x:"
                , Input.Number.input
                    (Input.Number.defaultOptions UpdateX)
                    []
                    model.x
                , Html.button
                    [ Events.onClick (UpdateX Nothing) ]
                    [ Html.text "clear" ]
                ]
            , Html.div []
                [ Html.text "y:"
                , Input.Number.input
                    (Input.Number.defaultOptions UpdateY)
                    []
                    model.y
                , Html.button
                    [ Events.onClick (UpdateY Nothing) ]
                    [ Html.text "clear" ]
                ]
            , Html.button
                buttonAttributes
                [ Html.text "add" ]
            ]
