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
import Styles.Colors exposing (..)
import Views.PointTable as PointTable


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
            [ viewVariableList model.variables model.newName model.newValue ]
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



{- pointlist -}


viewPointList : Dict String E -> PointStore -> Html Msg
viewPointList variables store =
    let
        styles =
            Css.asPairs >> Html.style

        rem =
            Css.rem
    in
    Html.div
        [ class [ PointList ] ]
        [ Html.table
            [ styles [ borderCollapse collapse ] ]
            (Html.tr
                [ styles
                    [ borderBottom3 (px 1) solid (hex base02) ]
                ]
                [ Html.th
                    [ class [ HeaderCell ] ]
                    [ Html.text "#" ]
                , Html.th
                    [ class [ HeaderCell ]
                    , styles
                        [ width (rem 3) ]
                    ]
                    [ Html.text "x" ]
                , Html.th
                    [ class [ HeaderCell ]
                    , styles
                        [ width (rem 3) ]
                    ]
                    [ Html.text "y" ]
                , Html.th [ class [ HeaderCell ] ] []
                , Html.th [ class [ HeaderCell ] ] []
                , Html.th [ class [ HeaderCell ] ] []
                ]
                :: (Dict.toList store |> List.map (viewPointEntry variables store))
            )
        ]


viewPointEntry : Dict String E -> PointStore -> ( Id, Point ) -> Html Msg
viewPointEntry variables store ( id, point ) =
    let
        styles =
            Css.asPairs >> Html.style

        v =
            Types.position store variables point

        x =
            v
                |> Maybe.map getX
                |> Maybe.map toString
                |> Maybe.withDefault ""

        y =
            v
                |> Maybe.map getY
                |> Maybe.map toString
                |> Maybe.withDefault ""

        icon name callback =
            Html.div
                [ class [ IconButton ] ]
                [ Html.i
                    [ Html.class "material-icons"
                    , Events.onClick callback
                    , class [ Icon ]
                    ]
                    [ Html.text name ]
                ]
    in
    Html.tr [ class [ ContentRow ] ]
        [ Html.td
            [ class [ ContentCell ] ]
            [ Html.text (toString id) ]
        , Html.td
            [ class [ ContentCell ] ]
            [ Html.text x ]
        , Html.td [ class [ ContentCell ] ]
            [ Html.text y ]
        , Html.td
            [ class [ ContentCell ]
            , styles
                [ textAlign left
                , paddingLeft (Css.rem 1.5)
                , paddingRight (Css.rem 1.5)
                ]
            ]
            [ Html.text (printPoint variables point) ]
        , Html.td [ class [ ContentCell ] ]
            [ icon "edit" (SelectPoint id) ]
        , Html.td [ class [ ContentCell ] ]
            [ icon "delete" (DeletePoint id) ]
        ]


printPoint : Dict String E -> Point -> String
printPoint variables point =
    case point of
        Types.Absolute _ _ ->
            "absolute"

        Types.Relative _ _ _ ->
            "relative"

        _ ->
            toString point



{- variable list -}


viewVariableList : Dict String E -> Maybe String -> Maybe E -> Html Msg
viewVariableList variables newName newValue =
    let
        styles =
            Css.asPairs >> Html.style

        icon name callback =
            Html.div
                [ class [ IconButton ] ]
                [ Html.i
                    [ Html.class "material-icons"
                    , Events.onClick callback
                    , class [ Icon ]
                    ]
                    [ Html.text name ]
                ]
    in
    Html.div
        [ class [ VariableList ] ]
        [ Html.table
            [ styles [ borderCollapse collapse ] ]
            (Dict.toList variables |> List.map (viewVariable variables))
        , Html.tr [ class [ ContentRow ] ]
            [ Html.td
                [ class [ ContentCell ] ]
                [ Html.input
                    [ Events.onInput NameUpdated
                    , Html.placeholder "name"
                    , styles
                        [ case newName of
                            Nothing ->
                                color (hex red)

                            Just _ ->
                                color (hex base0)
                        , backgroundColor (hex base03)
                        , borderColor transparent
                        , border zero
                        , fontFamily monospace
                        , fontSize (Css.rem 1)
                        , lineHeight (Css.rem 1)
                        , width (Css.rem 6)
                        , backgroundColor transparent
                        , focus
                            [ outline none
                            , borderColor (hex base02)
                            ]
                        ]
                    ]
                    []
                ]
            , Html.td
                [ class [ ContentCell ] ]
                [ Html.input
                    [ Events.onInput ValueUpdated
                    , Html.placeholder "value"
                    , styles
                        [ case newValue of
                            Nothing ->
                                color (hex red)

                            Just _ ->
                                color (hex base0)
                        , backgroundColor (hex base03)
                        , borderColor transparent
                        , border zero
                        , fontFamily monospace
                        , fontSize (Css.rem 1)
                        , lineHeight (Css.rem 1)
                        , width (Css.rem 10)
                        , backgroundColor transparent
                        , focus
                            [ outline none
                            , borderColor (hex base02)
                            ]
                        ]
                    ]
                    []
                ]
            , Html.td
                [ class [ ContentCell ] ]
                [ icon "add" AddVariable ]
            ]
        ]


viewVariable : Dict String E -> ( String, E ) -> Html Msg
viewVariable variables ( name, expr ) =
    let
        styles =
            Css.asPairs >> Html.style
    in
    Html.div
        [ styles
            [ displayFlex
            , flexFlow1 row
            ]
        ]
        [ Html.div []
            [ String.concat
                [ name
                , ": "
                , Expr.print expr
                , " = "
                , toString (Expr.compute variables expr)
                ]
                |> Html.text
            ]
        ]



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
    | PointList
    | VariableList
    | HeaderCell
    | ContentRow
    | ContentCell
    | IconButton
    | Icon


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
        , Css.class PointList
            [ color (hex base0)
            , backgroundColor (hex base2)
            , property "pointer-events" "auto"
            , fontFamily monospace
            , fontSize (Css.rem 1)
            , lineHeight (Css.rem 1)
            ]
        , Css.class VariableList
            [ color (hex base0)
            , backgroundColor (hex base2)
            , property "pointer-events" "auto"
            , fontFamily monospace
            , fontSize (Css.rem 1)
            , lineHeight (Css.rem 1)
            ]
        , Css.class HeaderCell
            [ paddingLeft (Css.rem 0.3)
            , paddingRight (Css.rem 0.3)
            , paddingTop (Css.rem 0.1)
            , paddingBottom (Css.rem 0.2)
            , borderBottom3 (px 1) solid (hex base02)
            , textAlign right
            ]
        , Css.class ContentRow
            [ hover
                [ backgroundColor (hex base3) ]
            ]
        , Css.class ContentCell
            [ paddingLeft (Css.rem 0.3)
            , paddingRight (Css.rem 0.3)
            , paddingTop (Css.rem 0.1)
            , paddingBottom (Css.rem 0.1)
            , textAlign right
            ]
        , Css.class IconButton
            [ width (Css.rem 1)
            , height (Css.rem 1)
            , borderRadius (pct 50)
            , color (hex base0)
            , backgroundColor transparent
            , cursor pointer
            , hover
                [ backgroundColor (hex base02)
                ]
            , Css.position Css.relative
            ]
        , Css.class Icon
            [ important (Css.fontSize (Css.rem 0.6))
            , important (Css.lineHeight (Css.rem 0.6))
            , Css.position Css.absolute
            , Css.top (Css.pct 50)
            , Css.left (Css.pct 50)
            , Css.transform (Css.translate2 (Css.pct -50) (Css.pct -50))
            ]
        ]
