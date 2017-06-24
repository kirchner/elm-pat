module FileBrowser exposing (..)

import Html exposing (Html)
import Html.Events as Html
import Styles.FileBrowser exposing (Class(..), class, classList)
import Views.Common exposing (iconBig)


type alias FileBrowser =
    {}


defaultModel : FileBrowser
defaultModel =
    {}


type Msg
    = NoOp


update : Msg -> FileBrowser -> FileBrowser
update msg model =
    model


type alias Callbacks msg =
    { clearSession : Maybe msg
    , lift : Msg -> msg
    , loadRemoteFile : Maybe (String -> msg)
    }


view : Callbacks msg -> a -> Html msg
view callbacks data =
    let
        onClick url =
            callbacks.loadRemoteFile
                |> Maybe.map (\loadRemoteFile -> loadRemoteFile url)
                |> Maybe.withDefault (callbacks.lift NoOp)

        fileLink url label =
            Html.a
                [ class
                    [ FileBrowserFileLink
                    ]
                , Html.onClick (onClick url)
                ]
                [ Html.text label
                ]
    in
    Html.div
        [ class [ Styles.FileBrowser.FileBrowser ]
        ]
        (List.concat
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


github : String -> String
github fn =
    "https://raw.githubusercontent.com/kirchner/elm-pat/master/demo_patterns/" ++ fn
