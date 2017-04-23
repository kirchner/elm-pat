module Tools.AddRelative
    exposing
        ( Model
        , callback
        , draw
        , Msg
        , init
        , update
        , view
        )

import Dict
import Dropdown
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


type alias Model =
    { id : Maybe String
    , x : Maybe Int
    , y : Maybe Int
    }


init : Model
init =
    { id = Nothing
    , x = Nothing
    , y = Nothing
    }


callback : Model -> PointStore -> Position -> Maybe Callback
callback model store p =
    let
        anchorId =
            model.id
                |> Maybe.andThen (String.toInt >> Result.toMaybe)

        anchorPosition =
            model.id
                |> Maybe.andThen (String.toInt >> Result.toMaybe)
                |> Maybe.andThen (flip Dict.get store)
                |> Maybe.andThen (position store)
    in
        case ( anchorId, anchorPosition ) of
            ( Just id, Just v ) ->
                let
                    x =
                        Maybe.map toFloat model.x
                            |> Maybe.withDefault (toFloat p.x - getX v)

                    y =
                        Maybe.map toFloat model.y
                            |> Maybe.withDefault (toFloat p.y - getY v)

                    w =
                        vec2 x y
                in
                    Just (AddPoint (relative id w))

            _ ->
                Nothing


draw : Model -> PointStore -> Maybe Position -> Svg msg
draw model store maybeP =
    let
        anchorPosition =
            model.id
                |> Maybe.andThen (String.toInt >> Result.toMaybe)
                |> Maybe.andThen (flip Dict.get store)
                |> Maybe.andThen (position store)
    in
        case maybeP of
            Just p ->
                case ( anchorPosition, model.x, model.y ) of
                    ( Just v, Just x, Just y ) ->
                        let
                            w =
                                (vec2 (getX v + toFloat x) (getY v + toFloat y))
                        in
                            Svg.g []
                                [ Svg.drawSelector v
                                , Svg.drawPoint w
                                , Svg.drawSelector w
                                , Svg.drawArrow v w
                                ]

                    ( Just v, Nothing, Nothing ) ->
                        Svg.g []
                            [ Svg.drawSelector v
                            , Svg.drawPoint (toVec p)
                            , Svg.drawSelector (toVec p)
                            , Svg.drawArrow v (toVec p)
                            ]

                    ( Just v, Just x, Nothing ) ->
                        let
                            deltaX =
                                toFloat x + getX v

                            w =
                                (vec2 deltaX (toFloat p.y))
                        in
                            Svg.g []
                                [ Svg.drawSelector v
                                , Svg.drawPoint w
                                , Svg.drawSelector w
                                , Svg.drawArrow v w
                                , Svg.drawVerticalLine deltaX
                                ]

                    ( Just v, Nothing, Just y ) ->
                        let
                            deltaY =
                                toFloat y + getY v

                            w =
                                (vec2 (toFloat p.x) deltaY)
                        in
                            Svg.g []
                                [ Svg.drawSelector v
                                , Svg.drawPoint w
                                , Svg.drawSelector w
                                , Svg.drawArrow v w
                                , Svg.drawHorizontalLine deltaY
                                ]

                    ( Nothing, _, _ ) ->
                        Svg.g [] []

            Nothing ->
                case ( anchorPosition, model.x, model.y ) of
                    ( Just v, Just x, Just y ) ->
                        let
                            w =
                                (vec2 (getX v + toFloat x) (getY v + toFloat y))
                        in
                            Svg.g []
                                [ Svg.drawSelector v
                                , Svg.drawPoint w
                                , Svg.drawSelector w
                                , Svg.drawArrow v w
                                ]

                    ( Just v, Nothing, Nothing ) ->
                        Svg.g []
                            [ Svg.drawSelector v ]

                    ( Just v, Just x, Nothing ) ->
                        let
                            deltaX =
                                toFloat x + getX v
                        in
                            Svg.g []
                                [ Svg.drawSelector v
                                , Svg.drawVerticalLine deltaX
                                ]

                    ( Just v, Nothing, Just y ) ->
                        let
                            deltaY =
                                toFloat y + getY v
                        in
                            Svg.g []
                                [ Svg.drawSelector v
                                , Svg.drawHorizontalLine deltaY
                                ]

                    ( Nothing, _, _ ) ->
                        Svg.g [] []


type Msg
    = UpdateId (Maybe String)
    | UpdateX (Maybe Int)
    | UpdateY (Maybe Int)
    | Add Id Int Int


update : Msg -> Model -> ( Model, Maybe Callback )
update msg model =
    case msg of
        UpdateId newId ->
            ( { model | id = newId }, Nothing )

        UpdateX newX ->
            ( { model | x = newX }, Nothing )

        UpdateY newY ->
            ( { model | y = newY }, Nothing )

        Add id x y ->
            let
                point =
                    relative id (vec2 (toFloat x) (toFloat y))
            in
                ( model, Just (AddPoint point) )


view : Model -> PointStore -> Html Msg
view model store =
    let
        items =
            Dict.keys store
                |> List.map toString
                |> List.map
                    (\id ->
                        { value = id
                        , text = "point " ++ id
                        , enabled = True
                        }
                    )

        buttonAttributes =
            let
                maybeId =
                    model.id
                        |> Maybe.andThen (Result.toMaybe << String.toInt)
            in
                case ( maybeId, model.x, model.y ) of
                    ( Just id, Just x, Just y ) ->
                        [ Events.onClick (Add id x y)
                        , Attributes.disabled False
                        ]

                    _ ->
                        [ Attributes.disabled True ]
    in
        Html.div []
            [ Html.div []
                [ Html.text "id:"
                , Dropdown.dropdown
                    { items = items
                    , emptyItem =
                        Just
                            { value = "-1"
                            , text = "select point"
                            , enabled = True
                            }
                    , onChange = UpdateId
                    }
                    []
                    model.id
                ]
            , Html.div []
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
