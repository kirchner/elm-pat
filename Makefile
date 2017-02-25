build: src/*.elm
	mkdir -p build
	elm-make --yes src/Main.elm --output build/elm.js

dist-web: build
	mkdir -p gh-pages
	cp build/elm.js        gh-pages
	cp static/html/*.html  gh-pages

dist: dist-web

clean:
	rm -rf build

dist-clean: clean
	rm -rf elm-stuff
	rm -rf gh-pages/*
