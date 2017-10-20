module Tools
    exposing
        ( Msg(..)
        , Tool(..)
        , all
        , description
        , initAbsolute
        , initBetween
        , initCircleIntersection
        , initDistance
        , initRelative
        , name
        , svg
        , update
        , view
        )

import Html exposing (Html)
import Svg exposing (Svg)
import Tools.Absolute as Absolute
import Tools.Between as Between
import Tools.Callbacks exposing (Callbacks)
import Tools.CircleIntersection as CircleIntersection
import Tools.Data exposing (Data)
import Tools.Distance as Distance
import Tools.ExtendPiece as ExtendPiece
import Tools.Relative as Relative


type Tool
    = Absolute Absolute.State
    | Between Between.State
    | CircleIntersection CircleIntersection.State
    | ExtendPiece ExtendPiece.State
    | Distance Distance.State
    | Relative Relative.State


name : Tool -> String
name tool =
    case tool of
        Absolute _ ->
            "absolute"

        Relative _ ->
            "relative"

        Distance _ ->
            "distance"

        Between _ ->
            "between"

        CircleIntersection _ ->
            "circle intersection"

        ExtendPiece _ ->
            "extend piece"


description : Tool -> String
description tool =
    case tool of
        Absolute _ ->
            "Add a point by providing absolute coordinates."

        Relative _ ->
            "Add a point relative to another point, providing distance and angle."

        Distance _ ->
            "Add a point relative to another point, providing x- and y-distance."

        Between _ ->
            "Add a point at a given ration between two other points."

        CircleIntersection _ ->
            "Add a point at the intersection of two circles."

        ExtendPiece _ ->
            "Extend a piece."


all : Data -> List Tool
all data =
    [ initAbsolute
    , initRelative data
    , initDistance data
    , initBetween data
    , initCircleIntersection data
    ]



---- INIT


initAbsolute : Tool
initAbsolute =
    Absolute.init |> Absolute


initRelative : Data -> Tool
initRelative data =
    Relative.init data |> Relative


initDistance : Data -> Tool
initDistance data =
    Distance.init data |> Distance


initBetween : Data -> Tool
initBetween data =
    Between.init data |> Between


initCircleIntersection : Data -> Tool
initCircleIntersection data =
    CircleIntersection.init data |> CircleIntersection



---- UPDATE


type Msg
    = AbsoluteMsg Absolute.Msg
    | BetweenMsg Between.Msg
    | CircleIntersectionMsg CircleIntersection.Msg
    | DistanceMsg Distance.Msg
    | RelativeMsg Relative.Msg


update : Callbacks msg -> Msg -> Tool -> ( Tool, Cmd Msg, Maybe msg )
update callbacks msg tool =
    case ( msg, tool ) of
        ( AbsoluteMsg msg, Absolute state ) ->
            ( Absolute (Absolute.update msg state)
            , Cmd.none
            , Nothing
            )

        ( BetweenMsg msg, Between state ) ->
            let
                ( newState, cmd, maybeMsg ) =
                    Between.update callbacks msg state
            in
            ( Between newState
            , cmd |> Cmd.map BetweenMsg
            , maybeMsg
            )

        ( CircleIntersectionMsg msg, CircleIntersection state ) ->
            let
                ( newState, cmd, maybeMsg ) =
                    CircleIntersection.update callbacks msg state
            in
            ( CircleIntersection newState
            , cmd |> Cmd.map CircleIntersectionMsg
            , maybeMsg
            )

        ( DistanceMsg msg, Distance state ) ->
            let
                ( newState, cmd, maybeMsg ) =
                    Distance.update callbacks msg state
            in
            ( Distance newState
            , cmd |> Cmd.map DistanceMsg
            , maybeMsg
            )

        ( RelativeMsg msg, Relative state ) ->
            let
                ( newState, cmd, maybeMsg ) =
                    Relative.update callbacks msg state
            in
            ( Relative newState
            , cmd |> Cmd.map RelativeMsg
            , maybeMsg
            )

        _ ->
            ( tool
            , Cmd.none
            , Nothing
            )



---- VIEW


view : Callbacks msg -> Data -> Tool -> Html Msg
view callbacks data tool =
    case tool of
        Absolute state ->
            Absolute.view callbacks data state
                |> Html.map AbsoluteMsg

        Relative state ->
            Relative.view callbacks data state
                |> Html.map RelativeMsg

        Distance state ->
            Distance.view callbacks data state
                |> Html.map DistanceMsg

        Between state ->
            Between.view callbacks data state
                |> Html.map BetweenMsg

        CircleIntersection state ->
            CircleIntersection.view callbacks data state
                |> Html.map CircleIntersectionMsg

        ExtendPiece _ ->
            Html.text ""



---- SVG


svg : Callbacks msg -> (Tool -> msg) -> Data -> Maybe Tool -> Svg msg
svg callbacks updateTool data tool =
    case tool of
        Just (Absolute state) ->
            Absolute.svg callbacks (updateTool << Absolute) data state

        Just (Relative state) ->
            Relative.svg callbacks (updateTool << Relative) data state

        Just (Distance state) ->
            Distance.svg callbacks (updateTool << Distance) data state

        Just (Between state) ->
            Between.svg callbacks (updateTool << Between) data state

        Just (CircleIntersection state) ->
            CircleIntersection.svg callbacks (updateTool << CircleIntersection) data state

        Just (ExtendPiece state) ->
            ExtendPiece.svg callbacks data state

        Nothing ->
            Svg.g [] []
