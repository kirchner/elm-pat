module Tools.Common
    exposing
        ( Callbacks
        , Config
        , Data
        , WithFocused
        , WithMouse
        , exprInput
        , getPosition
        , selectPoint
        , updateFocused
        , updateMouse
        , svgUpdateMouse
        )

import Dict exposing (Dict)
import Events
import Expr exposing (..)
import Html exposing (Html)
import Html.Attributes as Html
import Html.Events as Html
import Input.Float
import Math.Vector2 exposing (..)
import Maybe.Extra as Maybe
import Svg exposing (Svg)
import Svg.Attributes as Svg
import Svg.Events as Svg
import Svg.Extra as Svg
import Tools.Styles exposing (..)
import Types exposing (..)


type alias WithMouse a =
    { a | mouse : Maybe Position }


type alias WithFocused a =
    { a | focused : Maybe Id }


updateMouse :
    (WithMouse a -> msg)
    -> WithMouse a
    -> ViewPort
    -> Maybe Position
    -> msg
updateMouse callback state viewPort newMouse =
    callback { state | mouse = Maybe.map (svgToCanvas viewPort) newMouse }


updateFocused :
    (WithFocused a -> msg)
    -> WithFocused a
    -> Maybe Id
    -> msg
updateFocused callback state newFocused =
    callback { state | focused = newFocused }


type alias Config state msg =
    { addPoint : Point -> msg
    , updatePoint : Id -> Point -> msg
    , stateUpdated : state -> msg
    , viewPort : ViewPort
    }


type alias Data =
    { store : PointStore
    , variables : Dict String E
    , viewPort : ViewPort
    , cursorPosition : Maybe Position
    , focusedPoint : Maybe Id
    }


type alias Callbacks msg =
    { addPoint : Point -> msg
    , updateCursorPosition : Maybe Position -> msg
    , focusPoint : Maybe Id -> msg
    }



{- svgs -}


svgUpdateMouse : Maybe msg -> (Maybe Position -> msg) -> Data -> Svg msg
svgUpdateMouse mouseClicked updateCursorPosition data =
    Svg.rect
        ([ Svg.x (toString data.viewPort.x)
         , Svg.y (toString data.viewPort.y)
         , Svg.width (toString data.viewPort.width)
         , Svg.height (toString data.viewPort.height)
         , Svg.fill "transparent"
         , Svg.strokeWidth "0"
         , Events.onMove (updateCursorPosition << Just)
         , Svg.onMouseOut (updateCursorPosition Nothing)
         ]
            ++ (mouseClicked
                    |> Maybe.map Svg.onClick
                    |> Maybe.toList
               )
        )
        []


drawCursor : Vec2 -> Svg msg
drawCursor position =
    let
        ( x, y ) =
            toTuple position
    in
    Svg.g []
        [ Svg.drawPoint (vec2 x y)
        , Svg.drawSelector (vec2 x y)
        ]


getPosition :
    ViewPort
    -> (WithMouse a -> msg)
    -> WithMouse a
    -> (Position -> msg)
    -> Svg msg
getPosition viewPort updateState state mouseClicked =
    Svg.rect
        [ Svg.x (toString viewPort.x)
        , Svg.y (toString viewPort.y)
        , Svg.width (toString viewPort.width)
        , Svg.height (toString viewPort.height)
        , Svg.fill "transparent"
        , Svg.strokeWidth "0"
        , Events.onClick mouseClicked
        , Events.onMove
            (updateMouse updateState state viewPort << Just)
        , Svg.onMouseOut
            (updateMouse updateState state viewPort Nothing)
        ]
        []


selectPoint :
    Config (WithMouse (WithFocused a)) msg
    -> WithMouse (WithFocused a)
    -> PointStore
    -> Dict String E
    -> (Id -> msg)
    -> Svg msg
selectPoint config state store variables callback =
    Svg.g []
        (List.filterMap
            (pointSelector config state store variables callback)
            (Dict.toList store)
        )


pointSelector :
    Config (WithMouse (WithFocused state)) msg
    -> WithMouse (WithFocused state)
    -> PointStore
    -> Dict String E
    -> (Id -> msg)
    -> ( Id, Point )
    -> Maybe (Svg msg)
pointSelector config state store variables callback ( id, point ) =
    let
        draw v =
            Svg.g []
                [ Svg.circle
                    [ Svg.cx (toString (getX v))
                    , Svg.cy (toString (getY v))
                    , Svg.r "5"
                    , Svg.fill "transparent"
                    , Svg.strokeWidth "0"
                    , Svg.onClick (callback id)
                    , Svg.onMouseOver
                        (updateFocused config.stateUpdated state (Just id))
                    , Svg.onMouseOut
                        (updateFocused config.stateUpdated state Nothing)
                    ]
                    []
                , if id |> equals state.focused then
                    Svg.drawSelector v
                  else
                    Svg.g [] []
                ]
    in
    position store variables point
        |> Maybe.map draw



{- views -}


exprInput : String -> Maybe E -> (String -> msg) -> Html msg
exprInput name e callback =
    let
        row attrs nodes =
            Html.div ([ class [ Row ] ] ++ attrs) nodes

        cell attrs nodes =
            Html.div ([ class [ Column ] ] ++ attrs) nodes

        icon name =
            cell []
                [ Html.div
                    [ class [ IconButton ] ]
                    [ Html.i
                        [ Html.class "material-icons"
                        , Html.onClick (callback "")
                        , class [ Icon ]
                        ]
                        [ Html.text name ]
                    ]
                ]

        input =
            Html.input
                [ Html.onInput callback
                , Html.placeholder
                    (e
                        |> Maybe.map print
                        |> Maybe.withDefault ""
                    )
                , class [ Textfield ]
                ]
                []
    in
    row []
        [ cell []
            [ Html.div
                [ class [ VariableName ] ]
                [ Html.text (name ++ " =") ]
            , input
            ]
        , icon "delete"
        ]
