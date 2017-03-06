module Agenda
    exposing
        ( Agenda
        , Description
        , getDescription
        , run
        , runs
        , succeed
        , try
        , fail
        , map
        , map2
        , (|=)
        , (|.)
        , zeroOrMore
        , FailureHandling
            ( Fail
            , Succeed
            , Retry
            )
        , oneOf
        )

{-| Convenient way of implementing the handling of chains of user
actions.  This is inspired **[this parser][parser]**.

[parser]: http://package.elm-lang.org/packages/elm-tools/parser/1.0.2/

Suppose you are writing a vector graphics program.  You want the user to
be able to add a line segment


    type alias Line =
        { start : Vec2
        , end : Vec2
        }


by clicking two times into the canvas in order to give the position of
its start and its end point.  We can implement such a tool as the
following `Agenda`:


    lineTool : Agenda Msg Line
    lineTool =
        succeed Line
            |= inputPosition
            |= inputPosition


    inputPosition  : Agenda Msg Vec2
    inputPosition =
        try "input position" <|
            \msg ->
                case msg of
                    InputPosition v ->
                        Just <| succeed v

                    _ ->
                        Nothing


    type Msg
        = NoOp
        | InputPosition Vec2


Then the model is given by


    type alias Model =
        { selectedTool : Maybe (Agenda Msg Line)
        , ...
        }


When the user chooses to add a line, we set `selectedTool = Just
lineTool`.  Then each time the user triggers a message our update
function has to update `selectedTool` via `run tool msg`, which either
returns a new Agenda `newAgenda` which we store by setting `selectedTool
= Just newAgenda` in order to be ready for more user input, or it
returns `Ok Line`, which we then can add to the set of lines and we
set `selectedTool = Nothing`.


# Agendas
@docs Agenda, run, runs, Description, getDescription


# Combining Agendas
@docs succeed, fail, try, map, map2, (|=), (|.), zeroOrMore, FailureHandling, oneOf
-}


{-| An `Agenda msg a` can generate `a`'s if fed with the correct `msg`'s.
-}
type Agenda msg a
    = Agenda (Result (Step msg a) (Maybe a))


type Step msg a
    = Step Description (msg -> Maybe (Agenda msg a))



{-
   type Step description msg a
       = Step (Maybe description) (msg -> Maybe (Agenda msg a))

   describe : Agenda msg a -> (List description -> description) -> Agenda msg a
-}


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


{-| Given a `msg` try to run the agenda.  This can either give
another agenda (`Err newAgenda`), the final result (`Ok (Just a)`) or
terminate, when the given `msg` was not suitable (`Ok Nothing`).
-}
run : Agenda msg a -> msg -> Result (Agenda msg a) (Maybe a)
run ((Agenda agenda) as oldAgenda) msg =
    case agenda of
        Err (Step _ action) ->
            case action msg of
                Just (Agenda (Ok result)) ->
                    Ok result

                Just nextAgenda ->
                    Err nextAgenda

                Nothing ->
                    Ok Nothing

        Ok a ->
            Ok a


{-| Run all `msg`'s in the list.
-}
runs : Agenda msg a -> List msg -> Result (Agenda msg a) (Maybe a)
runs ((Agenda agenda) as oldAgenda) msgs =
    case msgs of
        [] ->
            Err oldAgenda

        msg :: rest ->
            case run oldAgenda msg of
                Ok result ->
                    Ok result

                Err nextAgenda ->
                    runs nextAgenda rest


{-| An agenda that always generates an `a`.
-}
succeed : a -> Agenda msg a
succeed a =
    Agenda <| Ok <| Just a


{-| An Agenda that always fails.
-}
fail : Agenda msg a
fail =
    Agenda <| Ok Nothing


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

        Ok (Just a) ->
            succeed <| func a

        Ok Nothing ->
            fail


{-| -}
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

        Ok (Just a) ->
            map (func a) agendaB

        Ok Nothing ->
            fail


{-| Used to chain agendas together, similarly to **[parser
pipelines][pp]**.  This operator keeps the value.

[pp]: https://github.com/elm-tools/parser/blob/master/README.md#parser-pipeline
-}
(|=) : Agenda msg (a -> b) -> Agenda msg a -> Agenda msg b
(|=) agendaFunc agendaArg =
    map2 apply agendaFunc agendaArg
infixl 5 |=


apply : (a -> b) -> a -> b
apply f a =
    f a


{-| Used to chain agendas together, similarly to **[parser
pipelines][pp]**.  This operator ignores the value.

[pp]: https://github.com/elm-tools/parser/blob/master/README.md#parser-pipeline
-}
(|.) : Agenda msg keep -> Agenda msg ignore -> Agenda msg keep
(|.) agendaKeep agendaIgnore =
    map2 always agendaKeep agendaIgnore
infixl 5 |.


{-| Keep on repeating the given Agenda until the given exit `msg`
is sent, collecting all results.  See the documentation of
FailureHandling for the meaning the second argument.
-}
zeroOrMore : msg -> FailureHandling -> Agenda msg a -> Agenda msg (List a)
zeroOrMore exitMsg failureHandling =
    zeroOrMoreIterator exitMsg failureHandling []


{-| If one Agenda fails, do we let the whole Agenda `Fail` (and possibly
loose the previous results), or do we `Succeed` with the list of results
collected so far, or do we return the last agenda so the user can
`Retry`?
-}
type FailureHandling
    = Fail
    | Succeed
    | Retry


zeroOrMoreIterator :
    msg
    -> FailureHandling
    -> List a
    -> Agenda msg a
    -> Agenda msg (List a)
zeroOrMoreIterator exitMsg failureHandling list agenda =
    let
        description =
            "zero or more of " ++ (getDescription agenda)
    in
        try description <| zeroOrMoreUpdate exitMsg failureHandling list agenda


zeroOrMoreUpdate :
    msg
    -> FailureHandling
    -> List a
    -> Agenda msg a
    -> msg
    -> Maybe (Agenda msg (List a))
zeroOrMoreUpdate exitMsg failureHandling list ((Agenda agenda) as oldAgenda) msg =
    if exitMsg == msg then
        Just <| succeed list
    else
        case agenda of
            Err (Step _ update) ->
                case update msg of
                    Just nextAgenda ->
                        case nextAgenda of
                            Agenda (Ok (Just result)) ->
                                Just <|
                                    (zeroOrMoreIterator exitMsg failureHandling)
                                        (list ++ [ result ])
                                        oldAgenda

                            Agenda (Ok Nothing) ->
                                Nothing

                            _ ->
                                Just <|
                                    (zeroOrMoreIterator exitMsg failureHandling)
                                        list
                                        nextAgenda

                    Nothing ->
                        case failureHandling of
                            Fail ->
                                Just <| fail

                            Succeed ->
                                Just <| succeed list

                            Retry ->
                                Just <|
                                    (zeroOrMoreIterator exitMsg failureHandling)
                                        list
                                        oldAgenda

            Ok (Just result) ->
                Just <|
                    (zeroOrMoreIterator exitMsg failureHandling)
                        (list ++ [ result ])
                        oldAgenda

            Ok Nothing ->
                Nothing


{-| Try all given agendas simultaniously.  Succeeds as soon as one of
them succeeds.  Fails if all agendas have failed.  Could be resource
hungry since we do not exclusively switch to the first Agenda which
succeeds after the first `run` iteration.
-}
oneOf : List (Agenda msg a) -> Agenda msg a
oneOf agendas =
    let
        descriptions =
            List.foldl (\a s -> s ++ " " ++ a) "" <|
                List.map getDescription agendas

        description =
            "do one of: " ++ descriptions
    in
        Agenda <|
            Err <|
                Step description (oneOfUpdate agendas)


oneOfUpdate : List (Agenda msg a) -> msg -> Maybe (Agenda msg a)
oneOfUpdate agendas msg =
    let
        newAgendas =
            agendas |> List.map action

        action : Agenda msg a -> msg -> Maybe (Agenda msg a)
        action (Agenda agenda) msg =
            case agenda of
                Err (Step _ update) ->
                    update msg

                Ok (Just result) ->
                    Just (succeed result)

                Ok Nothing ->
                    Nothing

        liveAgendas =
            newAgendas |> List.filterMap ((|>) msg)

        result msg =
            newAgendas |> List.foldl (collect msg) Nothing

        collect : msg -> (msg -> Maybe (Agenda msg a)) -> Maybe a -> Maybe a
        collect msg nextAction result =
            case result of
                Nothing ->
                    case nextAction msg of
                        Just (Agenda (Ok newResult)) ->
                            newResult

                        _ ->
                            Nothing

                _ ->
                    result
    in
        case result msg of
            Just result ->
                Just (succeed result)

            Nothing ->
                if List.isEmpty liveAgendas then
                    Nothing
                else
                    Just <| oneOf liveAgendas
