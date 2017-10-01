module Events
    exposing
        ( onClick
        , onMouseDown
        , onMove
        , onWheel
        )

{- internal -}

import Data.Position exposing (Position)
import Json.Decode exposing (..)
import VirtualDom exposing (on)


onClick : (Position -> msg) -> VirtualDom.Property msg
onClick tagger =
    on "click" (map tagger positionDecoder)


onMove : (Position -> msg) -> VirtualDom.Property msg
onMove tagger =
    on "mousemove" (map tagger positionDecoder)


onMouseDown : (Position -> msg) -> VirtualDom.Property msg
onMouseDown tagger =
    on "mousedown" (map tagger positionDecoder)


positionDecoder : Decoder Position
positionDecoder =
    map2 Position
        (field "clientX" int)
        (field "clientY" int)


onWheel : (Float -> msg) -> VirtualDom.Property msg
onWheel onZoom =
    let
        ignoreDefaults =
            VirtualDom.Options True True
    in
    VirtualDom.onWithOptions
        "wheel"
        ignoreDefaults
        (map onZoom <| field "deltaY" float)
