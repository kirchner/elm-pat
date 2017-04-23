module Tests exposing (..)

import Dict
import Expect
import Fuzz exposing (..)
import Math.Vector2 exposing (..)
import Test exposing (..)


{- internal -}

import Types exposing (..)


all : Test
all =
    describe "Types"
        [ describe "position"
            [ absoluteTest
            , relativeTest
            ]
        ]



{- tests -}


absoluteTest : Test
absoluteTest =
    fuzz vec "absolute" <|
        \v ->
            let
                store =
                    Dict.singleton 0 point

                point =
                    absolute v
            in
                Expect.equal
                    (position store point)
                    (Just v)


relativeTest : Test
relativeTest =
    fuzz (tuple ( vec, vec )) "relative" <|
        \( v, w ) ->
            let
                store =
                    Dict.fromList
                        [ ( 0, absolutePoint )
                        , ( 1, relativePoint )
                        ]

                absolutePoint =
                    absolute v

                relativePoint =
                    relative 0 w
            in
                Expect.equal
                    (position store relativePoint)
                    (Just (add v w))



{- fuzzer -}


vec : Fuzzer Vec2
vec =
    map2 (\x y -> vec2 x y) float float
