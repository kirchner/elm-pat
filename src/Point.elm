module Point
    exposing
        ( Choice(..)
        , Handlers
        , Point
        , Ratio
        , absolute
        , between
        , circleIntersection
        , decode
        , dispatch
        , distance
        , encode
        , name
        , position
        , positionById
        , relative
        , setName
        )

import Dict exposing (Dict)
import Expr exposing (E(..), compute)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Math.Vector2 exposing (..)
import Store exposing (Id, Store)


{- point -}


type Point
    = Point
        { name : String
        , data : PointData
        }


type PointData
    = Absolute E E
    | Relative (Id Point) E E
    | Distance (Id Point) E E
    | Between (Id Point) (Id Point) Ratio
    | CircleIntersection (Id Point) E (Id Point) E Choice


type alias Ratio =
    Float


type Choice
    = LeftMost
    | RightMost


decodeChoice : Decoder Choice
decodeChoice =
    Decode.float
        |> Decode.andThen
            (\float ->
                if float == -1 then
                    Decode.succeed LeftMost
                else if float == 1 then
                    Decode.succeed RightMost
                else
                    Decode.fail "not a proper choice"
            )


name : Point -> String
name (Point point) =
    point.name


setName : String -> Point -> Point
setName name (Point point) =
    Point
        { point | name = name }



{- constructors -}


absolute : E -> E -> Point
absolute x y =
    Point
        { name = ""
        , data = Absolute x y
        }


relative : Id Point -> E -> E -> Point
relative id x y =
    Point
        { name = ""
        , data = Relative id x y
        }


distance : Id Point -> E -> E -> Point
distance id angle distance =
    Point
        { name = ""
        , data = Distance id angle distance
        }


between : Id Point -> Id Point -> Ratio -> Point
between first last ratio =
    Point
        { name = ""
        , data = Between first last ratio
        }


circleIntersection : Id Point -> E -> Id Point -> E -> Choice -> Point
circleIntersection first firstRadius last lastRadius choice =
    Point
        { name = ""
        , data = CircleIntersection first firstRadius last lastRadius choice
        }



{- dispatch -}


type alias Handlers a =
    { withAbsolute : Point -> E -> E -> a
    , withRelative : Point -> Id Point -> E -> E -> a
    , withDistance : Point -> Id Point -> E -> E -> a
    , withBetween : Point -> Id Point -> Id Point -> Ratio -> a
    , withCircleIntersection : Point -> Id Point -> E -> Id Point -> E -> Choice -> a
    }


dispatch : Handlers a -> Point -> a
dispatch handlers ((Point { name, data }) as point) =
    case data of
        Absolute x y ->
            handlers.withAbsolute point x y

        Relative id x y ->
            handlers.withRelative point id x y

        Distance id angle distance ->
            handlers.withDistance point id angle distance

        Between first last ratio ->
            handlers.withBetween point first last ratio

        CircleIntersection first firstRadius last lastRadius choice ->
            handlers.withCircleIntersection point first firstRadius last lastRadius choice



{- helpers -}


positionById : Store Point -> Dict String E -> Id Point -> Maybe Vec2
positionById store variables id =
    Store.get id store
        |> Maybe.andThen (position store variables)


position : Store Point -> Dict String E -> Point -> Maybe Vec2
position store variables (Point { name, data }) =
    let
        lookUp id =
            Store.get id store
                |> Maybe.andThen (position store variables)
    in
    case data of
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
                (\v w -> sub w v |> scale ratio |> add v)
                (lookUp idA)
                (lookUp idB)

        CircleIntersection idA rA idB rB choice ->
            let
                maybeDelta =
                    Maybe.map2
                        (\a b -> b |> flip sub a)
                        maybeA
                        (lookUp idB)

                maybeA =
                    lookUp idA
            in
            case
                ( maybeA
                , maybeDelta
                , compute variables rA
                , compute variables rB
                )
            of
                ( Just a, Just delta, Just rA, Just rB ) ->
                    let
                        distSquared =
                            delta |> lengthSquared

                        dist =
                            delta |> length

                        z =
                            (rB ^ 2 - rA ^ 2 - distSquared)
                                / (-2 * dist)

                        h =
                            factor * sqrt (rA ^ 2 - z)

                        factor =
                            case choice of
                                LeftMost ->
                                    -1

                                RightMost ->
                                    1

                        deltaPerp =
                            vec2 (getY delta) (-1 * getX delta)
                                |> normalize

                        position =
                            deltaPerp
                                |> scale h
                                |> add (delta |> normalize |> scale z)
                                |> add a
                    in
                    Just position

                _ ->
                    Nothing



-- SERIALIZATION


encode : Point -> Value
encode (Point point) =
    let
        def tag e0 e1 id id0 id1 ratio =
            Encode.object
                [ ( "tag", Encode.string tag )
                , ( "e0", Expr.encode e0 )
                , ( "e1", Expr.encode e1 )
                , ( "id", Store.encodeId id )
                , ( "id0", Store.encodeId id0 )
                , ( "id1", Store.encodeId id1 )
                , ( "ratio", Encode.float ratio )
                ]

        encodeName =
            Encode.string point.name

        encodeData =
            case point.data of
                Absolute e0 e1 ->
                    def "absolute" e0 e1 (Store.idUnsafe 0) (Store.idUnsafe 0) (Store.idUnsafe 0) 0.0

                Relative id e0 e1 ->
                    def "relative" e0 e1 id (Store.idUnsafe 0) (Store.idUnsafe 0) 0.0

                Distance id e0 e1 ->
                    def "distance" e0 e1 id (Store.idUnsafe 0) (Store.idUnsafe 0) 0.0

                Between id0 id1 ratio ->
                    def "between" (Expr.Number 0.0) (Expr.Number 0.0) (Store.idUnsafe 0) id0 id1 ratio

                CircleIntersection id0 e0 id1 e1 choice ->
                    let
                        ratio =
                            case choice of
                                LeftMost ->
                                    -1

                                RightMost ->
                                    1
                    in
                    def "circleIntersection" e0 e1 (Store.idUnsafe 0) id0 id1 ratio
    in
    Encode.object
        [ ( "name", encodeName )
        , ( "data", encodeData )
        ]


decode : Decoder Point
decode =
    let
        dataDecoder =
            Decode.at [ "tag" ] Decode.string
                |> Decode.andThen
                    (\tag ->
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

                            "circleIntersection" ->
                                Decode.map5 CircleIntersection
                                    (Decode.at [ "id0" ] Store.decodeId)
                                    (Decode.at [ "e0" ] Expr.decode)
                                    (Decode.at [ "id1" ] Store.decodeId)
                                    (Decode.at [ "e1" ] Expr.decode)
                                    (Decode.at [ "ratio" ] decodeChoice)

                            _ ->
                                Decode.fail "decodePoint: mailformed input"
                    )

        nameDecoder =
            Decode.string
    in
    Decode.map2
        (\name data ->
            Point
                { name = name
                , data = data
                }
        )
        (Decode.at [ "name" ] nameDecoder)
        (Decode.at [ "data" ] dataDecoder)
