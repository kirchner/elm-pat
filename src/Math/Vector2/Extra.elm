module Math.Vector2.Extra
    exposing
        ( areColinear
        , haveSameDirection
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
