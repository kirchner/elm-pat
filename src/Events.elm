module Events
    exposing
        ( onMoveWithCoords
        )

import Json.Decode as Json
import Mouse
import VirtualDom


onMoveWithCoords : (Mouse.Position -> msg) -> VirtualDom.Property msg
onMoveWithCoords tagger =
    VirtualDom.on "mousemove" (Json.map tagger offsetPosition)


offsetPosition : Json.Decoder Mouse.Position
offsetPosition =
    Json.map2 Mouse.Position
        (Json.field "offsetX" Json.int)
        (Json.field "offsetY" Json.int)
