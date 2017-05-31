port module Stylesheets exposing (..)

import Css.File exposing (CssCompilerProgram, CssFileStructure)
import Tools.Styles
import Styles.PointTable
import Styles.VariableTable
import Styles.ToolBox
import Styles.Editor
import Styles.Common


port files : CssFileStructure -> Cmd msg


fileStructure : CssFileStructure
fileStructure =
    Css.File.toFileStructure
        [ ( "tools.css", Css.File.compile [ Tools.Styles.css ] )
        , ( "common.css", Css.File.compile [ Styles.Common.css ] )
        , ( "editor.css", Css.File.compile [ Styles.Editor.css ] )
        , ( "point_table.css", Css.File.compile [ Styles.PointTable.css ] )
        , ( "variable_table.css", Css.File.compile [ Styles.VariableTable.css ] )
        , ( "tool_box.css", Css.File.compile [ Styles.ToolBox.css ] )
        ]


main : CssCompilerProgram
main =
    Css.File.compiler files fileStructure
