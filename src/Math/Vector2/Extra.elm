module Math.Vector2.Extra
    exposing
        ( areColinear
        , haveSameDirection
        , intersectCircleCircle
        , perp
        , project
        , vecProduct
        )

import Math.Vector2 exposing (..)


{-| Project the first vector orthogonally onto the second vector
-}
project : Vec2 -> Vec2 -> Vec2
project v w =
    w |> scale (dot v w / lengthSquared w)


{-| Compute the vector product of two vectors.
-}
vecProduct : Vec2 -> Vec2 -> Vec2
vecProduct v w =
    vec2 (getX v * getY w) (-1 * getY v * getX w)


{-| Check, if two vectors are colinear
-}
areColinear : Vec2 -> Vec2 -> Bool
areColinear v w =
    length (vecProduct v w) == 0


{-| Check, if two vectors lie in the same half-space, i.e. the smallest
angle between them is strictly smaller 90 degrees.
-}
haveSameDirection : Vec2 -> Vec2 -> Bool
haveSameDirection v w =
    dot v w > 0


{-| Rotate the vector counterclockwise by 90 degrees.
-}
perp : Vec2 -> Vec2
perp v =
    vec2 (-1 * getY v) (getX v)


{-| Compute the intersection of two circles
-}
intersectCircleCircle : Bool -> Vec2 -> Float -> Vec2 -> Float -> Maybe Vec2
intersectCircleCircle leftMost a rA b rB =
    let
        delta =
            b |> flip sub a

        dist =
            delta |> length

        distSquared =
            delta |> lengthSquared

        d =
            delta
                |> scale (((rA ^ 2 - rB ^ 2) / distSquared + 1) / 2)

        normalDeltaPerp =
            delta
                |> normalize
                |> perp

        l =
            sqrt (rA ^ 2 - lengthSquared d)

        factor =
            if leftMost then
                1
            else
                -1
    in
    if dist <= rA + rB then
        normalDeltaPerp
            |> scale (l * factor)
            |> add d
            |> add a
            |> Just
    else
        Nothing
