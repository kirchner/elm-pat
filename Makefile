build: elm-css/node-packages.nix
	nix-shell default.nix -A env --run "make all"

all:
	elm-make --yes --output=gh-pages/elm.js src/App.elm
	elm-css --output gh-pages src/Stylesheets.elm
	cp static/index.html gh-pages/index.html

clean:
	rm -rf elm-stuff/

elm-css/default.nix:
	nix-shell default.nix -A node2nix --run "(cd elm-css && node2nix)"
