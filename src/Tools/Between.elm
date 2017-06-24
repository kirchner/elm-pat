module Tools.Between
    exposing
        ( State
        , init
        , svg
        , view
        )

import Expr exposing (E)
import Html exposing (Html)
import Point exposing (Point)
import Store exposing (Id, Store)
import Svg exposing (Svg)
import Tools.Common exposing (Callbacks, Data)
import Tools.Dropdown as Dropdown


type alias State =
    { firstDropdown : Dropdown.State
    , first : Maybe ( Id Point, Point )
    , lastDropdown : Dropdown.State
    , last : Maybe ( Id Point, Point )
    , ratio : Maybe E
    }


init : Data -> State
init data =
    { firstDropdown = Dropdown.init
    , first = Nothing
    , lastDropdown = Dropdown.init
    , last = Nothing
    , ratio = Nothing
    }


point : Data -> State -> Maybe Point
point data state =
    Nothing



{- svg -}


svg : Callbacks msg -> (State -> msg) -> Data -> State -> Svg msg
svg callbacks updateState data state =
    Svg.g [] []



{- view -}


view : Callbacks msg -> (State -> msg) -> Data -> State -> Html msg
view callbacks updateState data state =
    Html.div [] []
