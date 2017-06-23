let

  pkgs = import <nixpkgs> {};

  stdenv = pkgs.stdenv;
  git    = pkgs.git;

  elm-compiler = pkgs.elmPackages.elm-compiler;
  elm-make     = pkgs.elmPackages.elm-make;
  elm-package  = pkgs.elmPackages.elm-package;
  elm-format   = pkgs.elmPackages.elm-format;
  elm-repl     = pkgs.elmPackages.elm-repl;

in rec {

  elm-css =
    (import elm-css/default.nix {}).package;

  node2nix =
    pkgs.nodePackages.node2nix;

  env = pkgs.buildEnv rec {
    name = "elm-pat";
    paths = [ stdenv git elm-compiler elm-make elm-package elm-format elm-repl elm-css ];
    buildInputs = paths;
  };

}
