module Tools.Common
    exposing
        ( WithMouse
        , exprInput
        , updateMouse
        )

import Expr exposing (..)
import Html exposing (Html)
import Html.Attributes as Html
import Html.Events as Html
import Input.Float
import Tools.Styles exposing (..)
import Types exposing (..)


type alias WithMouse a =
    { a | mouse : Maybe Position }


updateMouse :
    (WithMouse a -> msg)
    -> WithMouse a
    -> ViewPort
    -> Maybe Position
    -> msg
updateMouse callback state viewPort newMouse =
    callback { state | mouse = Maybe.map (svgToCanvas viewPort) newMouse }



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
