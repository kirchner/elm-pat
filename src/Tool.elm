module Tool exposing (..)

-- external

import Dict exposing (..)
import Math.Vector2 exposing (..)


-- internal

import Point exposing (..)


-- tool as a parser


type Tool msg result
    = Tool (msg -> Maybe (Step msg result))


type Step msg result
    = Cont (Tool msg result)
    | Done result


step : msg -> Tool msg result -> Result (Tool msg result) result
step msg (Tool tool) =
    case tool msg of
        Just (Done result) ->
            Ok result

        Just (Cont nextTool) ->
            Err nextTool

        Nothing ->
            Err (Tool tool)


succeed : result -> Tool msg result
succeed result =
    Tool (\_ -> Just (Done result))


map : (a -> b) -> Tool msg a -> Tool msg b
map func (Tool tool) =
    Tool <|
        \msg ->
            case tool msg of
                Just (Done result) ->
                    Just (Done (func result))

                Just (Cont nextTool) ->
                    Just (Cont (map func nextTool))

                Nothing ->
                    Nothing


map2 : (a -> b -> c) -> Tool msg a -> Tool msg b -> Tool msg c
map2 func (Tool toolA) (Tool toolB) =
    Tool <|
        \msg ->
            case toolA msg of
                Just (Done resultA) ->
                    Just (Cont (map (func resultA) (Tool toolB)))

                Just (Cont nextToolA) ->
                    Just (Cont (map2 func nextToolA (Tool toolB)))

                Nothing ->
                    Nothing


(|=) : Tool msg (a -> b) -> Tool msg a -> Tool msg b
(|=) toolFunc toolArg =
    map2 apply toolFunc toolArg


apply : (a -> b) -> a -> b
apply f a =
    f a



-- msg


type Msg
    = InputPosition Vec2
    | SelectPoint PointId



-- steps


positionStep : Tool Msg Vec2
positionStep =
    Tool <|
        \msg ->
            case msg of
                InputPosition v ->
                    Just (Done v)

                _ ->
                    Nothing


selectPointStep : Tool Msg PointId
selectPointStep =
    Tool <|
        \msg ->
            case msg of
                SelectPoint id ->
                    Just (Done id)

                _ ->
                    Nothing



-- origin tool


pointFromOriginTool : Tool Msg Point
pointFromOriginTool =
    succeed pointFromOrigin
        |= positionStep


pointFromOrigin : Vec2 -> Point
pointFromOrigin v =
    Origin { position = v }



-- dd point tool


pointFromDDPointTool : Dict PointId Point -> Tool Msg Point
pointFromDDPointTool points =
    succeed (pointFromDDPoint points)
        |= selectPointStep
        |= positionStep


pointFromDDPoint : Dict PointId Point -> PointId -> Vec2 -> Point
pointFromDDPoint points anchorId v =
    let
        anchorPosition =
            Maybe.withDefault (vec2 0 0) <|
                position points anchorId
    in
        DDPoint
            { anchor = anchorId
            , horizontalDistance =
                (getX v) - (getX anchorPosition)
            , verticalDistance =
                (getY v) - (getY anchorPosition)
            }



---- possible steps
--
--
--type Step
--    = Position (Maybe Vec2)
--    | SelectPoint (Maybe PointId)
--
--
--stepInfoText : Step -> String
--stepInfoText step =
--    case step of
--        Position data ->
--            case data of
--                Just v ->
--                    "selected position is " ++ (toString v)
--
--                Nothing ->
--                    "click in the pattern to choose a position"
--
--        SelectPoint data ->
--            case data of
--                Just id ->
--                    "selected point is " ++ (toString id)
--
--                Nothing ->
--                    "select a point in the pattern"
--
--
--
---- all tools
--
--
--type Tool
--    = AddOriginTool
--    | AddDDPointTool
--    | AddADPointTool
--
--
--allTools : List Tool
--allTools =
--    [ AddOriginTool, AddDDPointTool, AddADPointTool ]
--
--
--toolInfoText : Tool -> String
--toolInfoText tool =
--    case tool of
--        AddOriginTool ->
--            "add origin"
--
--        AddDDPointTool ->
--            "add dd point"
--
--        AddADPointTool ->
--            "add ad point"
--
--
--type alias Agenda =
--    List Step
--
--
--agenda : Tool -> Agenda
--agenda tool =
--    case tool of
--        AddOriginTool ->
--            [ Position Nothing ]
--
--        AddDDPointTool ->
--            [ SelectPoint Nothing, Position Nothing ]
--
--        AddADPointTool ->
--            [ SelectPoint Nothing, Position Nothing ]
--
--
--pointFrom : Dict PointId Point -> Agenda -> Tool -> Maybe Point
--pointFrom points agenda tool =
--    case tool of
--        AddOriginTool ->
--            pointFromOrigin agenda
--
--        AddDDPointTool ->
--            pointFromDDPoint points agenda
--
--        AddADPointTool ->
--            pointFromADPoint points agenda
--
--
--pointFromOrigin : Agenda -> Maybe Point
--pointFromOrigin agenda =
--    case agenda of
--        (Position (Just v)) :: [] ->
--            Just (Origin { position = v })
--
--        _ ->
--            Nothing
--
--
--pointFromDDPoint : Dict PointId Point -> Agenda -> Maybe Point
--pointFromDDPoint points agenda =
--    case agenda of
--        (SelectPoint (Just anchorId)) :: (Position (Just v)) :: [] ->
--            Maybe.map
--                (\anchorPosition ->
--                    (DDPoint
--                        { anchor = anchorId
--                        , horizontalDistance =
--                            (getX v) - (getX anchorPosition)
--                        , verticalDistance =
--                            (getY v) - (getY anchorPosition)
--                        }
--                    )
--                )
--            <|
--                position points anchorId
--
--        _ ->
--            Nothing
--
--
--pointFromADPoint : Dict PointId Point -> Agenda -> Maybe Point
--pointFromADPoint points agenda =
--    case agenda of
--        (SelectPoint (Just anchorId)) :: (Position (Just v)) :: [] ->
--            Maybe.map
--                (\anchorPosition ->
--                    (ADPoint
--                        { anchor = anchorId
--                        , angle =
--                            atan2
--                                (getY <| sub anchorPosition v)
--                                (getX <| sub anchorPosition v)
--                        , distance = length (sub anchorPosition v)
--                        }
--                    )
--                )
--            <|
--                position points anchorId
--
--        _ ->
--            Nothing
