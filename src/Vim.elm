module Vim exposing (..)

import Agenda exposing (..)


{-
   q

   wq

   a

   i
-}


type Action
    = NoOp
    | Quit
    | WriteQuit
    | WriteAll


everyTool : Agenda Char Action
everyTool =
    oneOf [ qTool, wqTool, wallTool ]



{- tools -}


qTool : Agenda Char Action
qTool =
    cmd <|
        tryChar 'q' Quit


wqTool : Agenda Char Action
wqTool =
    cmd <|
        succeed (\_ result -> result)
            |= tryChar 'w' NoOp
            |= tryChar 'q' WriteQuit


wallTool : Agenda Char Action
wallTool =
    cmd <|
        succeed (\_ _ _ result -> result)
            |= tryChar 'w' NoOp
            |= tryChar 'a' NoOp
            |= tryChar 'l' NoOp
            |= tryChar 'l' WriteAll



{- helpers -}


cmd : Agenda Char Action -> Agenda Char Action
cmd agenda =
    succeed (\_ result -> result)
        |= colon
        |= agenda


colon : Agenda Char Action
colon =
    tryChar ':' NoOp


tryChar : Char -> Action -> Agenda Char Action
tryChar char action =
    try (toString char)
        (\c ->
            if c == char then
                Just (succeed action)
            else
                Nothing
        )
