#!/bin/bash

elm-css --output gh-pages src/Stylesheets.elm
cp static/index.html gh-pages/index.html
