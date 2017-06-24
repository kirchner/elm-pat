module Point
    exposing
        ( Id
        , Point(..)
        , Store
        , Ratio
        , absolute
        , emptyStore
        , firstId
        , position
        , positionById
        , relative
        )

import Dict exposing (Dict)
import Expr exposing (E(..), compute)
import Math.Vector2 exposing (..)


{- point -}


type Point
    = Absolute E E
    | Relative Id E E
    | Distance Id E E
    | Between Id Id Ratio


type alias Ratio =
    Float


absolute : Vec2 -> Point
absolute v =
    Absolute (Number (getX v)) (Number (getY v))


relative : Id -> Vec2 -> Point
relative id v =
    Relative id (Number (getX v)) (Number (getY v))



{- point store -}


type alias Store =
    Dict Id Point


type alias Id =
    Int


emptyStore : Store
emptyStore =
    Dict.empty


firstId : Id
firstId =
    0



{- helpers -}


positionById : Store -> Dict String E -> Id -> Maybe Vec2
positionById store variables id =
    Dict.get id store
        |> Maybe.andThen (position store variables)


position : Store -> Dict String E -> Point -> Maybe Vec2
position store variables point =
    let
        lookUp id =
            Dict.get id store
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
