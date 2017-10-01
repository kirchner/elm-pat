port module Ports
    exposing
        ( autofocus
        , dumpFile0
        , serialize
        )

import Json.Decode exposing (Value)


port autofocus : () -> Cmd msg


port serialize : Value -> Cmd msg


port dumpFile0 : () -> Cmd msg
