port module Stylesheets exposing (..)

import Css.File exposing (CssFileStructure, CssCompilerProgram)


{- internal -}

import View
import Tools.Absolute


port files : CssFileStructure -> Cmd msg


fileStructure : CssFileStructure
fileStructure =
    Css.File.toFileStructure
        [ ( "toolbar.css", Css.File.compile [ View.css ] )
        , ( "absolute.css", Css.File.compile [ Tools.Absolute.css ] )
        ]


main : CssCompilerProgram
main =
    Css.File.compiler files fileStructure
