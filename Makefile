all:
	elm-make --output=gh-pages/elm.js src/App.elm
	elm-css --output gh-pages src/Stylesheets.elm
	cp static/index.html gh-pages/index.html
