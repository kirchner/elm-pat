module Model exposing (..)

-- external

import Dict exposing (Dict)
import Math.Vector2 exposing (..)
import Window


-- internal

import Point exposing (..)


-- MSG


type Msg
    = NoOp
    | UpdateWindowSize Window.Size
    | AddOrigin OriginInfo
    | FocusPoint PointId
    | UnFocusPoint PointId



-- MODEL


type alias Model =
    { windowSize : Window.Size
    , points : Dict PointId Point
    , pointId : PointId
    , focusedPointId : Maybe PointId
    }


defaultModel : Model
defaultModel =
    { windowSize =
        { width = 640
        , height = 400
        }
        --, points = Dict.empty
        --, pointId = defaultId
    , points =
        Dict.fromList
            [ ( 0, Origin { position = vec2 40 40 } )
            ]
    , pointId = 1
    , focusedPointId = Nothing
    }
