module Tools.Common
    exposing
        ( Callbacks
        , Data
        , DropdownState
        , exprInput
        , exprInput_
        , idDropdown
        , initDropdownState
        , svgSelectPoint
        , svgUpdateMouse
        , updateDropdownState
        , view
        , viewPointSelect
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
import Keyboard.Extra exposing (Key)
import Math.Vector2 exposing (..)
import Maybe.Extra as Maybe
import Piece exposing (..)
import Point exposing (Point)
import Set exposing (Set)
import Store exposing (Id, Store)
import Styles.Colors as Colors
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg
import Svg.Extra as Svg
import Tools.Styles exposing (..)
import Types exposing (..)
import Views.Common exposing (iconSmall)


type alias Data =
    { store : Store Point
    , pieceStore : Store Piece
    , variables : Dict String E
    , viewPort : ViewPort
    , cursorPosition : Maybe Position
    , focusedPoint : Maybe (Id Point)
    , pressedKeys : List Key
    , selectedPoints : List (Id Point)
    }


type alias Callbacks msg =
    { addPoint : Point -> msg
    , updateCursorPosition : Maybe Position -> msg
    , focusPoint : Maybe (Id Point) -> msg
    , selectPoint : Maybe (Id Point) -> msg
    , clearSelection : msg
    , extendPiece : Id Piece -> Id Point -> Maybe (Id Point) -> msg
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


svgSelectPoint :
    (Maybe (Id Point) -> msg)
    -> (Maybe (Id Point) -> msg)
    -> Data
    -> Svg msg
svgSelectPoint focusPoint selectPoint data =
    Store.toList data.store
        |> List.filterMap (pointSelector_ focusPoint selectPoint data)
        |> Svg.g []


pointSelector_ :
    (Maybe (Id Point) -> msg)
    -> (Maybe (Id Point) -> msg)
    -> Data
    -> ( Id Point, Point )
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
                    Svg.drawSelector Svg.Solid Colors.red v
                  else
                    Svg.g [] []
                ]
    in
    Point.position data.store data.variables point
        |> Maybe.map draw


drawCursor : Vec2 -> Svg msg
drawCursor position =
    let
        ( x, y ) =
            toTuple position
    in
    Svg.g []
        [ Svg.drawPoint Colors.base0 (vec2 x y)
        , Svg.drawSelector Svg.Solid Colors.base1 (vec2 x y)
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


exprInput_ : Bool -> String -> Maybe E -> (String -> msg) -> Html msg
exprInput_ autoFocus name e callback =
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
            , Html.autofocus autoFocus
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
    }


initDropdownState : DropdownState
initDropdownState =
    { autoState = Autocomplete.empty
    , howManyToShow = 5
    , query = ""
    , showMenu = False
    }


setQuery :
    Data
    -> DropdownState
    -> String
    -> ( DropdownState, Maybe ( Id Point, Point ) )
setQuery data state id =
    ( { state | query = id }
    , id
        |> String.toInt
        |> Result.toMaybe
        |> Maybe.andThen
            (\id ->
                Store.get (Store.fromInt id) data.store
                    |> Maybe.map (\point -> ( Store.fromInt id, point ))
            )
    )


resetInput : DropdownState -> ( DropdownState, Maybe ( Id Point, Point ) )
resetInput state =
    ( { state | query = "" }
        |> resetMenu
    , Nothing
    )


resetMenu : DropdownState -> DropdownState
resetMenu state =
    { state
        | autoState = Autocomplete.empty
        , showMenu = False
    }


filteredPoints : String -> Data -> List ( Id Point, Point )
filteredPoints query data =
    let
        lowerQuery =
            String.toLower query

        keepPoint ( id, point ) =
            pointEntry id point
                |> String.toLower
                |> String.contains lowerQuery
    in
    data.store
        |> Store.toList
        |> List.filter keepPoint


type DropdownMsg
    = SetQuery String
    | SetAutoState Autocomplete.Msg
    | SelectPoint String
    | Reset
    | OnFocus
    | HandleEscape
    | NoOp


updateDropdownState :
    Maybe ( Id Point, Point )
    -> Data
    -> DropdownMsg
    -> DropdownState
    -> ( DropdownState, Maybe ( Id Point, Point ) )
updateDropdownState selectedPoint data autoMsg state =
    case autoMsg of
        SetQuery newQuery ->
            let
                showMenu =
                    not (List.isEmpty (filteredPoints newQuery data))
            in
            ( { state
                | query = newQuery
                , showMenu = showMenu
              }
            , Nothing
            )

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
                    ( newState, Nothing )

                Just updateMsg ->
                    updateDropdownState selectedPoint data updateMsg newState

        SelectPoint id ->
            let
                ( dirtyState, selection ) =
                    setQuery data state id
            in
            ( dirtyState |> resetMenu, selection )

        Reset ->
            ( { state
                | autoState =
                    Autocomplete.reset updateConfig state.autoState
              }
            , Nothing
            )

        OnFocus ->
            ( { state | showMenu = not state.showMenu }, Nothing )

        HandleEscape ->
            let
                validOptions =
                    not (List.isEmpty (filteredPoints state.query data))

                handleEscape =
                    if validOptions then
                        ( state
                            |> resetMenu
                        , Nothing
                        )
                    else
                        state
                            |> resetInput

                escapedState =
                    case selectedPoint of
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
            ( state, selectedPoint )


updateConfig : Autocomplete.UpdateConfig DropdownMsg ( Id Point, Point )
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


viewPointSelect :
    Maybe ( Id Point, Point )
    -> Data
    -> DropdownState
    -> Html DropdownMsg
viewPointSelect selectedPoint data state =
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
            case selectedPoint of
                Just ( id, point ) ->
                    toString id

                Nothing ->
                    state.query

        menu =
            if
                state.showMenu
                    && not
                        (filteredPoints state.query data
                            |> List.isEmpty
                        )
            then
                viewMenu data state
            else
                Html.div [] []
    in
    Html.div
        [ Html.class "tool__ValueContainer"
        ]
        [ Html.input
            [ Html.onInput SetQuery
            , Html.onFocus OnFocus
            , Html.onWithOptions "keydown" options dec
            , Html.value query
            , Html.placeholder "anchor point"
            , Html.autocomplete False
            , class [ Textfield, MenuTextfield ]
            ]
            []
        , menu
        ]


viewMenu : Data -> DropdownState -> Html DropdownMsg
viewMenu data state =
    Html.div
        [ class [ MenuContainer ] ]
        [ filteredPoints state.query data
            |> Autocomplete.view
                viewConfig
                state.howManyToShow
                state.autoState
            |> map SetAutoState
        ]


pointEntry : Id Point -> Point -> String
pointEntry id point =
    "#"
        ++ (id |> Store.toInt |> toString)
        ++ ": "
        ++ (point |> Point.name)


viewConfig : Autocomplete.ViewConfig ( Id Point, Point )
viewConfig =
    Autocomplete.viewConfig
        { toId =
            \( id, point ) -> id |> toString
        , ul = [ class [ MenuList ] ]
        , li =
            \keySelected mouseSelected ( id, point ) ->
                { attributes =
                    [ class [ MenuItem ]
                    , classList
                        [ ( MenuItemSelected
                          , keySelected || mouseSelected
                          )
                        ]
                    ]
                , children = [ pointEntry id point |> Html.text ]
                }
        }


idDropdown : Data -> Maybe String -> (Maybe String -> msg) -> Html msg
idDropdown data anchor updateAnchor =
    let
        items =
            Store.intKeys data.store
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
