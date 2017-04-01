module Tools
    exposing
        ( Tool
            ( PointTool
            , CutTool
            , BoundaryTool
            )
        , Msg
            ( InputPosition
            , SelectPoint
            , Finish
            )
        , origin
        , adPoint
        , ddPoint
        , cut
        , boundary
        )

-- external

import Dict exposing (Dict)
import Math.Vector2 exposing (..)


-- internal

import Agenda
    exposing
        ( Agenda
        , try
        , fail
        , succeed
        , tell
        , (>>=)
        , (>>>)
        , (|=)
        , zeroOrMore
        )
import Boundary exposing (Boundary)
import Cut exposing (Cut)
import Point
    exposing
        ( Point
        , unsafePosition
        , PointId
        )


type Tool
    = PointTool (Agenda State Msg Point)
    | CutTool (Agenda State Msg Cut)
    | BoundaryTool (Agenda State Msg Boundary)


type Msg
    = InputPosition Vec2
    | SelectPoint PointId
    | Finish


type State
    = Select (List PointId)



{- steps -}


inputPosition : Agenda s Msg Vec2
inputPosition =
    try <|
        \msg ->
            case msg of
                InputPosition v ->
                    succeed v

                _ ->
                    fail


selectPoint : Agenda s Msg PointId
selectPoint =
    try <|
        \msg ->
            case msg of
                SelectPoint id ->
                    succeed id

                _ ->
                    fail



{- point tools -}


origin : Agenda State Msg Point
origin =
    inputPosition
        >>= \p ->
                succeed (Point.origin p)


adPoint : Dict PointId Point -> Agenda State Msg Point
adPoint points =
    selectPoint
        >>= \id ->
                let
                    p =
                        unsafePosition points id
                in
                    tell (Select [ id ])
                        >>> inputPosition
                        >>= \q ->
                                succeed (Point.adPoint points id q)


ddPoint : Dict PointId Point -> Agenda State Msg Point
ddPoint points =
    selectPoint
        >>= \id ->
                let
                    p =
                        unsafePosition points id
                in
                    tell (Select [ id ])
                        >>> inputPosition
                        >>= \q ->
                                succeed (Point.ddPoint points id q)



{- cut tools -}


cut : Agenda State Msg Cut
cut =
    selectPoint
        >>= \id1 ->
                tell (Select [ id1 ])
                    >>> selectPoint
                    >>= \id2 ->
                            succeed (Cut.cut id1 id2)



{- boundary tools -}


boundary : Agenda s Msg Boundary
boundary =
    succeed Boundary.boundary
        |= selectPoint
        |= selectPoint
        |= (zeroOrMore Finish selectPoint)
