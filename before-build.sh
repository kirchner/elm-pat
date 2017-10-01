#!/bin/bash

mkdir -p ./gh-pages
sass static/pat.scss > gh-pages/pat.css
cp static/index.html gh-pages/index.html
