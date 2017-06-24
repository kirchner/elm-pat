module Views.ToolBox exposing (view)

import Editor
    exposing
        ( Msg(..)
        , allTools
        , toolName
        )
import Html exposing (..)
import Styles.ToolBox
    exposing
        ( Class(..)
        , class
        )
import Tools.Common exposing (Data)
import Views.Common exposing (iconBig)


view : Data -> Html Msg
view data =
    let
        button tool =
            iconBig "edit" (UpdateTool tool)
    in
    Html.div
        [ class [ Container ] ]
        (allTools data |> List.map button)
