module Tools.Relative
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


type alias State =
    WithMouse
        (WithFocused
            { anchor : Maybe String
            , x : Maybe E
            , y : Maybe E
            , id : Maybe Id
            }
        )


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


type alias Config msg =
    Tools.Common.Config State msg



{- svg -}


type alias Variables =
    Dict String E


svg : Config msg -> State -> PointStore -> Variables -> Svg msg
svg config state store variables =
    case anchorPosition store variables state of
        Just anchorPosition ->
            [ pointPosition store variables state anchorPosition
                |> Maybe.map (drawPoint anchorPosition)
            , drawLines state variables anchorPosition
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
        , Svg.drawRectArrow anchorPosition pointPosition
        ]


drawLines : State -> Variables -> Vec2 -> Maybe (Svg msg)
drawLines state variables anchorPosition =
    let
        verticalLine x =
            Svg.drawVerticalLine (x + getX anchorPosition)

        horizontalLine y =
            Svg.drawHorizontalLine (y + getY anchorPosition)
    in
    case ( state.x, state.y ) of
        ( Just x, Just y ) ->
            Nothing

        _ ->
            Just <|
                Svg.g [] <|
                    List.filterMap identity
                        [ state.x
                            |> Maybe.andThen (compute variables)
                            |> Maybe.map verticalLine
                        , state.y
                            |> Maybe.andThen (compute variables)
                            |> Maybe.map horizontalLine
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
        |> Maybe.map (getPosition config state)


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
    -> Variables
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
                    config.updatePoint id (point config state anchor v pos)

        _ ->
            Nothing



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
        x =
            state.x
                |> Maybe.andThen (compute variables)
                |> Maybe.map (\x -> x + getX anchorPosition)

        y =
            state.y
                |> Maybe.andThen (compute variables)
                |> Maybe.map (\y -> y + getY anchorPosition)
    in
    case state.mouse of
        Just mousePosition ->
            Just <|
                vec2
                    (x |> Maybe.withDefault (toFloat mousePosition.x))
                    (y |> Maybe.withDefault (toFloat mousePosition.y))

        Nothing ->
            Maybe.map2 vec2 x y



{- create point -}


point : Config msg -> State -> Id -> Vec2 -> Position -> Point
point config state anchorId anchorPosition mousePosition =
    let
        p =
            svgToCanvas config.viewPort mousePosition

        x =
            state.x
                |> Maybe.withDefault
                    (Number (toFloat p.x - getX anchorPosition))

        y =
            state.y
                |> Maybe.withDefault
                    (Number (toFloat p.y - getY anchorPosition))
    in
    Relative anchorId x y


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
