module File exposing
    ( empty
    , load
    , load_
    , save
    , store
    , restore
    , encode
    , decode
    )

import Dict exposing (Dict)
import Expr exposing (E)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Model exposing (..)
import Piece exposing (Piece)
import Point exposing (Point)
import Store exposing (Id, Store)


empty : File
empty =
    { store = Store.empty
    , pieceStore = Store.empty
    , variables = Dict.empty
    , selectedPoints = []
    }


load : File -> Model
load file =
    load_ file defaultModel


load_ : File -> Model -> Model
load_ file defaultModel =
    { defaultModel
      | store = file.store
      , pieceStore = file.pieceStore
      , variables = file.variables
      , selectedPoints = file.selectedPoints
    }


save : Model -> File
save model =
    { store = model.store
    , pieceStore = model.pieceStore
    , variables = model.variables
    , selectedPoints = model.selectedPoints
    }


store : Model -> Encode.Value
store =
    save >> encode


restore : Decode.Value -> Model -> Model
restore value defaultModel =
    Decode.decodeValue decode value
    |> Result.map (\file -> load_ file defaultModel)
    |> Result.toMaybe
    |> Maybe.withDefault defaultModel


-- SERIALIZATION


encode : File -> Encode.Value
encode model =
    Encode.object
    [ ("store", Store.encode Point.encode model.store)
    , ("pieceStore", Store.encode Piece.encode model.pieceStore)
    , ("variables", encodeVariables model.variables)
    , ("selectedPoints", Encode.list (List.map Store.encodeId model.selectedPoints))
    ]


decode : Decoder File
decode =
    Decode.map4 File
        (Decode.at ["store"] (Store.decode Point.decode))
        (Decode.at ["pieceStore"] (Store.decode Piece.decode))
        (Decode.at ["variables"] decodeVariables)
        (Decode.at ["selectedPoints"] (Decode.list Store.decodeId))


encodeVariables : Dict String E -> Encode.Value
encodeVariables variables =
    variables
    |> Dict.map (\id expr -> (id, Expr.encode expr))
    |> Dict.values
    |> Encode.object


decodeVariables : Decoder (Dict String E)
decodeVariables =
    Decode.dict Expr.decode
