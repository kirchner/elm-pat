port module Stylesheets exposing (..)

import Css.File exposing (CssFileStructure, CssCompilerProgram)
import EditorCss as Editor


port files : CssFileStructure -> Cmd msg


fileStructure : CssFileStructure
fileStructure =
    Css.File.toFileStructure
        [ ( "editor.css", Css.File.compile [ Editor.css ] ) ]


main : CssCompilerProgram
main =
    Css.File.compiler files fileStructure
