module Tools.Common
    exposing
        ( Callbacks
        , Data
        , DropdownState
        , exprInput
        , idDropdown
        , initDropdownState
        , svgSelectPoint
        , svgUpdateMouse
        , updateDropdownState
        , view
        , viewPointSelect
        , selectedPoint
        )

import Autocomplete
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
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg
import Svg.Extra as Svg
import Tools.Styles exposing (..)
import Types exposing (..)
import Views.Common exposing (iconSmall)


type alias Data =
    { store : PointStore
    , variables : Dict String E
    , viewPort : ViewPort
    , cursorPosition : Maybe Position
    , focusedPoint : Maybe Id
    }


type alias Callbacks msg =
    { addPoint : Point -> msg
    , updateCursorPosition : Maybe Position -> msg
    , focusPoint : Maybe Id -> msg
    }



{- svgs -}


svgUpdateMouse : Maybe msg -> (Maybe Position -> msg) -> Data -> Svg msg
svgUpdateMouse mouseClicked updateCursorPosition data =
    Svg.rect
        ([ Svg.x (toString data.viewPort.x)
         , Svg.y (toString data.viewPort.y)
         , Svg.width (toString data.viewPort.width)
         , Svg.height (toString data.viewPort.height)
         , Svg.fill "transparent"
         , Svg.strokeWidth "0"
         , Events.onMove (updateCursorPosition << Just)
         , Svg.onMouseOut (updateCursorPosition Nothing)
         ]
            ++ (mouseClicked
                    |> Maybe.map Svg.onClick
                    |> Maybe.toList
               )
        )
        []


svgSelectPoint : (Maybe Id -> msg) -> (Maybe Id -> msg) -> Data -> Svg msg
svgSelectPoint focusPoint selectPoint data =
    Dict.toList data.store
        |> List.filterMap (pointSelector_ focusPoint selectPoint data)
        |> Svg.g []


pointSelector_ :
    (Maybe Id -> msg)
    -> (Maybe Id -> msg)
    -> Data
    -> ( Id, Point )
    -> Maybe (Svg msg)
pointSelector_ focusPoint selectPoint data ( id, point ) =
    let
        draw v =
            Svg.g []
                [ Svg.circle
                    [ Svg.cx (toString (getX v))
                    , Svg.cy (toString (getY v))
                    , Svg.r "5"
                    , Svg.fill "transparent"
                    , Svg.strokeWidth "0"
                    , Svg.onClick (selectPoint (Just id))
                    , Svg.onMouseOver (focusPoint (Just id))
                    , Svg.onMouseOut (focusPoint Nothing)
                    ]
                    []
                , if id |> equals data.focusedPoint then
                    Svg.drawSelector v
                  else
                    Svg.g [] []
                ]
    in
    position data.store data.variables point
        |> Maybe.map draw


drawCursor : Vec2 -> Svg msg
drawCursor position =
    let
        ( x, y ) =
            toTuple position
    in
    Svg.g []
        [ Svg.drawPoint (vec2 x y)
        , Svg.drawSelector (vec2 x y)
        ]



{- views -}


view :
    Callbacks msg
    -> Data
    -> state
    -> (Data -> state -> Maybe Point)
    -> List (Html msg)
    -> Html msg
view callbacks data state point elements =
    let
        addPoint =
            point data state |> Maybe.map callbacks.addPoint

        button =
            case addPoint of
                Just callback ->
                    [ iconSmall "add" callback ]

                Nothing ->
                    []
    in
    Html.div
        [ class [ ToolBox ] ]
        elements


exprInput : String -> Maybe E -> (String -> msg) -> Html msg
exprInput name e callback =
    let
        deleteIcon =
            if e /= Nothing then
                [ Html.div
                    [ class [ IconContainer ] ]
                    [ iconSmall "delete" (callback "") ]
                ]
            else
                []
    in
    Html.div
        [ class [ ValueContainer ] ]
        ([ Html.input
            [ Html.onInput callback
            , Html.placeholder
                (e
                    |> Maybe.map print
                    |> Maybe.withDefault name
                )
            , class [ Textfield ]
            ]
            []
         ]
            ++ deleteIcon
        )



--


type alias DropdownState =
    { autoState : Autocomplete.State
    , howManyToShow : Int
    , query : String
    , showMenu : Bool
    , selectedPoint : Maybe ( Int, Point )
    }


selectedPoint : DropdownState -> Maybe ( Int, Point )
selectedPoint dropdownState =
    dropdownState.selectedPoint


initDropdownState : DropdownState
initDropdownState =
    { autoState = Autocomplete.empty
    , howManyToShow = 5
    , query = ""
    , showMenu = False
    , selectedPoint = Nothing
    }


setQuery : Data -> DropdownState -> String -> DropdownState
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


resetInput : DropdownState -> DropdownState
resetInput state =
    { state | query = "" }
        |> removeSelection
        |> resetMenu


removeSelection : DropdownState -> DropdownState
removeSelection state =
    { state | selectedPoint = Nothing }


resetMenu : DropdownState -> DropdownState
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


type DropdownMsg
    = SetQuery String
    | SetAutoState Autocomplete.Msg
    | SelectPoint String
    | Reset
    | OnFocus
    | HandleEscape
    | NoOp


updateDropdownState : Data -> DropdownMsg -> DropdownState -> DropdownState
updateDropdownState data autoMsg state =
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
                    updateDropdownState data updateMsg newState

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


updateConfig : Autocomplete.UpdateConfig DropdownMsg ( Int, Point )
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


viewPointSelect : Data -> DropdownState -> Html DropdownMsg
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


viewMenu : Data -> DropdownState -> Html DropdownMsg
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


idDropdown : Data -> Maybe String -> (Maybe String -> msg) -> Html msg
idDropdown data anchor updateAnchor =
    let
        items =
            Dict.keys data.store
                |> List.map toString
                |> List.map
                    (\id ->
                        { value = id
                        , text = "point " ++ id
                        , enabled = True
                        }
                    )
    in
    Html.div []
        [ Html.text "id:"
        , Dropdown.dropdown
            { items = items
            , emptyItem =
                Just
                    { value = "-1"
                    , text = "select point"
                    , enabled = True
                    }
            , onChange = updateAnchor
            }
            []
            anchor
        , Html.button
            [ Html.onClick (updateAnchor Nothing) ]
            [ Html.text "clear" ]
        ]
