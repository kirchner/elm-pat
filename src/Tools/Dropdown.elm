module Tools.Dropdown
    exposing
        ( State
        , init
        , update
        , view
        )

import Autocomplete
import Point exposing (Point)
import Store exposing (Id, Store)
import Tools.Styles exposing (..)
import Html exposing (Html, map)
import Html.Attributes as Html
import Html.Events as Html
import Json.Decode as Json
import Tools.Common exposing (Data)


type alias State =
    { autoState : Autocomplete.State
    , howManyToShow : Int
    , query : String
    , showMenu : Bool
    }


init : State
init =
    { autoState = Autocomplete.empty
    , howManyToShow = 5
    , query = ""
    , showMenu = False
    }



{- update -}


type Msg
    = SetQuery String
    | SetAutoState Autocomplete.Msg
    | SelectPoint String
    | Reset
    | OnFocus
    | HandleEscape
    | NoOp


update :
    Maybe ( Id Point, Point )
    -> Data
    -> Msg
    -> State
    -> ( State, Maybe ( Id Point, Point ) )
update selectedPoint data msg state =
    case msg of
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
                    ( newState, selectedPoint )

                Just updateMsg ->
                    update selectedPoint data updateMsg newState

        Reset ->
            ( { state
                | autoState =
                    Autocomplete.reset updateConfig state.autoState
              }
            , Nothing
            )

        SelectPoint id ->
            let
                ( dirtyState, selection ) =
                    setQuery data state id
            in
            ( dirtyState |> resetMenu, selection )

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


setQuery : Data -> State -> String -> ( State, Maybe ( Id Point, Point ) )
setQuery data state idString =
    let
        maybeIdPoint =
            idString
                |> String.toInt
                |> Result.toMaybe
                |> Maybe.andThen
                    (\id ->
                        Store.get (Store.fromInt id) data.store
                            |> Maybe.map (\point -> ( Store.fromInt id, point ))
                    )

        query =
            maybeIdPoint
                |> Maybe.map (\( id, point ) -> pointEntry id point)
                |> Maybe.withDefault ""
    in
    ( { state | query = query }
    , idString
        |> String.toInt
        |> Result.toMaybe
        |> Maybe.andThen
            (\id ->
                Store.get (Store.fromInt id) data.store
                    |> Maybe.map (\point -> ( Store.fromInt id, point ))
            )
    )


resetInput : State -> ( State, Maybe ( Id Point, Point ) )
resetInput state =
    ( { state | query = "" }
        |> resetMenu
    , Nothing
    )


resetMenu : State -> State
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



{- view -}


view : Maybe ( Id Point, Point ) -> Data -> State -> Html Msg
view selectedPoint data state =
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
                    pointEntry id point

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


viewMenu : Data -> State -> Html Msg
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



{- configuration -}


viewConfig : Autocomplete.ViewConfig ( Id Point, Point )
viewConfig =
    Autocomplete.viewConfig
        { toId = toId
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


updateConfig : Autocomplete.UpdateConfig Msg ( Id Point, Point )
updateConfig =
    Autocomplete.updateConfig
        { toId = toId
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



{- helpers -}


toId : ( Id Point, Point ) -> String
toId ( id, _ ) =
    id |> Store.toInt |> toString


pointEntry : Id Point -> Point -> String
pointEntry id point =
    "#"
        ++ (id |> Store.toInt |> toString)
        ++ ": "
        ++ (point |> Point.name)
