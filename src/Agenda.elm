module Agenda
    exposing
        ( Agenda
        , run
        , succeed
        , try
        , map
        , map2
        , (|=)
        , zeroOrMore
        )


type Agenda msg a
    = Agenda (Result (msg -> Maybe (Agenda msg a)) a)


run : Agenda msg a -> msg -> Result (Agenda msg a) a
run (Agenda agenda) msg =
    case agenda of
        Err action ->
            case action msg of
                Just (Agenda (Ok result)) ->
                    Ok result

                Just nextAgenda ->
                    Err nextAgenda

                Nothing ->
                    Err <| Agenda agenda

        Ok a ->
            Ok a


succeed : a -> Agenda msg a
succeed a =
    Agenda <| Ok a


try : (msg -> Maybe (Agenda msg a)) -> Agenda msg a
try update =
    Agenda <| Err update


map : (a -> b) -> Agenda msg a -> Agenda msg b
map func (Agenda agenda) =
    case agenda of
        Err update ->
            let
                funcUpdate msg =
                    case update msg of
                        Just nextAgenda ->
                            Just (map func nextAgenda)

                        Nothing ->
                            Nothing
            in
                try funcUpdate

        Ok a ->
            succeed <| func a


map2 : (a -> b -> c) -> Agenda msg a -> Agenda msg b -> Agenda msg c
map2 func (Agenda agendaA) agendaB =
    case agendaA of
        Err updateA ->
            let
                funcUpdate msg =
                    case updateA msg of
                        Just nextAgendaA ->
                            Just (map2 func nextAgendaA agendaB)

                        Nothing ->
                            Nothing
            in
                try funcUpdate

        Ok a ->
            map (func a) agendaB


(|=) : Agenda msg (a -> b) -> Agenda msg a -> Agenda msg b
(|=) agendaFunc agendaArg =
    map2 apply agendaFunc agendaArg


apply : (a -> b) -> a -> b
apply f a =
    f a


{-| This Agenda will be Done if the handling of the msg by the provided
Agenda gives Nothing.
-}
zeroOrMore : Agenda msg a -> Agenda msg (List a)
zeroOrMore =
    zeroOrMoreIterator []


zeroOrMoreIterator : List a -> Agenda msg a -> Agenda msg (List a)
zeroOrMoreIterator list agenda =
    try <| zeroOrMoreUpdate list agenda


zeroOrMoreUpdate : List a -> Agenda msg a -> msg -> Maybe (Agenda msg (List a))
zeroOrMoreUpdate list (Agenda agenda) msg =
    case agenda of
        Err update ->
            case update msg of
                Just nextAgenda ->
                    case nextAgenda of
                        Agenda (Ok result) ->
                            Just <| zeroOrMoreIterator (list ++ [ result ]) (Agenda agenda)

                        _ ->
                            Just <| zeroOrMoreIterator list nextAgenda

                Nothing ->
                    Just <| succeed list

        Ok result ->
            Just <| zeroOrMoreIterator (list ++ [ result ]) (Agenda agenda)


{-| Try all given Tools and move on with the first one that does
succeed. TODO: untested!
-}
oneOf : List (Agenda msg a) -> Agenda msg a
oneOf agendas =
    Agenda <| Err <| oneOfUpdate agendas


oneOfUpdate : List (Agenda msg a) -> msg -> Maybe (Agenda msg a)
oneOfUpdate agendas msg =
    let
        try (Agenda agenda) previousResult =
            case previousResult of
                Nothing ->
                    case agenda of
                        Err update ->
                            update msg

                        Ok a ->
                            Just <| succeed a

                _ ->
                    previousResult
    in
        List.foldl try Nothing agendas
