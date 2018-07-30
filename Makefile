all:
	elm-make --output=gh-pages/elm.js src/Main.elm
	sass static/pat.scss gh-pages/pat.css
	cp static/index.html gh-pages/index.html

clean:
	rm -rf elm-stuff/
