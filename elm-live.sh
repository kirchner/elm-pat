#!/bin/bash

elm-live src/Main.elm \
    --dir=gh-pages \
    --output=gh-pages/elm.js \
    --before-build=./before-build.sh \
    --warn

