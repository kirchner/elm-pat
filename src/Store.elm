module Store
    exposing
        ( Id
        , Store
        , empty
        , get
        , insert
        , toList
        , update
        )

import Dict exposing (Dict)


type Store a
    = Store
        { data : Dict Int a
        , nextId : Int
        }


type Id a
    = Id Int


empty : Store a
empty =
    Store
        { data = Dict.empty
        , nextId = 0
        }


get : Id a -> Store a -> Maybe a
get (Id id) (Store store) =
    Dict.get id store.data


insert : a -> Store a -> Store a
insert element (Store store) =
    Store
        { store
            | data = Dict.insert store.nextId element store.data
            , nextId = 1 + store.nextId
        }


update : Id a -> (Maybe a -> Maybe a) -> Store a -> Store a
update (Id id) f (Store store) =
    Store
        { store | data = Dict.update id f store.data }


toList : Store a -> List ( Id a, a )
toList (Store store) =
    Dict.toList store.data
        |> List.map (\( id, element ) -> ( Id id, element ))
