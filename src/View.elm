module View exposing (css, view)

import Css exposing (..)
import Css.Elements
import Css.Namespace exposing (namespace)
import Dict exposing (Dict)
import Editor
    exposing
        ( Model
        , Msg(..)
        , Tool(..)
        , allTools
        , toolDescription
        , toolName
        )
import Expr exposing (..)
import Html exposing (Html)
import Html.Attributes as Html
import Html.CssHelpers exposing (withNamespace)
import Html.Events as Events
import Math.Vector2 exposing (..)
import Styles.Colors exposing (..)
import Svg exposing (Svg)
import Tools.Absolute as Absolute
import Tools.Relative as Relative
import Tools.Select as Select
import Types
    exposing
        ( Id
        , Point
        , PointStore
        , ViewPort
        )
import View.Canvas as Canvas
import Views.PointTable as PointTable
import Views.VariableTable as VariableTable


{- main view -}


view : Model -> Html Msg
view model =
    let
        styles =
            Css.asPairs >> Html.style
    in
    Html.div []
        [ Html.div
            [ styles
                [ Css.position Css.absolute
                , Css.property "pointer-events" "none"
                ]
            ]
            [ viewToolBox
            , viewToolInfo model.viewPort model.variables model.store model.tool
            ]
        , Html.div
            [ styles
                [ Css.position Css.absolute
                , Css.bottom (Css.pct 0)
                , Css.left (Css.pct 0)
                ]
            ]
            [ PointTable.view model.variables model.store ]
        , Html.div
            [ styles
                [ Css.position Css.absolute
                , Css.bottom (Css.pct 0)
                , Css.right (Css.pct 0)
                ]
            ]
            [ VariableTable.view model.variables model.newName model.newValue ]
        , viewCanvas model
        ]



{- tool box -}


viewToolBox : Html Msg
viewToolBox =
    let
        button tool =
            Html.div [ class [ ButtonWrapper ] ]
                [ Html.div
                    [ class [ Button ]
                    , Events.onClick (UpdateTool tool)
                    ]
                    [ Html.text (toolName tool) ]
                , Html.div [ class [ Tooltip ] ]
                    [ Html.text (toolDescription tool) ]
                ]
    in
    Html.div
        [ class [ Main ] ]
        (allTools |> List.map button)


viewToolInfo : ViewPort -> Dict String E -> PointStore -> Tool -> Html Msg
viewToolInfo viewPort variables store tool =
    case tool of
        Absolute state ->
            Absolute.view variables (addAbsoluteConfig viewPort) state

        Relative state ->
            Relative.view (addRelativeConfig viewPort) state store

        Select _ ->
            Html.div [] []

        None ->
            Html.div [] []



{- canvas -}


viewCanvas : Model -> Html Msg
viewCanvas model =
    Canvas.view
        (drawTool model.viewPort model.variables model.store model.tool)
        model.viewPort
        model.store
        model.variables


drawTool : ViewPort -> Dict String E -> PointStore -> Tool -> Svg Msg
drawTool viewPort variables store tool =
    case tool of
        Absolute state ->
            Absolute.svg variables (addAbsoluteConfig viewPort) state

        Relative state ->
            Relative.svg (addRelativeConfig viewPort) state store variables

        Select state ->
            Select.svg (selectConfig viewPort) state store variables

        None ->
            Svg.g [] []



{- tool configurations -}


addAbsoluteConfig : ViewPort -> Absolute.Config Msg
addAbsoluteConfig viewPort =
    { addPoint = AddPoint
    , updatePoint = UpdatePoint
    , stateUpdated = UpdateTool << Absolute
    , viewPort = viewPort
    }


addRelativeConfig : ViewPort -> Relative.Config Msg
addRelativeConfig viewPort =
    { addPoint = AddPoint
    , updatePoint = UpdatePoint
    , stateUpdated = UpdateTool << Relative
    , viewPort = viewPort
    }


selectConfig : ViewPort -> Select.Config Msg
selectConfig viewPort =
    { selectPoint = SelectPoint
    , stateUpdated = UpdateTool << Select
    , viewPort = viewPort
    }



{- css -}


type Class
    = Main
    | ButtonWrapper
    | Button
    | Tooltip


{ id, class, classList } =
    withNamespace "toolbar"


css =
    (stylesheet << namespace "toolbar")
        [ Css.Elements.body
            [ margin zero ]
        , Css.class Main
            [ displayFlex
            , flexFlow1 row
            , property "pointer-events" "auto"
            ]
        , Css.class ButtonWrapper
            [ position relative
            , hover
                [ Css.descendants
                    [ Css.class Tooltip
                        [ opacity (num 1)
                        , property "visibility" "visible"
                        , transforms
                            [ translateX (pct -50)
                            , scale3d 1 1 1
                            ]
                        ]
                    ]
                ]
            ]
        , Css.class Button
            [ textAlign center
            , width (Css.rem 10)
            , height (Css.rem 2)
            , lineHeight (Css.rem 2)
            , color (hex base0)
            , backgroundColor (hex base03)
            , cursor pointer
            , hover
                [ backgroundColor (hex base02) ]
            ]
        , Css.class Tooltip
            [ display inlineBlock
            , property "visibility" "invisible"
            , opacity (num 0)
            , transforms
                [ translateX (pct -50)
                , scale3d 0 0 1
                ]
            , property "transition"
                ("opacity 150ms ease-in-out"
                    ++ ", transform 150ms ease-in-out"
                )
            , position absolute
            , top (pct 100)
            , left (pct 50)
            , marginTop (Css.rem 0.5)
            , padding (Css.rem 0.2)
            , color (hex base0)
            , backgroundColor (hex base2)
            , fontSize smaller
            , borderRadius (px 2)
            ]
        ]
