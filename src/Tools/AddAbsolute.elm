module Tools.AddAbsolute
    exposing
        ( State
        , init
        , svg
        , view
        )

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
    { x : Maybe Int
    , y : Maybe Int
    , mouse : Maybe Position
    }


init : State
init =
    { x = Nothing
    , y = Nothing
    , mouse = Nothing
    }



{- config -}


type alias Config msg =
    { addPoint : Point -> msg
    , stateUpdated : State -> msg
    , viewPort : ViewPort
    }



{- canvas -}


svg : Config msg -> State -> Svg msg
svg config state =
    Svg.g []
        [ case state.mouse of
            Just p ->
                case ( state.x, state.y ) of
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
                case ( state.x, state.y ) of
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
        , eventRect config state
        ]


eventRect : Config msg -> State -> Svg msg
eventRect config state =
    Svg.rect
        [ Svg.x (toString config.viewPort.x)
        , Svg.y (toString config.viewPort.y)
        , Svg.width (toString config.viewPort.width)
        , Svg.height (toString config.viewPort.height)
        , Svg.fill "transparent"
        , Svg.strokeWidth "0"
        , Events.onClick (addPoint config state)
        , Events.onMove (updateMouse config.stateUpdated state config.viewPort << Just)
        , Svg.onMouseOut (updateMouse config.stateUpdated state config.viewPort Nothing)
        ]
        []



{- view -}


view : Config msg -> State -> Html msg
view config state =
    let
        buttonAttributes =
            case ( state.x, state.y ) of
                ( Just x, Just y ) ->
                    let
                        point =
                            absolute (vec2 (toFloat x) (toFloat y))
                    in
                        [ Html.onClick (config.addPoint point)
                        , Html.disabled False
                        ]

                _ ->
                    [ Html.disabled True ]
    in
        Html.div []
            [ Html.div []
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


addPoint : Config msg -> State -> Position -> msg
addPoint config state position =
    let
        p =
            svgToCanvas config.viewPort position
    in
        case ( state.x, state.y ) of
            ( Just x, Just y ) ->
                config.addPoint (absolute (vec2 (toFloat x) (toFloat y)))

            ( Just x, Nothing ) ->
                config.addPoint (absolute (vec2 (toFloat x) (toFloat p.y)))

            ( Nothing, Just y ) ->
                config.addPoint (absolute (vec2 (toFloat p.x) (toFloat y)))

            ( Nothing, Nothing ) ->
                config.addPoint (absolute (vec2 (toFloat p.x) (toFloat p.y)))


updateX : (State -> msg) -> State -> Maybe Int -> msg
updateX callback state newX =
    callback { state | x = newX }


updateY : (State -> msg) -> State -> Maybe Int -> msg
updateY callback state newY =
    callback { state | y = newY }


updateMouse : (State -> msg) -> State -> ViewPort -> Maybe Position -> msg
updateMouse callback state viewPort newMouse =
    callback { state | mouse = Maybe.map (svgToCanvas viewPort) newMouse }
