module Agenda
    exposing
        ( Agenda
        , Description
        , getDescription
        , run
        , succeed
        , try
        , map
        , map2
        , (|=)
        , (|.)
        , zeroOrMore
        , oneOf
        )

{-|

# Agendas
@docs Agenda, run, Description, getDescription


# Combining Agendas
@docs succeed, try, map, (|=), zeroOrMore, oneOf, map2


-}


{-| An `Agenda msg a` can generate `a`'s from a given message `msg`.
-}
type Agenda msg a
    = Agenda (Result (Step msg a) a)


type Step msg a
    = Step Description (msg -> Maybe (Agenda msg a))


{-| Describe what the user should do, if she wants to successfully do
the agenda.
-}
type alias Description =
    String


{-| Obtain the description of a given agenda.
-}
getDescription : Agenda msg a -> Description
getDescription (Agenda agenda) =
    case agenda of
        Err (Step description _) ->
            description

        Ok a ->
            "nothing to do"


{-| Given a message `msg` try to run the agenda.  This can either result
in another agenda.  (Either the original agenda, if the message was not
successfull, or with a new agenda, if we need more `msg`'s.)
-}
run : Agenda msg a -> msg -> Result (Agenda msg a) a
run ((Agenda agenda) as oldAgenda) msg =
    case agenda of
        Err (Step _ action) ->
            case action msg of
                Just (Agenda (Ok result)) ->
                    Ok result

                Just nextAgenda ->
                    Err nextAgenda

                Nothing ->
                    Err oldAgenda

        Ok a ->
            Ok a


{-| An agenda that always generates an `a`.
-}
succeed : a -> Agenda msg a
succeed a =
    Agenda <| Ok a


{-| An agenda that generates an `a` from the given update function.
-}
try : Description -> (msg -> Maybe (Agenda msg a)) -> Agenda msg a
try description update =
    Agenda <| Err <| Step description update


{-| Transform the result of an agenda.
-}
map : (a -> b) -> Agenda msg a -> Agenda msg b
map func (Agenda agenda) =
    case agenda of
        Err (Step description update) ->
            let
                funcUpdate msg =
                    case update msg of
                        Just nextAgenda ->
                            Just (map func nextAgenda)

                        Nothing ->
                            Nothing
            in
                try description funcUpdate

        Ok a ->
            succeed <| func a


map2 : (a -> b -> c) -> Agenda msg a -> Agenda msg b -> Agenda msg c
map2 func (Agenda agendaA) agendaB =
    case agendaA of
        Err (Step descriptionA updateA) ->
            let
                funcUpdate msg =
                    case updateA msg of
                        Just nextAgendaA ->
                            Just (map2 func nextAgendaA agendaB)

                        Nothing ->
                            Nothing
            in
                try descriptionA funcUpdate

        Ok a ->
            map (func a) agendaB


{-| Used to chain agendas together, similarly to **[pp][parser pipelines]**.  This operator keeps the value.

[here]: https://github.com/elm-tools/parser/blob/master/README.md#parser-pipeline
-}
(|=) : Agenda msg (a -> b) -> Agenda msg a -> Agenda msg b
(|=) agendaFunc agendaArg =
    map2 apply agendaFunc agendaArg
infixl 5 |=


apply : (a -> b) -> a -> b
apply f a =
    f a


{-| Used to chain agendas together, similarly to **[pp][parser pipelines]**.  This operator ignores the value.

[here]: https://github.com/elm-tools/parser/blob/master/README.md#parser-pipeline
-}
(|.) : Agenda msg keep -> Agenda msg ignore -> Agenda msg keep
(|.) agendaKeep agendaIgnore =
    map2 always agendaKeep agendaIgnore
infixl 5 |.


{-| This agenda will succeed if the handling of the msg by the provided
agenda gives Nothing.
-}
zeroOrMore : Agenda msg a -> Agenda msg (List a)
zeroOrMore =
    zeroOrMoreIterator []


zeroOrMoreIterator : List a -> Agenda msg a -> Agenda msg (List a)
zeroOrMoreIterator list agenda =
    let
        description =
            "zero or more of " ++ (getDescription agenda)
    in
        try description <| zeroOrMoreUpdate list agenda


zeroOrMoreUpdate : List a -> Agenda msg a -> msg -> Maybe (Agenda msg (List a))
zeroOrMoreUpdate list ((Agenda agenda) as oldAgenda) msg =
    case agenda of
        Err (Step _ update) ->
            case update msg of
                Just nextAgenda ->
                    case nextAgenda of
                        Agenda (Ok result) ->
                            Just <| zeroOrMoreIterator (list ++ [ result ]) oldAgenda

                        _ ->
                            Just <| zeroOrMoreIterator list nextAgenda

                Nothing ->
                    Just <| succeed list

        Ok result ->
            Just <| zeroOrMoreIterator (list ++ [ result ]) oldAgenda


{-| Try all given agendas and move on with the first one that does
succeed. TODO: untested!
-}
oneOf : List (Agenda msg a) -> Agenda msg a
oneOf agendas =
    let
        descriptions =
            List.foldl (\a s -> s ++ ", " ++ a) "" <|
                List.map getDescription agendas

        description =
            "do one of: " ++ descriptions
    in
        Agenda <| Err <| Step description <| oneOfUpdate agendas


oneOfUpdate : List (Agenda msg a) -> msg -> Maybe (Agenda msg a)
oneOfUpdate agendas msg =
    let
        try (Agenda agenda) previousResult =
            case previousResult of
                Nothing ->
                    case agenda of
                        Err (Step _ update) ->
                            update msg

                        Ok a ->
                            Just <| succeed a

                _ ->
                    previousResult
    in
        List.foldl try Nothing agendas
