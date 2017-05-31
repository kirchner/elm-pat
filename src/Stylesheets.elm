port module Stylesheets exposing (..)

import Css.File exposing (CssCompilerProgram, CssFileStructure)
import Tools.Styles
import View
import Styles.PointTable


port files : CssFileStructure -> Cmd msg


fileStructure : CssFileStructure
fileStructure =
    Css.File.toFileStructure
        [ ( "toolbar.css", Css.File.compile [ View.css ] )
        , ( "tools.css", Css.File.compile [ Tools.Styles.css ] )
        , ( "pointtable.css", Css.File.compile [ Styles.PointTable.css ] )
        ]


main : CssCompilerProgram
main =
    Css.File.compiler files fileStructure
