module Tools.Relative
    exposing
        ( Config
        , State
        , init
        , initWith
        , svg
        , view
        )

{- internal -}

import Css
import Dict exposing (Dict)
import Dropdown
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


{- state -}


type alias State =
    WithMouse
        { anchor : Maybe String
        , x : Maybe E
        , y : Maybe E
        , focused : Maybe Id
        , id : Maybe Id
        }


init : State
init =
    { anchor = Nothing
    , x = Nothing
    , y = Nothing
    , focused = Nothing
    , id = Nothing
    , mouse = Nothing
    }


initWith : Id -> Id -> E -> E -> State
initWith id anchor x y =
    { init
        | anchor = Just (toString anchor)
        , x = Just x
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


svg : Config msg -> State -> PointStore -> Dict String E -> Svg msg
svg config state store variables =
    let
        anchorPosition =
            state.anchor
                |> Maybe.andThen (String.toInt >> Result.toMaybe)
                |> Maybe.andThen (flip Dict.get store)
                |> Maybe.andThen (position store variables)
    in
    case anchorPosition of
        Just v ->
            Svg.g []
                [ case state.mouse of
                    Just position ->
                        drawCursor variables config state v position

                    Nothing ->
                        Svg.g [] []
                , drawLines variables config state v
                , drawNewPoint variables config state v
                , eventRect config state store variables
                ]

        Nothing ->
            Svg.g []
                [ eventCircles config state store variables ]


drawCursor : Dict String E -> Config msg -> State -> Vec2 -> Position -> Svg msg
drawCursor variables config state v p =
    let
        draw x y =
            Svg.g []
                [ Svg.drawPoint (vec2 x y)
                , Svg.drawSelector (vec2 x y)
                , Svg.drawRectArrow v (vec2 x y)
                ]
    in
    case ( state.x, state.y ) of
        ( Just x, Just y ) ->
            Svg.g [] []

        _ ->
            draw
                (state.x
                    |> Maybe.andThen (compute variables)
                    |> Maybe.withDefault (toFloat p.x)
                )
                (state.y
                    |> Maybe.andThen (compute variables)
                    |> Maybe.withDefault (toFloat p.y)
                )


drawLines : Dict String E -> Config msg -> State -> Vec2 -> Svg msg
drawLines variables config state v =
    let
        verticalLine x =
            Svg.drawVerticalLine (x + getX v)

        horizontalLine y =
            Svg.drawHorizontalLine (y + getY v)
    in
    case ( state.x, state.y ) of
        ( Just x, Just y ) ->
            Svg.g [] []

        _ ->
            Svg.g [] <|
                List.filterMap identity
                    [ state.x
                        |> Maybe.andThen (compute variables)
                        |> Maybe.map verticalLine
                    , state.y
                        |> Maybe.andThen (compute variables)
                        |> Maybe.map horizontalLine
                    ]


drawNewPoint : Dict String E -> Config msg -> State -> Vec2 -> Svg msg
drawNewPoint variables config state v =
    let
        draw x y =
            Svg.g []
                [ Svg.drawPoint (vec2 x y)
                , Svg.drawSelector (vec2 x y)
                , Svg.drawRectArrow v (vec2 x y)
                ]
    in
    Maybe.map2 draw
        (state.x |> Maybe.andThen (compute variables))
        (state.y |> Maybe.andThen (compute variables))
        |> Maybe.withDefault (Svg.g [] [])


eventRect : Config msg -> State -> PointStore -> Dict String E -> Svg msg
eventRect config state store variables =
    case state.id of
        Just id ->
            case updatePoint config state store variables id of
                Just callback ->
                    Svg.rect
                        [ Svg.x (toString config.viewPort.x)
                        , Svg.y (toString config.viewPort.y)
                        , Svg.width (toString config.viewPort.width)
                        , Svg.height (toString config.viewPort.height)
                        , Svg.fill "transparent"
                        , Svg.strokeWidth "0"
                        , Events.onClick callback
                        , Events.onMove
                            (updateMouse config.stateUpdated state config.viewPort << Just)
                        , Svg.onMouseOut
                            (updateMouse config.stateUpdated state config.viewPort Nothing)
                        ]
                        []

                Nothing ->
                    Svg.g [] []

        Nothing ->
            case addPoint config state store variables of
                Just callback ->
                    Svg.rect
                        [ Svg.x (toString config.viewPort.x)
                        , Svg.y (toString config.viewPort.y)
                        , Svg.width (toString config.viewPort.width)
                        , Svg.height (toString config.viewPort.height)
                        , Svg.fill "transparent"
                        , Svg.strokeWidth "0"
                        , Events.onClick callback
                        , Events.onMove
                            (updateMouse config.stateUpdated state config.viewPort << Just)
                        , Svg.onMouseOut
                            (updateMouse config.stateUpdated state config.viewPort Nothing)
                        ]
                        []

                Nothing ->
                    Svg.g [] []


eventCircles :
    Config msg
    -> State
    -> PointStore
    -> Dict String E
    -> Svg msg
eventCircles config state store variables =
    Svg.g []
        (List.filterMap
            (eventCircle config state store variables)
            (Dict.toList store)
        )


eventCircle :
    Config msg
    -> State
    -> PointStore
    -> Dict String E
    -> ( Id, Point )
    -> Maybe (Svg msg)
eventCircle config state store variables ( id, point ) =
    let
        draw v =
            Svg.g []
                [ Svg.circle
                    [ Svg.cx (toString (getX v))
                    , Svg.cy (toString (getY v))
                    , Svg.r "5"
                    , Svg.fill "transparent"
                    , Svg.strokeWidth "0"
                    , Svg.onClick
                        (updateAnchor config.stateUpdated state (Just (toString id)))
                    , Svg.onMouseOver
                        (updateFocused config.stateUpdated state (Just id))
                    , Svg.onMouseOut
                        (updateFocused config.stateUpdated state Nothing)
                    ]
                    []
                , if id |> equals state.focused then
                    Svg.drawSelector v
                  else
                    Svg.g [] []
                ]
    in
    position store variables point
        |> Maybe.map draw


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
    in
    Html.div
        [ class [ ToolBox ] ]
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
                , onChange = updateAnchor config.stateUpdated state
                }
                []
                state.anchor
            , Html.button
                [ Html.onClick (updateAnchor config.stateUpdated state Nothing) ]
                [ Html.text "clear" ]
            ]
        , exprInput "x" state.x (updateX config.stateUpdated state)
        , exprInput "y" state.y (updateY config.stateUpdated state)
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
            case
                ( Maybe.andThen (Result.toMaybe << String.toInt) state.anchor
                , state.x
                , state.y
                )
            of
                ( Just id, Just x, Just y ) ->
                    let
                        point =
                            Relative id x y
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


addPoint :
    Config msg
    -> State
    -> PointStore
    -> Dict String E
    -> Maybe (Position -> msg)
addPoint config state store variables =
    let
        anchorId =
            state.anchor
                |> Maybe.andThen (String.toInt >> Result.toMaybe)

        anchorPosition =
            state.anchor
                |> Maybe.andThen (String.toInt >> Result.toMaybe)
                |> Maybe.andThen (flip Dict.get store)
                |> Maybe.andThen (position store variables)
    in
    case ( anchorId, anchorPosition ) of
        ( Just id, Just v ) ->
            Just <|
                \pos ->
                    let
                        p =
                            svgToCanvas config.viewPort pos

                        x =
                            state.x
                                |> Maybe.withDefault (Number (toFloat p.x - getX v))

                        y =
                            state.y
                                |> Maybe.withDefault (Number (toFloat p.y - getY v))
                    in
                    config.addPoint (Relative id x y)

        _ ->
            Nothing


updatePoint :
    Config msg
    -> State
    -> PointStore
    -> Dict String E
    -> Id
    -> Maybe (Position -> msg)
updatePoint config state store variables id =
    let
        anchorId =
            state.anchor
                |> Maybe.andThen (String.toInt >> Result.toMaybe)

        anchorPosition =
            state.anchor
                |> Maybe.andThen (String.toInt >> Result.toMaybe)
                |> Maybe.andThen (flip Dict.get store)
                |> Maybe.andThen (position store variables)
    in
    case ( anchorId, anchorPosition ) of
        ( Just anchor, Just v ) ->
            Just <|
                \pos ->
                    let
                        p =
                            svgToCanvas config.viewPort pos

                        x =
                            state.x
                                |> Maybe.withDefault (Number (toFloat p.x - getX v))

                        y =
                            state.y
                                |> Maybe.withDefault (Number (toFloat p.y - getY v))
                    in
                    config.updatePoint id (Relative anchor x y)

        _ ->
            Nothing


updateAnchor : (State -> msg) -> State -> Maybe String -> msg
updateAnchor callback state newAnchor =
    callback
        { state
            | anchor = newAnchor
            , focused = Nothing
        }


updateX : (State -> msg) -> State -> String -> msg
updateX callback state s =
    callback { state | x = parse s }


updateY : (State -> msg) -> State -> String -> msg
updateY callback state s =
    callback { state | y = parse s }


updateFocused : (State -> msg) -> State -> Maybe Id -> msg
updateFocused callback state newFocused =
    callback { state | focused = newFocused }