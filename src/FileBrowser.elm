module FileBrowser exposing (..)

import Html exposing (Html)
import Html.Events as Html
import Styles.FileBrowser exposing (Class(..), class, classList)
import Views.Common exposing (iconBig)
import UndoList exposing (UndoList)


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


type alias Callbacks a msg =
    { clearSession : Maybe msg
    , lift : Msg -> msg
    , loadRemoteFile : Maybe (String -> msg)
    , restoreSession : Maybe (a -> msg)
    , undo : Maybe msg
    , redo : Maybe msg
    }


view : Callbacks a msg -> UndoList a -> Html msg
view callbacks undoList =
    let
        loadRemoteFile url =
            callbacks.loadRemoteFile
                |> Maybe.map (\loadRemoteFile -> loadRemoteFile url)
                |> Maybe.withDefault (callbacks.lift NoOp)

        restoreSession file =
            callbacks.restoreSession
                |> Maybe.map (\restoreSession -> restoreSession file)
                |> Maybe.withDefault (callbacks.lift NoOp)

        fileLink url label =
            Html.a
                [ class
                    [ FileBrowserFileLink
                    ]
                , Html.onClick (loadRemoteFile url)
                ]
                [ Html.text label
                ]

        historyLink file label =
            Html.a
                [ class
                    [ FileBrowserFileLink
                    ]
                , Html.onClick (restoreSession file)
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
                    , fileLink (github "sample_pattern.json") "sample pattern"
                    ]
              ]
            , [ iconBig "close" <|
                    Maybe.withDefault (callbacks.lift NoOp) callbacks.clearSession
              ]
            , [ Html.div
                    [ class [ FileBrowserFileLinkWrapper ]
                    ]
                    ( List.map (\(label, file) ->
                        historyLink file label
                      )
                      ( List.concat
                        [ List.indexedMap (\i r ->
                              ("future " ++ toString i, r)
                          )
                          (List.reverse undoList.future)

                        , [("current", undoList.present)]

                        , List.indexedMap (\i r ->
                              ("past " ++ toString i, r)
                          )
                          undoList.past
                        ]
                      )
                    )
              ]
            , [ iconBig "undo" <|
                    Maybe.withDefault (callbacks.lift NoOp) callbacks.undo
              ]
            , [ iconBig "redo" <|
                    Maybe.withDefault (callbacks.lift NoOp) callbacks.redo
              ]
            ]
        )


github : String -> String
github fn =
    "https://raw.githubusercontent.com/kirchner/elm-pat/master/demo_patterns/" ++ fn
