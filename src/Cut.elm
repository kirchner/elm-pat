module Cut
    exposing
        ( Cut
        , cut
        , anchorA
        , anchorB
        , CutId
        , defaultId
        )

-- internal

import Point exposing (PointId)


type Cut
    = Cut CutInfo


type alias CutInfo =
    { anchorA : PointId
    , anchorB : PointId
    }


cut : PointId -> PointId -> Cut
cut idA idB =
    Cut
        { anchorA = idA
        , anchorB = idB
        }


anchorA : Cut -> PointId
anchorA (Cut cut) =
    cut.anchorA


anchorB : Cut -> PointId
anchorB (Cut cut) =
    cut.anchorB


type alias CutId =
    Int


defaultId : CutId
defaultId =
    0
