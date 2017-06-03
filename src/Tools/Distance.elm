module Tools.Distance
    exposing
        ( Config
        , State
        , init
        , initWith
        , svg
        , view
        )

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
import Styles.Colors exposing (..)
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg
import Svg.Extra as Svg
import Tools.Common exposing (..)
import Tools.Styles exposing (..)
import Types exposing (..)


{- state -}


type alias State =
    WithMouse
        { anchor : Maybe String
        , distance : Maybe E
        , angle : Maybe E
        , focused : Maybe Id
        , id : Maybe Id
        }


init : State
init =
    { anchor = Nothing
    , distance = Nothing
    , angle = Nothing
    , focused = Nothing
    , id = Nothing
    , mouse = Nothing
    }


initWith : Id -> Id -> E -> E -> State
initWith id anchor distance angle =
    { init
        | anchor = Just (toString anchor)
        , distance = Just distance
        , angle = Just angle
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
    state.anchor
        |> Maybe.andThen (String.toInt >> Result.toMaybe)
        |> Maybe.andThen (flip Dict.get store)
        |> Maybe.andThen (position store variables)
        |> Maybe.map
            (\anchorPosition ->
                let
                    _ =
                        Debug.log "anchorPosition" anchorPosition

                    _ =
                        Debug.log "mouse" state.mouse
                in
                Svg.g []
                    [ case state.mouse of
                        Just position ->
                            drawCursor variables
                                config
                                state
                                anchorPosition
                                (Debug.log "position" position)

                        Nothing ->
                            Svg.g [] []
                    , eventRect config state store variables
                    ]
            )
        |> Maybe.withDefault
            (Svg.g []
                [ eventCircles config state store variables ]
            )


drawCursor : Dict String E -> Config msg -> State -> Vec2 -> Position -> Svg msg
drawCursor variables config state anchorPosition mousePosition =
    let
        draw x y =
            Svg.g []
                [ Svg.drawPoint (vec2 x y)
                , Svg.drawSelector (vec2 x y)
                , Svg.drawArrow anchorPosition (vec2 x y)
                ]
    in
    case ( state.distance, state.angle ) of
        ( Just distance, Just angle ) ->
            Svg.g [] []

        ( Nothing, Nothing ) ->
            draw (toFloat mousePosition.x) (toFloat mousePosition.y)

        _ ->
            draw
                (Nothing
                    |> Maybe.andThen (compute variables)
                    |> Maybe.map (\x -> x + getX anchorPosition)
                    |> Maybe.withDefault (toFloat mousePosition.x)
                )
                (Nothing
                    |> Maybe.andThen (compute variables)
                    |> Maybe.map (\y -> y + getY anchorPosition)
                    |> Maybe.withDefault (toFloat mousePosition.y)
                )


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



{- view -}


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
        , exprInput "d"
            state.distance
            (updateDistance config.stateUpdated state)
        , exprInput "a"
            state.angle
            (updateAngle config.stateUpdated state)
        , case state.id of
            Just id ->
                action state "update" (config.updatePoint id)

            Nothing ->
                action state "add" config.addPoint
        ]


action : State -> String -> (Point -> msg) -> Html msg
action state title callback =
    Html.div
        [ class [ Button ] ]
        [ Html.text title ]



{- events -}


addPoint :
    Config msg
    -> State
    -> PointStore
    -> Dict String E
    -> Maybe (Position -> msg)
addPoint config state store variables =
    Nothing


updatePoint :
    Config msg
    -> State
    -> PointStore
    -> Dict String E
    -> Id
    -> Maybe (Position -> msg)
updatePoint config state store variables id =
    Nothing


updateAnchor : (State -> msg) -> State -> Maybe String -> msg
updateAnchor callback state newAnchor =
    callback
        { state
            | anchor = newAnchor
            , focused = Nothing
        }


updateDistance : (State -> msg) -> State -> String -> msg
updateDistance callback state s =
    callback { state | distance = parse s }


updateAngle : (State -> msg) -> State -> String -> msg
updateAngle callback state s =
    callback { state | angle = parse s }


updateFocused : (State -> msg) -> State -> Maybe Id -> msg
updateFocused callback state newFocused =
    callback { state | focused = newFocused }
