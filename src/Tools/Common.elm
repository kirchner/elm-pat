module Tools.Common
    exposing
        ( WithMouse
        , updateMouse
        )

{- internal -}

import Types exposing (..)


type alias WithMouse a =
    { a | mouse : Maybe Position }


updateMouse :
    (WithMouse a -> msg)
    -> WithMouse a
    -> ViewPort
    -> Maybe Position
    -> msg
updateMouse callback state viewPort newMouse =
    callback { state | mouse = Maybe.map (svgToCanvas viewPort) newMouse }
