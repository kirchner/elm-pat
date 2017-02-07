module ToolCombiner
    exposing
        ( Tool(..)
          --, Step(..)
        , Next(..)
        , step
        , succeed
        , (|=)
          --, zeroOrMore
        )


type Tool msg result
    = Tool (msg -> Next msg result)


type Next msg result
    = Repeat
    | Continue (Tool msg result)
    | Finish result



--| Succeed result
--type Step msg result
--    = Cont (Tool msg result)
--    | Done result


step : msg -> Tool msg result -> Next msg result
step msg (Tool action) =
    action msg


succeed : result -> Tool msg result
succeed result =
    Tool <| \m -> Finish result


map : (a -> b) -> Tool msg a -> Tool msg b
map func (Tool action) =
    let
        newAction msg =
            case action msg of
                Repeat ->
                    Repeat

                Continue nextTool ->
                    step msg (map func nextTool)

                Finish result ->
                    Finish (func result)
    in
        Tool newAction


map2 : (a -> b -> c) -> Tool msg a -> Tool msg b -> Tool msg c
map2 func (Tool actionA) toolB =
    let
        newAction msg =
            case actionA msg of
                Repeat ->
                    Repeat

                Continue nextToolA ->
                    step msg (map2 func nextToolA toolB)

                Finish result ->
                    step msg (map (func result) toolB)
    in
        Tool newAction


(|=) : Tool msg (a -> b) -> Tool msg a -> Tool msg b
(|=) toolFunc toolArg =
    map2 apply toolFunc toolArg


apply : (a -> b) -> a -> b
apply f a =
    f a



--    case tool of
--        Tool action ->
--            case action msg of
--
--
--                Just (Tool newAction) ->
--                    Err (Tool newAction)
--
--                Nothing
--
--
--                Just (Done result) ->
--                    Ok result
--
--                Just (Cont nextTool) ->
--                    Err nextTool
--
--                Nothing ->
--                    Err tool
--
--        Succeed result ->
--            Ok result
--succeed : result -> Tool msg result
--succeed result =
--    Succeed result
--
--
--map : (a -> b) -> Tool msg a -> Tool msg b
--map func tool =
--    case tool of
--        Tool action ->
--            let
--                funcAction msg =
--                    case action msg of
--                        Just (Done result) ->
--                            Just (Done (func result))
--
--                        Just (Cont nextTool) ->
--                            Just (Cont (map func nextTool))
--
--                        Nothing ->
--                            Nothing
--            in
--                Tool funcAction
--
--        Succeed result ->
--            Succeed (func result)
--
--
--map2 : (a -> b -> c) -> Tool msg a -> Tool msg b -> Tool msg c
--map2 func toolA toolB =
--    case toolA of
--        Tool actionA ->
--            let
--                funcAction msg =
--                    case actionA msg of
--                        Just (Done resultA) ->
--                            Just (Cont (map (func resultA) toolB))
--
--                        Just (Cont nextToolA) ->
--                            Just (Cont (map2 func nextToolA toolB))
--
--                        Nothing ->
--                            Nothing
--            in
--                Tool funcAction
--
--        Succeed result ->
--            map (func result) toolB
--
--
--(|=) : Tool msg (a -> b) -> Tool msg a -> Tool msg b
--(|=) toolFunc toolArg =
--    map2 apply toolFunc toolArg
--
--
--apply : (a -> b) -> a -> b
--apply f a =
--    f a
--
--
--{-| This Tool will be Done if the handling of the msg by the provided
--Tool gives Nothing.
---}
--zeroOrMore : Tool msg a -> Tool msg (List a)
--zeroOrMore =
--    zeroOrMoreIterator []
--
--
--zeroOrMoreIterator : List a -> Tool msg a -> Tool msg (List a)
--zeroOrMoreIterator list tool =
--    Tool <| zeroOrMoreStep list tool
--
--
--zeroOrMoreStep : List a -> Tool msg a -> msg -> Maybe (Step msg (List a))
--zeroOrMoreStep list tool msg =
--    case tool of
--        Tool action ->
--            case action msg of
--                Just (Done result) ->
--                    Just (Cont (zeroOrMoreIterator (result :: list) tool))
--
--                Just (Cont tool) ->
--                    Just (Cont (zeroOrMoreIterator list tool))
--
--                Nothing ->
--                    Just (Done list)
--
--        Succeed result ->
--            Just (Done [ result ])
--
--
--{-| Try all given Tools and move on with the first one that does
--succeed. TODO: untested!
---}
--oneOf : List (Tool msg a) -> Tool msg a
--oneOf tools =
--    Tool <| oneOfStep tools
--
--
--oneOfStep : List (Tool msg a) -> msg -> Maybe (Step msg a)
--oneOfStep tools msg =
--    let
--        try tool previousResult =
--            case previousResult of
--                Nothing ->
--                    case tool of
--                        Tool action ->
--                            action msg
--
--                        Succeed result ->
--                            Just (Done result)
--
--                _ ->
--                    previousResult
--    in
--        case List.foldl try Nothing tools of
--            Just (Done result) ->
--                Just (Done result)
--
--            Just (Cont tool) ->
--                Just (Cont tool)
--
--            Nothing ->
--                Just (Cont (oneOf tools))
