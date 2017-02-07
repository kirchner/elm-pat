module Cut exposing (..)

-- internal

import Point exposing (..)


type alias Cut =
    { anchorA : PointId
    , anchorB : PointId
    }


type alias CutId =
    Int
