module SharedStyles exposing (..)

import Html.CssHelpers exposing (withNamespace)


type CssClasses
    = ToolBox


type CssIds
    = ToolBar


editorNamespace =
    withNamespace "editor"


{ id, class, classList } =
    editorNamespace
