module Tools.PointMenu
    exposing
        ( Msg
        , SelectablePoints
        , init
        , selectPoint
        , selectedPoint
        , update
        , view
        )

import Array exposing (Array)
import Array.Extra as Array
import Data.Point as Point exposing (Point)
import Data.Store as Store exposing (Id, Store)
import Html exposing (Html)
import Html.Attributes as Attributes
import Selectize
import Tools.Data exposing (Data)


---- MODEL


type alias WithSelectablePoints rest =
    { rest | points : SelectablePoints }


type alias SelectablePoints =
    Array SelectablePoint


type alias SelectablePoint =
    { selected : Maybe ( Id Point, Point )
    , menu : Selectize.State ( Id Point, Point )
    }


init : Int -> Data -> SelectablePoints
init count data =
    let
        menu num =
            data.store
                |> Store.toList
                |> List.map Selectize.entry
                |> Selectize.closed ("point--" ++ toString num)
                    (\( pointId, point ) -> pointEntry pointId point)

        selectablePoint num =
            { selected =
                case
                    data.selectedPoints
                        |> List.drop num
                        |> List.head
                of
                    Just pointId ->
                        case Store.get pointId data.store of
                            Just point ->
                                Just ( pointId, point )

                            Nothing ->
                                Nothing

                    Nothing ->
                        Nothing
            , menu =
                menu num
            }
    in
    List.range 0 (count - 1)
        |> List.map selectablePoint
        |> Array.fromList


selectedPoint : Int -> WithSelectablePoints rest -> Maybe ( Id Point, Point )
selectedPoint id { points } =
    points
        |> Array.get id
        |> Maybe.andThen .selected


pointMenu : Int -> WithSelectablePoints rest -> Maybe (Selectize.State ( Id Point, Point ))
pointMenu id { points } =
    points
        |> Array.get id
        |> Maybe.map .menu


selectPoint :
    Int
    -> Id Point
    -> { r | store : Store Point }
    -> WithSelectablePoints rest
    -> WithSelectablePoints rest
selectPoint id pointId { store } state =
    let
        updatePoint p point =
            { point | selected = Just ( pointId, p ) }
    in
    case Store.get pointId store of
        Just p ->
            { state
                | points =
                    Array.update id (updatePoint p) state.points
            }

        Nothing ->
            state



---- UPDATE


type Msg
    = SelectizeMsg Int (Selectize.Msg ( Id Point, Point ))


update :
    (Maybe (Id Point) -> topMsg)
    -> (Msg -> msg)
    -> Msg
    -> WithSelectablePoints rest
    -> ( WithSelectablePoints rest, Cmd msg, Maybe topMsg )
update selectPoint lift (SelectizeMsg id msg) state =
    case Array.get id state.points of
        Just { selected, menu } ->
            let
                ( newMenu, menuCmd, maybeMsg ) =
                    Selectize.update identity
                        selected
                        menu
                        msg

                cmd =
                    menuCmd
                        |> Cmd.map (SelectizeMsg id)
                        |> Cmd.map lift
            in
            case maybeMsg of
                Just maybePoint ->
                    ( { state
                        | points =
                            Array.set id
                                { selected = maybePoint, menu = newMenu }
                                state.points
                      }
                    , cmd
                    , maybePoint
                        |> Maybe.map Tuple.first
                        |> selectPoint
                        |> Just
                    )

                Nothing ->
                    ( { state
                        | points =
                            Array.set id
                                { selected = selected, menu = newMenu }
                                state.points
                      }
                    , cmd
                    , Nothing
                    )

        Nothing ->
            ( state
            , Cmd.none
            , Nothing
            )



---- VIEW


view :
    Int
    -> WithSelectablePoints rest
    -> Html Msg
view id state =
    case pointMenu id state of
        Just menu ->
            Html.div
                [ Attributes.class "tool__value-container" ]
                [ Selectize.view viewConfig
                    (selectedPoint id state)
                    menu
                    |> Html.map (SelectizeMsg id)
                ]

        Nothing ->
            Html.text ""



---- CONFIGURATIONS


viewConfig : Selectize.ViewConfig ( Id Point, Point )
viewConfig =
    Selectize.viewConfig
        { container = []
        , menu = [ Attributes.class "tool__menu-container" ]
        , ul = [ Attributes.class "tool__menu-list" ]
        , divider = \_ -> { attributes = [], children = [] }
        , entry =
            \( id, point ) mouseFocused keyboardFocused ->
                { attributes =
                    [ Attributes.class "tool__menu-item"
                    , Attributes.classList
                        [ ( "tool__menu-item--selected", keyboardFocused || mouseFocused ) ]
                    ]
                , children =
                    [ pointEntry id point |> Html.text ]
                }
        , input =
            Selectize.autocomplete
                { attrs =
                    \sthSelected open ->
                        [ Attributes.class "tool__menu-textfield" ]
                , toggleButton = Nothing
                , clearButton = Nothing
                , placeholder = "Select a point"
                }
        }



---- HELPERS


pointEntry : Id Point -> Point -> String
pointEntry id point =
    "#"
        ++ (id |> Store.toInt |> toString)
        ++ ": "
        ++ (point |> Point.name)
