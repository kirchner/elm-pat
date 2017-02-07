module ToolCombiner
    exposing
        ( Tool(..)
        , Step(..)
        , step
        , succeed
        , (|=)
        )


type Tool msg result
    = Tool (msg -> Maybe (Step msg result))
    | Succeed result


type Step msg result
    = Cont (Tool msg result)
    | Done result


step : msg -> Tool msg result -> Result (Tool msg result) result
step msg tool =
    case tool of
        Tool action ->
            case action msg of
                Just (Done result) ->
                    Ok result

                Just (Cont nextTool) ->
                    Err nextTool

                Nothing ->
                    Err tool

        Succeed result ->
            Ok result


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
                        Just (Done result) ->
                            Just (Done (func result))

                        Just (Cont nextTool) ->
                            Just (Cont (map func nextTool))

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
                        Just (Done resultA) ->
                            Just (Cont (map (func resultA) toolB))

                        Just (Cont nextToolA) ->
                            Just (Cont (map2 func nextToolA toolB))

                        Nothing ->
                            Nothing
            in
                Tool funcAction

        Succeed result ->
            map (func result) toolB


(|=) : Tool msg (a -> b) -> Tool msg a -> Tool msg b
(|=) toolFunc toolArg =
    map2 apply toolFunc toolArg


apply : (a -> b) -> a -> b
apply f a =
    f a
