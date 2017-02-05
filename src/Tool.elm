module Tool exposing (..)

-- external

import Dict exposing (..)
import Math.Vector2 exposing (..)


-- internal

import Point exposing (..)


-- possible steps


type Step
    = Position (Maybe Vec2)
    | SelectPoint (Maybe PointId)


stepInfoText : Step -> String
stepInfoText step =
    case step of
        Position data ->
            case data of
                Just v ->
                    "selected position is " ++ (toString v)

                Nothing ->
                    "click in the pattern to choose a position"

        SelectPoint data ->
            case data of
                Just id ->
                    "selected point is " ++ (toString id)

                Nothing ->
                    "select a point in the pattern"



-- all tools


type Tool
    = AddOriginTool
    | AddDDPointTool


allTools : List Tool
allTools =
    [ AddOriginTool, AddDDPointTool ]


toolInfoText : Tool -> String
toolInfoText tool =
    case tool of
        AddOriginTool ->
            "add origin"

        AddDDPointTool ->
            "add dd point"


type alias Agenda =
    List Step


agenda : Tool -> Agenda
agenda tool =
    case tool of
        AddOriginTool ->
            [ Position Nothing ]

        AddDDPointTool ->
            [ SelectPoint Nothing, Position Nothing ]


pointFrom : Dict PointId Point -> Agenda -> Tool -> Maybe Point
pointFrom points agenda tool =
    case tool of
        AddOriginTool ->
            pointFromOrigin agenda

        AddDDPointTool ->
            pointFromDDPoint points agenda


pointFromOrigin : Agenda -> Maybe Point
pointFromOrigin agenda =
    case agenda of
        (Position (Just v)) :: [] ->
            Just (Origin { position = v })

        _ ->
            Nothing


pointFromDDPoint : Dict PointId Point -> Agenda -> Maybe Point
pointFromDDPoint points agenda =
    case agenda of
        (SelectPoint (Just anchorId)) :: (Position (Just v)) :: [] ->
            Maybe.map
                (\anchorPosition ->
                    (DDPoint
                        { anchor = anchorId
                        , horizontalDistance =
                            (getX v) - (getX anchorPosition)
                        , verticalDistance =
                            (getY v) - (getY anchorPosition)
                        }
                    )
                )
            <|
                position points anchorId

        _ ->
            Nothing
