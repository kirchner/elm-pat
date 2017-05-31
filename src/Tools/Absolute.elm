module Tools.Absolute
    exposing
        ( Config
        , State
        , init
        , initWith
        , svg
        , view
        )

import Dict exposing (Dict)
import Events
import Expr exposing (..)
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
import Styles.Colors exposing (..)


{- TODO: rename these in Types -}


absolute =
    Types.absolute


position =
    Types.position



{- state -}


type alias State =
    WithMouse
        { x : Maybe E
        , y : Maybe E
        , id : Maybe Id
        }


init : State
init =
    { x = Nothing
    , y = Nothing
    , id = Nothing
    , mouse = Nothing
    }


initWith : Id -> E -> E -> State
initWith id x y =
    { init
        | x = Just x
        , y = Just y
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


svg : Dict String E -> Config msg -> State -> Svg msg
svg variables config state =
    Svg.g []
        [ case state.mouse of
            Just position ->
                drawCursor variables config state position

            Nothing ->
                Svg.g [] []
        , drawLines variables config state
        , drawNewPoint variables config state
        , eventRect variables config state
        ]


drawCursor : Dict String E -> Config msg -> State -> Position -> Svg msg
drawCursor variables config state p =
    let
        x =
            state.x
                |> Maybe.andThen (compute variables)
                |> Maybe.withDefault (toFloat p.x)

        y =
            state.y
                |> Maybe.andThen (compute variables)
                |> Maybe.withDefault (toFloat p.y)
    in
    case ( state.x, state.y ) of
        ( Just x, Just y ) ->
            Svg.g [] []

        _ ->
            Svg.g []
                [ Svg.drawPoint (vec2 x y)
                , Svg.drawSelector (vec2 x y)
                ]


drawLines : Dict String E -> Config msg -> State -> Svg msg
drawLines variables config state =
    case ( state.x, state.y ) of
        ( Just x, Just y ) ->
            Svg.g [] []

        _ ->
            Svg.g [] <|
                List.filterMap identity
                    [ state.x
                        |> Maybe.andThen (compute variables)
                        |> Maybe.map Svg.drawVerticalLine
                    , state.x
                        |> Maybe.andThen (compute variables)
                        |> Maybe.map Svg.drawVerticalLine
                    ]


drawNewPoint : Dict String E -> Config msg -> State -> Svg msg
drawNewPoint variables config state =
    let
        draw x y =
            Svg.g []
                [ Svg.drawPoint (vec2 x y)
                , Svg.drawSelector (vec2 x y)
                ]
    in
    Maybe.map2 draw
        (state.x |> Maybe.andThen (compute variables))
        (state.y |> Maybe.andThen (compute variables))
        |> Maybe.withDefault (Svg.g [] [])


eventRect : Dict String E -> Config msg -> State -> Svg msg
eventRect variables config state =
    Svg.rect
        [ Svg.x (toString config.viewPort.x)
        , Svg.y (toString config.viewPort.y)
        , Svg.width (toString config.viewPort.width)
        , Svg.height (toString config.viewPort.height)
        , Svg.fill "transparent"
        , Svg.strokeWidth "0"
        , case state.id of
            Just id ->
                Events.onClick (updatePoint variables config state id)

            Nothing ->
                Events.onClick (addPoint variables config state)
        , Events.onMove
            (updateMouse config.stateUpdated state config.viewPort << Just)
        , Svg.onMouseOut
            (updateMouse config.stateUpdated state config.viewPort Nothing)
        ]
        []



{- view -}


view : Dict String E -> Config msg -> State -> Html msg
view variables config state =
    Html.div
        [ class [ ToolBox ] ]
        [ exprInput "x" state.x (updateX config.stateUpdated state)
        , exprInput "y" state.y (updateY config.stateUpdated state)
        , case state.id of
            Just id ->
                action variables state "update" (config.updatePoint id)

            Nothing ->
                action variables state "add" config.addPoint
        ]


action : Dict String E -> State -> String -> (Point -> msg) -> Html msg
action variables state title callback =
    let
        attrs =
            Maybe.map2 Absolute state.x state.y
                |> Maybe.map
                    (\point ->
                        [ Html.onClick (callback point)
                        , Html.disabled False
                        ]
                    )
                |> Maybe.withDefault
                    [ Html.disabled True ]
    in
    Html.div
        ([ class [ Button ] ] ++ attrs)
        [ Html.text title ]



{- events -}


addPoint : Dict String E -> Config msg -> State -> Position -> msg
addPoint variables config state position =
    let
        x =
            state.x
                |> Maybe.withDefault
                    (svgToCanvas config.viewPort position
                        |> .x
                        |> toFloat
                        |> Number
                    )

        y =
            state.y
                |> Maybe.withDefault
                    (svgToCanvas config.viewPort position
                        |> .y
                        |> toFloat
                        |> Number
                    )
    in
    config.addPoint (Absolute x y)


updatePoint : Dict String E -> Config msg -> State -> Id -> Position -> msg
updatePoint variables config state id position =
    let
        x =
            state.x
                |> Maybe.withDefault
                    (svgToCanvas config.viewPort position
                        |> .x
                        |> toFloat
                        |> Number
                    )

        y =
            state.y
                |> Maybe.withDefault
                    (svgToCanvas config.viewPort position
                        |> .y
                        |> toFloat
                        |> Number
                    )
    in
    config.updatePoint id (Absolute x y)


updateX : (State -> msg) -> State -> String -> msg
updateX callback state s =
    callback { state | x = parse s }


updateY : (State -> msg) -> State -> String -> msg
updateY callback state s =
    callback { state | y = parse s }
