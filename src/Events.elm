module Events
    exposing
        ( onClick
        , onMove
        )

import Json.Decode exposing (..)
import VirtualDom exposing (on)
import Platform exposing (Task)


{- internal -}

import Types exposing (Position)


onClick : (Position -> msg) -> VirtualDom.Property msg
onClick tagger =
    on "click" (map tagger positionDecoder)


onMove : (Position -> msg) -> VirtualDom.Property msg
onMove tagger =
    on "mousemove" (map tagger positionDecoder)


positionDecoder : Decoder Position
positionDecoder =
    map2 Position
        (field "offsetX" int)
        (field "offsetY" int)
