module SharedStyles exposing (..)

import Html.CssHelpers exposing (withNamespace)


type ToolbarClass
    = ToolbarMain
    | ToolbarButtonWrapper
    | ToolbarButton
    | ToolbarTooltip
    | ToolTextfield
    | ToolbarRow
    | ToolbarColumn
    | ToolbarIconButton


toolbarNamespace =
    withNamespace "toolbar"


{ id, class, classList } =
    toolbarNamespace
