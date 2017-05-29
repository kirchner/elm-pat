module Tools.Select
    exposing
        ( Config
        , State
        , init
        , svg
        )

{- internal -}

import Dict exposing (Dict)
import Events
import Expr exposing (..)
import Math.Vector2 exposing (..)
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg
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


svg : Config msg -> State -> PointStore -> Dict String E -> Svg msg
svg config state store variables =
    eventCircles config state store variables


eventCircles :
    Config msg
    -> State
    -> PointStore
    -> Dict String E
    -> Svg msg
eventCircles config state store variables =
    Svg.g []
        (List.filterMap
            (eventCircle config state store variables)
            (Dict.toList store)
        )


eventCircle :
    Config msg
    -> State
    -> PointStore
    -> Dict String E
    -> ( Id, Point )
    -> Maybe (Svg msg)
eventCircle config state store variables ( id, point ) =
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
    position store variables point
        |> Maybe.map draw



{- events -}


updateFocused : (State -> msg) -> State -> Maybe Id -> msg
updateFocused callback state newFocused =
    callback { state | focused = newFocused }
