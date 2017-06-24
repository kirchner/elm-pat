module FileBrowser exposing (..)

import Html exposing (Html)
import Html.Events as Html
import Views.Common exposing (iconBig)
import Styles.FileBrowser exposing (Class(..), class, classList)
import Http


type alias FileBrowser =
    {
    }


defaultModel =
    {
    }


type Msg
    = NoOp


update msg model =
    model


view callbacks data =
    let
        fileLink url label =
            Html.a
            [ class
              [ FileBrowserFileLink
              ]
            , Html.onClick <|
              Maybe.withDefault (callbacks.lift NoOp) (Maybe.map (\loadRemoteFile -> loadRemoteFile url) callbacks.loadRemoteFile)
            ]
            [ Html.text label
            ]
    in
    Html.div
        [ class [ Styles.FileBrowser.FileBrowser ]
        ]
        ( List.concat
          [ [ Html.div
              [ class [ FileBrowserFileLinkWrapper ]
              ]
              [ fileLink (github "demo-demo.json") "demo-demo"
              , fileLink (github "basic_bodice.json") "basic bodice"
              ]
            ]
          , [ iconBig "close" <|
              Maybe.withDefault (callbacks.lift NoOp) callbacks.clearSession
            ]
          ]
        )


github fn =
    "https://raw.githubusercontent.com/kirchner/elm-pat/master/demo_patterns/" ++ fn
