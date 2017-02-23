module Model
    exposing
        ( Msg(..)
        , Model
        , defaultModel
        , Focus(..)
        )

-- external

import Dict exposing (Dict)
import Material
import Math.Vector2 exposing (..)
import Window


-- internal

import Boundary
    exposing
        ( Boundary
        , BoundaryId
        )
import Cut
    exposing
        ( Cut
        , CutId
        )
import Point
    exposing
        ( Point
        , PointId
        )
import Tools
    exposing
        ( Tool
        )


-- MSG


type Msg
    = NoOp
    | Mdl (Material.Msg Msg)
    | UpdateWindowSize Window.Size
    | SetFocus Focus
    | UnFocus
    | InitTool Tool
    | AbortTool
    | DoStep Tools.Msg



-- MODEL


type alias Model =
    { windowSize : Window.Size
    , offset : Vec2
    , points : Dict PointId Point
    , pointId : PointId
    , cuts : Dict CutId Cut
    , cutId : CutId
    , boundaries : Dict BoundaryId Boundary
    , boundaryId : BoundaryId
    , focus : Maybe Focus
    , selectedPoints : List PointId
    , selectedTool : Maybe Tool
    , mdl : Material.Model
    }


defaultModel : Model
defaultModel =
    { windowSize =
        { width = 640
        , height = 400
        }
    , offset = vec2 -320 -200
    , points = Dict.empty
    , pointId = Point.defaultId
    , cuts = Dict.empty
    , cutId = Cut.defaultId
    , boundaries = Dict.empty
    , boundaryId = Boundary.defaultId
    , focus = Nothing
    , selectedPoints = []
    , selectedTool = Nothing
    , mdl = Material.model
    }


type Focus
    = FPoint PointId
    | FCut CutId
    | FBoundary BoundaryId
