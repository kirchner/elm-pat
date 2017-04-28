module Tools.Select
    exposing
        ( State
        , Config
        , init
        , svg
        )

import Dict
import Math.Vector2 exposing (..)
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg


{- internal -}

import Events
import Svg.Extra as Svg
import Tools.Common exposing (..)
import Types exposing (..)


{- state -}


type alias State =
    WithMouse { focused : Maybe Id }


init : State
init =
    { focused = Nothing
    , mouse = Nothing
    }



{- config -}


type alias Config msg =
    { selectPoint : Id -> msg
    , stateUpdated : State -> msg
    , viewPort : ViewPort
    }


svg : Config msg -> State -> PointStore -> Svg msg
svg config state store =
    eventCircles config state store


eventCircles : Config msg -> State -> PointStore -> Svg msg
eventCircles config state store =
    Svg.g []
        (List.filterMap (eventCircle config state store) (Dict.toList store))


eventCircle : Config msg -> State -> PointStore -> ( Id, Point ) -> Maybe (Svg msg)
eventCircle config state store ( id, point ) =
    let
        draw v =
            Svg.g []
                [ Svg.circle
                    [ Svg.cx (toString (getX v))
                    , Svg.cy (toString (getY v))
                    , Svg.r "5"
                    , Svg.fill "transparent"
                    , Svg.strokeWidth "0"
                    , Svg.onClick (config.selectPoint id)
                    , Svg.onMouseOver
                        (updateFocused config.stateUpdated state (Just id))
                    , Svg.onMouseOut
                        (updateFocused config.stateUpdated state Nothing)
                    ]
                    []
                , if id |> equals state.focused then
                    Svg.drawSelector v
                  else
                    Svg.g [] []
                ]
    in
        position store point
            |> Maybe.map draw



{- events -}


updateFocused : (State -> msg) -> State -> Maybe Id -> msg
updateFocused callback state newFocused =
    callback { state | focused = newFocused }
