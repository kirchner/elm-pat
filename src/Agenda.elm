module Agenda
    exposing
        ( Agenda
        , Description
        , getDescription
        , run
        , runs
        , succeed
        , try
        , map
        , map2
        , (|=)
        , (|.)
          --, zeroOrMore
        , oneOf
        )

{-|

Convenient way of implementing chains of user actions inspired by
elm-tools/parser.

Suppose you are writing a vector graphic program.  You want the user to
be able to add a line segment


    type alias Line =
        { start : Vec2
        , end : Vec2
        }


by clicking two times into the canvas in order to give the position of
its start and end point.  We can implement such a tool as the
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
lineTool`.  Then each time the user triggers a message the selectedTool
value is updated via `run tool msg`, which either returns a new Agenda
we have to save to be ready for more user input, or it returns `Ok
Line`, which we then can add to the set of our lines.


# Agendas
@docs Agenda, run, Description, getDescription


# Combining Agendas
@docs succeed, try, map, (|=), zeroOrMore, oneOf, map2


-}


{-| An `Agenda msg a` can generate `a`'s from a given message `msg`.
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


{-| Given a message `msg` try to run the agenda.  This can either result
in another agenda.  (Either the original agenda, if the message was not
successfull, or with a new agenda, if we need more `msg`'s.)
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


{-| An agenda that always generates an `a`.
-}
succeed : a -> Agenda msg a
succeed a =
    Agenda <| Ok <| Just a


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


fail : Agenda msg a
fail =
    Agenda <| Ok Nothing


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


{-| Used to chain agendas together, similarly to **[pp][parser
pipelines]**.  This operator keeps the value.

[here]: https://github.com/elm-tools/parser/blob/master/README.md#parser-pipeline
-}
(|=) : Agenda msg (a -> b) -> Agenda msg a -> Agenda msg b
(|=) agendaFunc agendaArg =
    map2 apply agendaFunc agendaArg
infixl 5 |=


apply : (a -> b) -> a -> b
apply f a =
    f a


{-| Used to chain agendas together, similarly to **[pp][parser
pipelines]**.  This operator ignores the value.

[here]: https://github.com/elm-tools/parser/blob/master/README.md#parser-pipeline
-}
(|.) : Agenda msg keep -> Agenda msg ignore -> Agenda msg keep
(|.) agendaKeep agendaIgnore =
    map2 always agendaKeep agendaIgnore
infixl 5 |.



{- This agenda will succeed if the handling of the msg by the provided
   agenda gives Nothing.
-}
{-
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
                           Agenda (Ok (Just result)) ->
                               Just <| zeroOrMoreIterator (list ++ [ result ]) oldAgenda

                           Agenda (Ok Nothing) ->
                               Nothing

                           _ ->
                               Just <| zeroOrMoreIterator list nextAgenda

                   Nothing ->
                       Just <| succeed list

           Ok (Just result) ->
               Just <| zeroOrMoreIterator (list ++ [ result ]) oldAgenda

           Ok Nothing ->
               Nothing

-}


{-| Try all given agendas simultaniously.  Succeeds if one of them
succeeds.  May be resource hungry since we do not exclusivly switch to
the first Agenda which succeeds in the first run iteration.
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

            _ ->
                Just <| oneOf liveAgendas
