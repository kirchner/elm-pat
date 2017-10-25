module Data.ExprTest exposing (suite)

import Data.Expr as Expr exposing (E(..))
import Dict exposing (Dict)
import Expect
import Fuzz exposing (Fuzzer)
import Test exposing (..)


suite : Test
suite =
    concat
        [ describe "compute"
            [ fuzz Fuzz.float "a number" <|
                \num ->
                    Number num
                        |> Expr.compute Dict.empty
                        |> Expect.equal (Just num)
            , fuzz Fuzz.float "a symbol" <|
                \num ->
                    Symbol "my_symbol"
                        |> Expr.compute (Dict.singleton "my_symbol" (Number num))
                        |> Expect.equal (Just num)
            , fuzz2 Fuzz.float Fuzz.float "the sum of two numbers" <|
                \numA numB ->
                    Sum (Number numA) (Number numB)
                        |> Expr.compute Dict.empty
                        |> Expect.equal (Just (numA + numB))
            , fuzz2 Fuzz.float Fuzz.float "the difference of two numbers" <|
                \numA numB ->
                    Difference (Number numA) (Number numB)
                        |> Expr.compute Dict.empty
                        |> Expect.equal (Just (numA - numB))
            , fuzz2 Fuzz.float Fuzz.float "the product of two numbers" <|
                \numA numB ->
                    Product (Number numA) (Number numB)
                        |> Expr.compute Dict.empty
                        |> Expect.equal (Just (numA * numB))
            , fuzz2 Fuzz.float fuzzNonZeroFloat "the quotient of two numbers" <|
                \numA numB ->
                    Quotient (Number numA) (Number numB)
                        |> Expr.compute Dict.empty
                        |> Expect.equal (Just (numA / numB))
            ]
        , describe "parse"
            [ fuzz Fuzz.float "a number" <|
                \num ->
                    toString num
                        |> Expr.parse
                        |> Expect.equal (Just (Number num))
            , test "a symbol" <|
                \_ ->
                    "a_symbol"
                        |> Expr.parse
                        |> Expect.equal (Just (Symbol "a_symbol"))
            , fuzz2 Fuzz.float Fuzz.float "the sum of two numbers" <|
                \numA numB ->
                    [ toString numA
                    , " + "
                    , toString numB
                    ]
                        |> String.concat
                        |> Expr.parse
                        |> Expect.equal (Just (Sum (Number numA) (Number numB)))
            , fuzz2 Fuzz.float Fuzz.float "the difference of two numbers" <|
                \numA numB ->
                    [ toString numA
                    , " - "
                    , toString numB
                    ]
                        |> String.concat
                        |> Expr.parse
                        |> Expect.equal (Just (Difference (Number numA) (Number numB)))
            , fuzz2 Fuzz.float Fuzz.float "the product of two numbers" <|
                \numA numB ->
                    [ toString numA
                    , " * "
                    , toString numB
                    ]
                        |> String.concat
                        |> Expr.parse
                        |> Expect.equal (Just (Product (Number numA) (Number numB)))
            , fuzz2 Fuzz.float Fuzz.float "the quotient of two numbers" <|
                \numA numB ->
                    [ toString numA
                    , " / "
                    , toString numB
                    ]
                        |> String.concat
                        |> Expr.parse
                        |> Expect.equal (Just (Quotient (Number numA) (Number numB)))
            , fuzz Fuzz.float "a number inside parentheses" <|
                \num ->
                    [ "("
                    , toString num
                    , ")"
                    ]
                        |> String.concat
                        |> Expr.parse
                        |> Expect.equal (Just (Number num))
            , fuzz3 Fuzz.float Fuzz.float Fuzz.float "an expression with brackets" <|
                \numA numB numC ->
                    [ "("
                    , toString numA
                    , " + "
                    , toString numB
                    , ") * "
                    , toString numC
                    ]
                        |> String.concat
                        |> Expr.parse
                        |> Expect.equal
                            (Just
                                (Product
                                    (Sum (Number numA) (Number numB))
                                    (Number numC)
                                )
                            )
            ]
        ]



---- HELPER


fuzzNonZeroFloat : Fuzzer Float
fuzzNonZeroFloat =
    Fuzz.conditional
        { retries = 100
        , fallback = \num -> num + 1
        , condition = \num -> num /= 0
        }
        Fuzz.float
