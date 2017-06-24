module Point
    exposing
        ( Point(..)
        , Ratio
        , absolute
        , position
        , positionById
        , relative
        , encode
        , decode
        )

import Dict exposing (Dict)
import Expr exposing (E(..), compute)
import Math.Vector2 exposing (..)
import Store exposing (Id, Store)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)


{- point -}


type Point
    = Absolute E E
    | Relative (Id Point) E E
    | Distance (Id Point) E E
    | Between (Id Point) (Id Point) Ratio


type alias Ratio =
    Float


absolute : Vec2 -> Point
absolute v =
    Absolute (Number (getX v)) (Number (getY v))


relative : Id Point -> Vec2 -> Point
relative id v =
    Relative id (Number (getX v)) (Number (getY v))



{- helpers -}


positionById : Store Point -> Dict String E -> Id Point -> Maybe Vec2
positionById store variables id =
    Store.get id store
        |> Maybe.andThen (position store variables)


position : Store Point -> Dict String E -> Point -> Maybe Vec2
position store variables point =
    let
        lookUp id =
            Store.get id store
                |> Maybe.andThen (position store variables)
    in
    case point of
        Absolute x y ->
            Maybe.map2 vec2
                (compute variables x)
                (compute variables y)

        Relative id p q ->
            Maybe.map3 (\v p q -> v |> add (vec2 p q))
                (lookUp id)
                (compute variables p)
                (compute variables q)

        Distance id distance angle ->
            let
                coords anchorPosition distance angle =
                    vec2 (cos angle) (sin angle)
                        |> scale distance
                        |> add anchorPosition
            in
            Maybe.map3 coords
                (lookUp id)
                (compute variables distance)
                (compute variables angle)

        Between idA idB ratio ->
            Maybe.map2
                (\v w -> sub w v |> scale ratio |> add w)
                (lookUp idA)
                (lookUp idB)


-- SERIALIZATION


encode : Point -> Value
encode point =
    let
        def tag e0 e1 id id0 id1 ratio =
            Encode.object
            [ ("tag", Encode.string tag)
            , ("e0", Expr.encode e0)
            , ("e1", Expr.encode e1)
            , ("id", Store.encodeId id)
            , ("id0", Store.encodeId id0)
            , ("id1", Store.encodeId id1)
            , ("ratio", Encode.float ratio)
            ]
    in
    case point of
        Absolute e0 e1 ->
            def "absolute" e0 e1 (Store.idUnsafe 0) (Store.idUnsafe 0) (Store.idUnsafe 0) 0.0
        Relative id e0 e1 ->
            def "relative" e0 e1 id (Store.idUnsafe 0) (Store.idUnsafe 0) 0.0
        Distance id e0 e1 ->
            def "distance" e0 e1 id (Store.idUnsafe 0) (Store.idUnsafe 0) 0.0
        Between id0 id1 ratio ->
            def "between" (Expr.Number 0.0) (Expr.Number 0.0) (Store.idUnsafe 0) id0 id1 ratio


decode : Decoder Point
decode =
    Decode.at [ "tag" ] Decode.string
    |> Decode.andThen (\tag ->
           case tag of
               "absolute" ->
                   Decode.map2 Absolute
                       (Decode.at [ "e0" ] Expr.decode)
                       (Decode.at [ "e1" ] Expr.decode)
               "relative" ->
                   Decode.map3 Relative
                       (Decode.at [ "id" ] Store.decodeId)
                       (Decode.at [ "e0" ] Expr.decode)
                       (Decode.at [ "e1" ] Expr.decode)
               "distance" ->
                   Decode.map3 Distance
                       (Decode.at [ "id" ] Store.decodeId)
                       (Decode.at [ "e0" ] Expr.decode)
                       (Decode.at [ "e1" ] Expr.decode)
               "between" ->
                   Decode.map3 Between
                       (Decode.at [ "id0" ] Store.decodeId)
                       (Decode.at [ "id1" ] Store.decodeId)
                       (Decode.at [ "ratio" ] Decode.float)
               _ ->
                   Decode.fail "decodePoint: mailformed input"
       )
