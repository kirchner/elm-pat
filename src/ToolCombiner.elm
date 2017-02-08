module ToolCombiner
    exposing
        ( Tool(..)
        , step
        , succeed
        , (|=)
        , zeroOrMore
        )


type Tool msg result
    = Tool (msg -> Maybe (Tool msg result))
    | Succeed result


step : msg -> Tool msg result -> Tool msg result
step msg tool =
    case tool of
        Tool action ->
            case action msg of
                Just nextTool ->
                    nextTool

                Nothing ->
                    tool

        Succeed result ->
            Succeed result


succeed : result -> Tool msg result
succeed result =
    Succeed result


map : (a -> b) -> Tool msg a -> Tool msg b
map func tool =
    case tool of
        Tool action ->
            let
                funcAction msg =
                    case action msg of
                        Just nextTool ->
                            Just (map func nextTool)

                        Nothing ->
                            Nothing
            in
                Tool funcAction

        Succeed result ->
            Succeed (func result)


map2 : (a -> b -> c) -> Tool msg a -> Tool msg b -> Tool msg c
map2 func toolA toolB =
    case toolA of
        Tool actionA ->
            let
                funcAction msg =
                    case actionA msg of
                        Just nextToolA ->
                            Just (map2 func nextToolA toolB)

                        Nothing ->
                            Nothing
            in
                Tool funcAction

        Succeed resultA ->
            map (func resultA) toolB


(|=) : Tool msg (a -> b) -> Tool msg a -> Tool msg b
(|=) toolFunc toolArg =
    map2 apply toolFunc toolArg


apply : (a -> b) -> a -> b
apply f a =
    f a


{-| This Tool will be Done if the handling of the msg by the provided
Tool gives Nothing.
-}
zeroOrMore : Tool msg a -> Tool msg (List a)
zeroOrMore =
    zeroOrMoreIterator []


zeroOrMoreIterator : List a -> Tool msg a -> Tool msg (List a)
zeroOrMoreIterator list tool =
    Tool <| zeroOrMoreAction list tool


zeroOrMoreAction : List a -> Tool msg a -> msg -> Maybe (Tool msg (List a))
zeroOrMoreAction list tool msg =
    case tool of
        Tool action ->
            case action msg of
                Just nextTool ->
                    Just <| zeroOrMoreIterator list nextTool

                Nothing ->
                    Just <| Succeed list

        Succeed result ->
            Just <| zeroOrMoreIterator (result :: list) tool


{-| Try all given Tools and move on with the first one that does
succeed. TODO: untested!
-}
oneOf : List (Tool msg a) -> Tool msg a
oneOf tools =
    Tool <| oneOfAction tools


oneOfAction : List (Tool msg a) -> msg -> Maybe (Tool msg a)
oneOfAction tools msg =
    let
        try tool previousResult =
            case previousResult of
                Nothing ->
                    case tool of
                        Tool action ->
                            action msg

                        Succeed result ->
                            Just (Succeed result)

                _ ->
                    previousResult
    in
        List.foldl try Nothing tools
