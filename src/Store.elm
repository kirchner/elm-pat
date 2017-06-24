module Store
    exposing
        ( Id
        , Store
        , empty
        , fromInt
        , get
        , insert
        , intKeys
        , keys
        , remove
        , toInt
        , toList
        , update
        , values
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


insert : a -> Store a -> ( Id a, Store a )
insert element (Store store) =
    ( Id store.nextId
    , Store
        { store
            | data = Dict.insert store.nextId element store.data
            , nextId = 1 + store.nextId
        }
    )


update : Id a -> (Maybe a -> Maybe a) -> Store a -> Store a
update (Id id) f (Store store) =
    Store
        { store | data = Dict.update id f store.data }


remove : Id a -> Store a -> Store a
remove (Id id) (Store store) =
    Store
        { store | data = Dict.remove id store.data }


values : Store a -> List a
values (Store store) =
    Dict.values store.data


keys : Store a -> List (Id a)
keys (Store store) =
    Dict.keys store.data
        |> List.map Id


intKeys : Store a -> List Int
intKeys (Store store) =
    -- TODO: we should remove this function in the future
    Dict.keys store.data


toInt : Id a -> Int
toInt (Id id) =
    -- TODO: we should remove this function in the future
    id


fromInt : Int -> Id a
fromInt id =
    -- TODO: we should remove this function in the future
    Id id


toList : Store a -> List ( Id a, a )
toList (Store store) =
    Dict.toList store.data
        |> List.map (\( id, element ) -> ( Id id, element ))
