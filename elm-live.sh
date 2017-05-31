#!/bin/bash

elm-live src/App.elm \
    --dir=gh-pages \
    --output=gh-pages/elm.js \
    --before-build=./before-build.sh
