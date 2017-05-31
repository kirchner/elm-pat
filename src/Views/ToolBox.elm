module Views.ToolBox exposing (view)

import Editor
    exposing
        ( Msg(..)
        , allTools
        , toolName
        )
import Html exposing (..)
import Html.Attributes as Html
import Html.Events exposing (..)
import Styles.ToolBox
    exposing
        ( Class(..)
        , class
        )
import Views.Common exposing (iconBig)


view : Html Msg
view =
    let
        button tool =
            iconBig "edit" (UpdateTool tool)

        --Html.div
        --    [ class [ ButtonWrapper ] ]
        --    [ Html.div
        --        [ class [ Button ]
        --        , Events.onClick (UpdateTool tool)
        --        ]
        --        [ Html.text (toolName tool) ]
        --    , Html.div [ class [ Tooltip ] ]
        --        [ Html.text (toolDescription tool) ]
        --    ]
    in
    Html.div
        [ class [ Container ] ]
        (allTools |> List.map button)
