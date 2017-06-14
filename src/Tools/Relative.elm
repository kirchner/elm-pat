module Tools.Relative
    exposing
        ( State
        , init
        , initWith
        , svg
        , view
        )

import Autocomplete
import Css
import Dict exposing (Dict)
import Dropdown
import Events
import Expr exposing (..)
import Html exposing (Html, map)
import Html.Attributes as Html
import Html.Events as Html
import Json.Decode as Json
import Math.Vector2 exposing (..)
import Maybe.Extra as Maybe
import Styles.Colors exposing (..)
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg
import Svg.Extra as Svg
import Tools.Common as Tools
    exposing
        ( Callbacks
        , Data
        , exprInput
        , idDropdown
        , svgSelectPoint
        , svgUpdateMouse
        )
import Tools.Styles exposing (..)
import Types exposing (..)


type alias State =
    { anchor : Maybe String
    , x : Maybe E
    , y : Maybe E
    , id : Maybe Id

    -- autocomplete:
    -- we have to provide List Point from outside
    , autoState : Autocomplete.State
    , howManyToShow : Int
    , query : String
    , selectedPoint : Maybe ( Int, Point )
    , showMenu : Bool
    }


init : State
init =
    { anchor = Nothing
    , x = Nothing
    , y = Nothing
    , id = Nothing

    -- autocomplete:
    , autoState = Autocomplete.empty
    , howManyToShow = 5
    , query = ""
    , selectedPoint = Nothing
    , showMenu = False
    }



-- autocomplete


type AutoMsg
    = SetQuery String
    | SetAutoState Autocomplete.Msg
    | SelectPoint String
    | Reset
    | OnFocus
    | HandleEscape
    | NoOp


updateState : Data -> AutoMsg -> State -> State
updateState data autoMsg state =
    case autoMsg of
        SetQuery newQuery ->
            let
                showMenu =
                    not (List.isEmpty (filteredPoints newQuery data))
            in
            { state
                | query = newQuery
                , showMenu = showMenu
                , selectedPoint = Nothing
            }

        SetAutoState autoMsg ->
            let
                ( newAutoState, maybeMsg ) =
                    filteredPoints state.query data
                        |> Autocomplete.update
                            updateConfig
                            autoMsg
                            state.howManyToShow
                            state.autoState

                newState =
                    { state | autoState = newAutoState }
            in
            case maybeMsg of
                Nothing ->
                    newState

                Just updateMsg ->
                    updateState data updateMsg newState

        SelectPoint id ->
            let
                newState =
                    setQuery data state id
                        |> resetMenu
            in
            newState

        Reset ->
            { state
                | autoState =
                    Autocomplete.reset updateConfig state.autoState
                , selectedPoint = Nothing
            }

        OnFocus ->
            { state | showMenu = not state.showMenu }

        HandleEscape ->
            let
                validOptions =
                    not (List.isEmpty (filteredPoints state.query data))

                handleEscape =
                    if validOptions then
                        state
                            |> removeSelection
                            |> resetMenu
                    else
                        state
                            |> resetInput

                escapedState =
                    case state.selectedPoint of
                        Just ( id, point ) ->
                            if state.query == toString id then
                                state
                                    |> resetInput
                            else
                                handleEscape

                        Nothing ->
                            handleEscape
            in
            escapedState

        NoOp ->
            state


updateConfig : Autocomplete.UpdateConfig AutoMsg ( Int, Point )
updateConfig =
    Autocomplete.updateConfig
        { toId = Tuple.first >> toString
        , onKeyDown =
            \code maybeId ->
                if code == 38 || code == 40 then
                    --Maybe.map PreviewPerson maybeId
                    Maybe.map SelectPoint maybeId
                else if code == 13 then
                    --Maybe.map SelectPersonKeyboard maybeId
                    Maybe.map SelectPoint maybeId
                else
                    Just <| Reset
        , onTooLow = Nothing --Just <| Wrap False
        , onTooHigh = Nothing --Just <| Wrap True
        , onMouseEnter = \_ -> Nothing --\id -> Just <| PreviewPerson id
        , onMouseLeave = \_ -> Nothing
        , onMouseClick = \id -> Just <| SelectPoint id --SelectPersonMouse id
        , separateSelections = False
        }



-- view code


viewPointSelect : Data -> State -> Html AutoMsg
viewPointSelect data state =
    let
        options =
            { preventDefault = True, stopPropagation = False }

        dec =
            Json.map
                (\code ->
                    if code == 38 || code == 40 then
                        Ok NoOp
                    else if code == 27 then
                        Ok HandleEscape
                    else
                        Err "not handling that key"
                )
                Html.keyCode
                |> Json.andThen
                    fromResult

        fromResult : Result String a -> Json.Decoder a
        fromResult result =
            case result of
                Ok val ->
                    Json.succeed val

                Err reason ->
                    Json.fail reason

        query =
            case state.selectedPoint of
                Just ( id, point ) ->
                    toString id

                Nothing ->
                    state.query

        menu =
            if state.showMenu then
                [ viewMenu data state ]
            else
                []
    in
    Html.div
        [ Html.class "tool__ValueContainer"
        ]
        [ List.append
            [ Html.input
                [ Html.onInput SetQuery
                , Html.onFocus OnFocus
                , Html.onWithOptions "keydown" options dec
                , Html.value query
                , Html.placeholder "anchor point"
                , Html.autocomplete False
                , Html.style
                    [ ( "border-color", "transparent" )
                    , ( "font-family", "monospace" )
                    , ( "font-size", "1rem" )
                    , ( "line-height", "1rem" )
                    , ( "width", "10rem" )
                    , ( "background-color", "transparent" )
                    ]
                ]
                []
            ]
            menu
            |> Html.div []
        ]


viewMenu : Data -> State -> Html AutoMsg
viewMenu data state =
    Html.div
        [ Html.style
            [ ( "position", "relative" )
            , ( "width", "100%" )
            ]
        ]
        [ filteredPoints state.query data
            |> Autocomplete.view
                viewConfig
                state.howManyToShow
                state.autoState
            |> map SetAutoState
        ]


viewConfig : Autocomplete.ViewConfig ( Int, Point )
viewConfig =
    Autocomplete.viewConfig
        { toId = Tuple.first >> toString
        , ul =
            [ Html.style
                [ ( "position", "absolute" )
                , ( "width", "100%" )
                , ( "background-color", "#999" )
                , ( "list-style", "none" )
                , ( "padding", "0" )
                , ( "margin", "0" )
                ]
            ]
        , li =
            \_ _ ( id, point ) ->
                { attributes =
                    [ Html.style
                        []
                    ]
                , children =
                    [ Html.text ("point " ++ toString id) ]
                }
        }



-- helpers


setQuery : Data -> State -> String -> State
setQuery data state id =
    { state
        | query = id
        , selectedPoint =
            id
                |> String.toInt
                |> Result.toMaybe
                |> Maybe.andThen
                    (\id ->
                        Dict.get id data.store
                            |> Maybe.map (\point -> ( id, point ))
                    )
    }


resetInput : State -> State
resetInput state =
    { state | query = "" }
        |> removeSelection
        |> resetMenu


removeSelection : State -> State
removeSelection state =
    { state | selectedPoint = Nothing }


resetMenu : State -> State
resetMenu state =
    { state
        | autoState = Autocomplete.empty
        , showMenu = False
    }


filteredPoints : String -> Data -> List ( Int, Point )
filteredPoints query data =
    let
        lowerQuery =
            String.toLower query

        keepPoint ( id, point ) =
            toString id
                |> String.contains lowerQuery
    in
    data.store
        |> Dict.toList
        |> List.filter keepPoint



--


initWith : Id -> Id -> E -> E -> State
initWith id anchor x y =
    { init
        | anchor = Just (toString anchor)
        , x = Just x
        , y = Just y
        , id = Just id
    }


point : Data -> State -> Maybe Point
point data state =
    let
        anchorId =
            state.anchor
                |> Maybe.andThen (String.toInt >> Result.toMaybe)

        anchorPosition =
            anchorId
                |> Maybe.andThen (flip Dict.get data.store)
                |> Maybe.andThen (position data.store data.variables)

        xCursor =
            data.cursorPosition
                |> Maybe.map (\{ x, y } -> toFloat x)

        yCursor =
            data.cursorPosition
                |> Maybe.map (\{ x, y } -> toFloat y)

        xOffsetCursor =
            Maybe.map2 (\x anchor -> Number (x - getX anchor))
                xCursor
                anchorPosition

        yOffsetCursor =
            Maybe.map2 (\y anchor -> Number (y - getY anchor))
                yCursor
                anchorPosition

        xOffset =
            xOffsetCursor |> Maybe.or state.x

        yOffset =
            yOffsetCursor |> Maybe.or state.y
    in
    Maybe.map3 Relative anchorId xOffset yOffset



{- svg -}


svg : Callbacks msg -> (State -> msg) -> Data -> State -> Svg msg
svg callbacks updateState data state =
    case anchorPosition data state of
        Just anchorPosition ->
            let
                addPoint =
                    point data state |> Maybe.map callbacks.addPoint
            in
            [ newPoint data state
            , horizontalLine data state anchorPosition
            , verticalLine data state anchorPosition
            , Just (svgUpdateMouse addPoint callbacks.updateCursorPosition data)
            ]
                |> List.filterMap identity
                |> Svg.g []

        Nothing ->
            let
                selectPoint =
                    (\id -> { state | anchor = id |> Maybe.map toString })
                        >> updateState
            in
            [ svgSelectPoint callbacks.focusPoint selectPoint data ]
                |> Svg.g []


newPoint : Data -> State -> Maybe (Svg msg)
newPoint data state =
    let
        draw anchorPosition =
            pointPosition data state anchorPosition
                |> Maybe.map
                    (\pointPosition ->
                        Svg.g []
                            [ Svg.drawPoint pointPosition
                            , Svg.drawSelector pointPosition
                            , Svg.drawRectArrow anchorPosition pointPosition
                            ]
                    )
    in
    anchorPosition data state
        |> Maybe.andThen draw


horizontalLine : Data -> State -> Vec2 -> Maybe (Svg msg)
horizontalLine data state anchorPosition =
    state.y
        |> Maybe.andThen (compute data.variables)
        |> Maybe.map
            (\y -> Svg.drawHorizontalLine (y + getY anchorPosition))


verticalLine : Data -> State -> Vec2 -> Maybe (Svg msg)
verticalLine data state anchorPosition =
    state.x
        |> Maybe.andThen (compute data.variables)
        |> Maybe.map
            (\x -> Svg.drawVerticalLine (x + getX anchorPosition))



{- view -}


view : Callbacks msg -> (State -> msg) -> Data -> State -> Svg msg
view callbacks updateStateCallback data state =
    let
        updateAnchor =
            (\id -> { state | anchor = id }) >> updateStateCallback

        updateX =
            (\s -> { state | x = parse s }) >> updateStateCallback

        updateY =
            (\s -> { state | y = parse s }) >> updateStateCallback

        updateAutoState autoMsg =
            updateStateCallback (updateState data autoMsg state)
    in
    [ viewPointSelect data state
        |> map updateAutoState

    --idDropdown data state.anchor updateAnchor
    , exprInput "horizontal distance" state.x updateX
    , exprInput "vertical distance" state.y updateY
    ]
        |> Tools.view callbacks data state point



{- compute position -}


anchorPosition : Data -> State -> Maybe Vec2
anchorPosition data state =
    state.anchor
        |> Maybe.andThen (String.toInt >> Result.toMaybe)
        |> Maybe.andThen (flip Dict.get data.store)
        |> Maybe.andThen (position data.store data.variables)


pointPosition : Data -> State -> Vec2 -> Maybe Vec2
pointPosition data state anchorPosition =
    let
        x =
            state.x
                |> Maybe.andThen (compute data.variables)
                |> Maybe.map (\x -> x + getX anchorPosition)

        y =
            state.y
                |> Maybe.andThen (compute data.variables)
                |> Maybe.map (\y -> y + getY anchorPosition)
    in
    case data.cursorPosition of
        Just cursorPosition ->
            Just <|
                vec2
                    (x |> Maybe.withDefault (toFloat cursorPosition.x))
                    (y |> Maybe.withDefault (toFloat cursorPosition.y))

        Nothing ->
            Maybe.map2 vec2 x y
