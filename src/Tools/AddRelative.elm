module Tools.AddRelative
    exposing
        ( State
        , svg
        , init
        , view
        )

import Dict
import Dropdown
import Html exposing (Html)
import Html.Attributes as Html
import Html.Events as Html
import Input.Number
import Math.Vector2 exposing (..)
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg


{- internal -}

import Events
import Svg.Extra as Svg
import Types exposing (..)


{- state -}


type alias State =
    { id : Maybe String
    , x : Maybe Int
    , y : Maybe Int
    , mouse : Maybe Position
    }


init : State
init =
    { id = Nothing
    , x = Nothing
    , y = Nothing
    , mouse = Nothing
    }



{- config -}


type alias Config msg =
    { addPoint : Point -> msg
    , stateUpdated : State -> msg
    , viewPort : ViewPort
    }


svg : Config msg -> State -> PointStore -> Svg msg
svg config state store =
    let
        anchorPosition =
            state.id
                |> Maybe.andThen (String.toInt >> Result.toMaybe)
                |> Maybe.andThen (flip Dict.get store)
                |> Maybe.andThen (position store)
    in
        Svg.g []
            [ case state.mouse of
                Just p ->
                    case ( anchorPosition, state.x, state.y ) of
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
                    case ( anchorPosition, state.x, state.y ) of
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
            , eventRect config state store
            ]


eventRect : Config msg -> State -> PointStore -> Svg msg
eventRect config state store =
    case addPoint config state store of
        Just callback ->
            Svg.rect
                [ Svg.x (toString config.viewPort.x)
                , Svg.y (toString config.viewPort.y)
                , Svg.width (toString config.viewPort.width)
                , Svg.height (toString config.viewPort.height)
                , Svg.fill "transparent"
                , Svg.strokeWidth "0"
                , Events.onClick callback
                , Events.onMove (updateMouse config.stateUpdated state config.viewPort << Just)
                , Svg.onMouseOut (updateMouse config.stateUpdated state config.viewPort Nothing)
                ]
                []

        Nothing ->
            Svg.g [] []


view : Config msg -> State -> PointStore -> Html msg
view config state store =
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
            case
                ( Maybe.andThen (Result.toMaybe << String.toInt) state.id
                , state.x
                , state.y
                )
            of
                ( Just id, Just x, Just y ) ->
                    let
                        point =
                            relative id (vec2 (toFloat x) (toFloat y))
                    in
                        [ Html.onClick (config.addPoint point)
                        , Html.disabled False
                        ]

                _ ->
                    [ Html.disabled True ]
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
                    , onChange = updateId config.stateUpdated state
                    }
                    []
                    state.id
                ]
            , Html.div []
                [ Html.text "x:"
                , Input.Number.input
                    (Input.Number.defaultOptions (updateX config.stateUpdated state))
                    []
                    state.x
                , Html.button
                    [ Html.onClick (updateX config.stateUpdated state Nothing) ]
                    [ Html.text "clear" ]
                ]
            , Html.div []
                [ Html.text "y:"
                , Input.Number.input
                    (Input.Number.defaultOptions (updateY config.stateUpdated state))
                    []
                    state.y
                , Html.button
                    [ Html.onClick (updateY config.stateUpdated state Nothing) ]
                    [ Html.text "clear" ]
                ]
            , Html.button
                buttonAttributes
                [ Html.text "add" ]
            ]



{- events -}


addPoint : Config msg -> State -> PointStore -> Maybe (Position -> msg)
addPoint config state store =
    let
        anchorId =
            state.id
                |> Maybe.andThen (String.toInt >> Result.toMaybe)

        anchorPosition =
            state.id
                |> Maybe.andThen (String.toInt >> Result.toMaybe)
                |> Maybe.andThen (flip Dict.get store)
                |> Maybe.andThen (position store)
    in
        case ( anchorId, anchorPosition ) of
            ( Just id, Just v ) ->
                Just <|
                    \pos ->
                        let
                            p =
                                svgToCanvas config.viewPort pos

                            x =
                                Maybe.map toFloat state.x
                                    |> Maybe.withDefault (toFloat p.x - getX v)

                            y =
                                Maybe.map toFloat state.y
                                    |> Maybe.withDefault (toFloat p.y - getY v)

                            w =
                                vec2 x y
                        in
                            config.addPoint (relative id w)

            _ ->
                Nothing


updateId : (State -> msg) -> State -> Maybe String -> msg
updateId callback state newId =
    callback { state | id = newId }


updateX : (State -> msg) -> State -> Maybe Int -> msg
updateX callback state newX =
    callback { state | x = newX }


updateY : (State -> msg) -> State -> Maybe Int -> msg
updateY callback state newY =
    callback { state | y = newY }


updateMouse : (State -> msg) -> State -> ViewPort -> Maybe Position -> msg
updateMouse callback state viewPort newMouse =
    callback { state | mouse = Maybe.map (svgToCanvas viewPort) newMouse }
