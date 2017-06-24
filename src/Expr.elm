module Expr
    exposing
        ( E(..)
        , compute
        , parse
        , parseVariable
        , print
        , encode
        , decode
        )

import Char
import Dict exposing (Dict)
import Parser exposing (..)
import Parser.LanguageKit exposing (..)
import Set
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)


{-

   expr =
       term  |  term + expr  |  term - expr

   term =
       factor  |  factor * term  |  factor / factor

   factor =
       ( expr )  |  atom

   atom =
       number | symbol

-}


type E
    = Number Float
    | Symbol String
    | Sum E E
    | Difference E E
    | Product E E
    | Quotient E E



{- compute value -}


compute : Dict String E -> E -> Maybe Float
compute variables expr =
    let
        apply func e1 e2 =
            Maybe.map2 func
                (compute variables e1)
                (compute variables e2)
    in
    case expr of
        Number f ->
            Just f

        Symbol s ->
            Dict.get s variables
                |> Maybe.andThen (compute variables)

        Sum e1 e2 ->
            apply (\f1 f2 -> f1 + f2) e1 e2

        Difference e1 e2 ->
            apply (\f1 f2 -> f1 - f2) e1 e2

        Product e1 e2 ->
            apply (\f1 f2 -> f1 * f2) e1 e2

        Quotient e1 e2 ->
            apply (\f1 f2 -> f1 / f2) e1 e2



{- printing -}


print : E -> String
print expr =
    let
        apply operator e1 e2 =
            String.concat
                [ print e1
                , " "
                , operator
                , " "
                , print e2
                ]
    in
    case expr of
        Number f ->
            toString f

        Symbol s ->
            s

        Sum e1 e2 ->
            apply "+" e1 e2

        Difference e1 e2 ->
            apply "-" e1 e2

        Product e1 e2 ->
            apply "*" e1 e2

        Quotient e1 e2 ->
            apply "/" e1 e2



{- parser -}


parse : String -> Maybe E
parse s =
    run expr s |> Result.toMaybe


parseVariable : String -> Maybe String
parseVariable s =
    run
        (succeed identity
            |= variable Char.isLower isVarChar Set.empty
            |. end
        )
        s
        |> Result.toMaybe


expr : Parser E
expr =
    lazy (\_ -> term) |> andThen (\t -> exprHelp t)


exprHelp : E -> Parser E
exprHelp t =
    oneOf
        [ sum t |> andThen (\t -> exprHelp t)
        , difference t |> andThen (\t -> exprHelp t)
        , succeed t
        ]


sum : E -> Parser E
sum t =
    delayedCommit spaces <|
        succeed (Sum t)
            |. symbol "+"
            |. spaces
            |= term


difference : E -> Parser E
difference t =
    delayedCommit spaces <|
        succeed (Difference t)
            |. symbol "-"
            |. spaces
            |= term


term : Parser E
term =
    lazy (\_ -> factor) |> andThen (\f -> termHelp f)


termHelp : E -> Parser E
termHelp f =
    oneOf
        [ product f |> andThen (\f -> termHelp f)
        , quotient f
        , succeed f
        ]


product : E -> Parser E
product f =
    delayedCommit spaces <|
        succeed (Product f)
            |. symbol "*"
            |. spaces
            |= factor


quotient : E -> Parser E
quotient f =
    delayedCommit spaces <|
        succeed (Quotient f)
            |. symbol "/"
            |. spaces
            |= factor


factor : Parser E
factor =
    oneOf
        [ succeed identity
            |. symbol "("
            |= lazy (\_ -> expr)
            |. symbol ")"
        , atom
        ]


atom : Parser E
atom =
    oneOf
        [ succeed Number
            |= float
        , succeed (\float -> Number (-float))
            |. symbol "-"
            |= float
        , succeed Symbol
            |= variable Char.isLower isVarChar Set.empty
        ]


isVarChar : Char -> Bool
isVarChar char =
    Char.isLower char
        || Char.isUpper char
        || Char.isDigit char


spaces : Parser ()
spaces =
    ignore zeroOrMore (\c -> c == ' ')


-- SERIALIZATION


encode : E -> Value
encode expr =
    Encode.string (print expr)


decode : Decoder E
decode =
    Decode.string
    |> Decode.map (parse >> Maybe.withDefault (Number 0.0))
