module Tools.Absolute
    exposing
        ( Config
        , State
        , init
        , initWith
        , svg
        , view
        )

import Dict
import Events
import Html exposing (Html)
import Html.Attributes as Html
import Html.Events as Html
import Input.Float
import Math.Vector2 exposing (..)
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg
import Svg.Extra as Svg
import Tools.Common exposing (..)
import Tools.Styles exposing (..)
import Types exposing (..)
import View.Colors exposing (..)


{- TODO: rename these in Types -}


absolute =
    Types.absolute


position =
    Types.position



{- state -}


type alias State =
    WithMouse
        { x : Maybe Float
        , y : Maybe Float
        , id : Maybe Id
        }


init : State
init =
    { x = Nothing
    , y = Nothing
    , id = Nothing
    , mouse = Nothing
    }


initWith : Id -> Vec2 -> State
initWith id v =
    { init
        | x = Just (getX v)
        , y = Just (getY v)
        , id = Just id
    }



{- config -}


type alias Config msg =
    { addPoint : Point -> msg
    , updatePoint : Id -> Point -> msg
    , stateUpdated : State -> msg
    , viewPort : ViewPort
    }



{- canvas -}


svg : Config msg -> State -> Svg msg
svg config state =
    Svg.g []
        [ case state.mouse of
            Just position ->
                drawCursor config state position

            Nothing ->
                Svg.g [] []
        , drawLines config state
        , drawNewPoint config state
        , eventRect config state
        ]


drawCursor : Config msg -> State -> Position -> Svg msg
drawCursor config state p =
    case ( state.x, state.y ) of
        ( Just x, Just y ) ->
            Svg.g [] []

        ( Just x, Nothing ) ->
            Svg.g []
                [ Svg.drawPoint (vec2 x (toFloat p.y))
                , Svg.drawSelector (vec2 x (toFloat p.y))
                ]

        ( Nothing, Just y ) ->
            Svg.g []
                [ Svg.drawPoint (vec2 (toFloat p.x) y)
                , Svg.drawSelector (vec2 (toFloat p.x) y)
                ]

        ( Nothing, Nothing ) ->
            Svg.g []
                [ Svg.drawPoint (vec p.x p.y)
                , Svg.drawSelector (vec p.x p.y)
                ]


drawLines : Config msg -> State -> Svg msg
drawLines config state =
    case ( state.x, state.y ) of
        ( Just x, Just y ) ->
            Svg.g [] []

        ( Just x, Nothing ) ->
            Svg.g []
                [ Svg.drawVerticalLine x ]

        ( Nothing, Just y ) ->
            Svg.g []
                [ Svg.drawHorizontalLine y ]

        ( Nothing, Nothing ) ->
            Svg.g [] []


drawNewPoint : Config msg -> State -> Svg msg
drawNewPoint config state =
    case ( state.x, state.y ) of
        ( Just x, Just y ) ->
            Svg.g []
                [ Svg.drawPoint (vec2 x y)
                , Svg.drawSelector (vec2 x y)
                ]

        _ ->
            Svg.g [] []


eventRect : Config msg -> State -> Svg msg
eventRect config state =
    Svg.rect
        [ Svg.x (toString config.viewPort.x)
        , Svg.y (toString config.viewPort.y)
        , Svg.width (toString config.viewPort.width)
        , Svg.height (toString config.viewPort.height)
        , Svg.fill "transparent"
        , Svg.strokeWidth "0"
        , case state.id of
            Just id ->
                Events.onClick (updatePoint config state id)

            Nothing ->
                Events.onClick (addPoint config state)
        , Events.onMove
            (updateMouse config.stateUpdated state config.viewPort << Just)
        , Svg.onMouseOut
            (updateMouse config.stateUpdated state config.viewPort Nothing)
        ]
        []



{- view -}


view : Config msg -> State -> Html msg
view config state =
    Html.div
        [ class [ ToolBox ] ]
        [ floatInput "x" state.x (updateX config.stateUpdated state)
        , floatInput "y" state.y (updateY config.stateUpdated state)
        , case state.id of
            Just id ->
                action state "update" (config.updatePoint id)

            Nothing ->
                action state "add" config.addPoint
        ]


action : State -> String -> (Point -> msg) -> Html msg
action state title callback =
    let
        attrs =
            case ( state.x, state.y ) of
                ( Just x, Just y ) ->
                    let
                        point =
                            absolute (vec2 x y)
                    in
                    [ Html.onClick (callback point)
                    , Html.disabled False
                    ]

                _ ->
                    [ Html.disabled True ]
    in
    Html.div
        ([ class [ Button ] ] ++ attrs)
        [ Html.text title ]



{- events -}


addPoint : Config msg -> State -> Position -> msg
addPoint config state position =
    point state.x state.y (svgToCanvas config.viewPort position)
        |> config.addPoint


updatePoint : Config msg -> State -> Id -> Position -> msg
updatePoint config state id position =
    point state.x state.y (svgToCanvas config.viewPort position)
        |> config.updatePoint id


point : Maybe Float -> Maybe Float -> Position -> Point
point maybeX maybeY p =
    case ( maybeX, maybeY ) of
        ( Just x, Just y ) ->
            absolute (vec2 x y)

        ( Just x, Nothing ) ->
            absolute (vec2 x (toFloat p.y))

        ( Nothing, Just y ) ->
            absolute (vec2 (toFloat p.x) y)

        ( Nothing, Nothing ) ->
            absolute (vec p.x p.y)


updateX : (State -> msg) -> State -> Maybe Float -> msg
updateX callback state newX =
    callback { state | x = newX }


updateY : (State -> msg) -> State -> Maybe Float -> msg
updateY callback state newY =
    callback { state | y = newY }
