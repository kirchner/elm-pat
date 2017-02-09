module Cut
    exposing
        ( Cut
        , CutId
        , defaultId
        )

-- internal

import Point exposing (PointId)


type alias Cut =
    { anchorA : PointId
    , anchorB : PointId
    }


type alias CutId =
    Int


defaultId : CutId
defaultId =
    0
