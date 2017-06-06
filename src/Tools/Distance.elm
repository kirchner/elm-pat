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



{- svg -}


type alias Variables =
    Dict String E


svg : Config msg -> State -> PointStore -> Variables -> Svg msg
svg config state store variables =
    case anchorPosition store variables state of
        Just anchorPosition ->
            [ pointPosition store variables state anchorPosition
                |> Maybe.map (drawPoint anchorPosition)
            , eventRect config state store variables
            ]
                |> List.filterMap identity
                |> Svg.g []

        Nothing ->
            [ selectAnchor config state store variables ]
                |> Svg.g []


drawPoint : Vec2 -> Vec2 -> Svg msg
drawPoint anchorPosition pointPosition =
    Svg.g []
        [ Svg.drawPoint pointPosition
        , Svg.drawSelector pointPosition
        , Svg.drawArrow anchorPosition pointPosition
        ]


eventRect : Config msg -> State -> PointStore -> Variables -> Maybe (Svg msg)
eventRect config state store variables =
    let
        callback =
            case state.id of
                Just id ->
                    updatePoint config state store variables id

                Nothing ->
                    addPoint config state store variables
    in
    callback
        |> Maybe.map (getPosition config.viewPort config.stateUpdated state)


selectAnchor : Config msg -> State -> PointStore -> Variables -> Svg msg
selectAnchor config state store variables =
    selectPoint config state store variables <|
        toString
            >> Just
            >> updateAnchor config.stateUpdated state



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
    let
        attrs =
            case
                ( Maybe.andThen (Result.toMaybe << String.toInt) state.anchor
                , state.distance
                , state.angle
                )
            of
                ( Just id, Just distance, Just angle ) ->
                    let
                        point =
                            Distance id distance angle
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



{- compute position -}


anchorPosition : PointStore -> Variables -> State -> Maybe Vec2
anchorPosition store variables state =
    state.anchor
        |> Maybe.andThen (String.toInt >> Result.toMaybe)
        |> Maybe.andThen (flip Dict.get store)
        |> Maybe.andThen (position store variables)


pointPosition : PointStore -> Variables -> State -> Vec2 -> Maybe Vec2
pointPosition store variables state anchorPosition =
    let
        position distance angle =
            vec2 (cos angle) (sin angle)
                |> scale distance
                |> add anchorPosition

        _ =
            Debug.log "mouse" state.mouse
    in
    case state.mouse |> Maybe.map (\{ x, y } -> vec2 (toFloat x) (toFloat y)) of
        Just mousePosition ->
            let
                delta =
                    sub mousePosition anchorPosition
            in
            Just <|
                position
                    (state.distance
                        |> Maybe.andThen (compute variables)
                        |> Maybe.withDefault (length delta)
                    )
                    (state.angle
                        |> Maybe.andThen (compute variables)
                        |> Maybe.withDefault (atan2 (getY delta) (getX delta))
                    )

        Nothing ->
            Maybe.map2 position
                (state.distance |> Maybe.andThen (compute variables))
                (state.angle |> Maybe.andThen (compute variables))



{- events -}


addPoint :
    Config msg
    -> State
    -> PointStore
    -> Variables
    -> Maybe (Position -> msg)
addPoint config state store variables =
    let
        anchorId =
            state.anchor
                |> Maybe.andThen (String.toInt >> Result.toMaybe)
    in
    case ( anchorId, anchorPosition store variables state ) of
        ( Just id, Just v ) ->
            Just <|
                \pos ->
                    config.addPoint (point config state id v pos)

        _ ->
            Nothing


updatePoint :
    Config msg
    -> State
    -> PointStore
    -> Variables
    -> Id
    -> Maybe (Position -> msg)
updatePoint config state store variables id =
    let
        anchorId =
            state.anchor
                |> Maybe.andThen (String.toInt >> Result.toMaybe)
    in
    case ( anchorId, anchorPosition store variables state ) of
        ( Just id, Just v ) ->
            Just <|
                \pos ->
                    config.updatePoint id (point config state id v pos)

        _ ->
            Nothing



{- create point -}


point : Config msg -> State -> Id -> Vec2 -> Position -> Point
point config state anchorId anchorPosition mousePosition =
    let
        p =
            svgToCanvas config.viewPort mousePosition

        delta =
            sub (vec2 (toFloat p.x) (toFloat p.y)) anchorPosition

        distance =
            state.distance
                |> Maybe.withDefault
                    (Number (length delta))

        angle =
            state.angle
                |> Maybe.withDefault
                    (Number (atan2 (getY delta) (getX delta)))
    in
    Distance anchorId distance angle


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
