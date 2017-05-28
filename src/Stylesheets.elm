port module Stylesheets exposing (..)

import Css.File exposing (CssFileStructure, CssCompilerProgram)


{- internal -}

import View
import Tools.Styles


port files : CssFileStructure -> Cmd msg


fileStructure : CssFileStructure
fileStructure =
    Css.File.toFileStructure
        [ ( "toolbar.css", Css.File.compile [ View.css ] )
        , ( "tools.css", Css.File.compile [ Tools.Styles.css ] )
        ]


main : CssCompilerProgram
main =
    Css.File.compiler files fileStructure
