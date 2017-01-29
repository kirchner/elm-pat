let

  pkgs = import /nix/var/nix/profiles/per-user/root/channels/unstable {};

  stdenv = pkgs.stdenv;
  git    = pkgs.git;

  elm-compiler = pkgs.elmPackages.elm-compiler;
  elm-make     = pkgs.elmPackages.elm-make;
  elm-package  = pkgs.elmPackages.elm-package;
  elm-format   = pkgs.elmPackages.elm-format;

in rec {

  env = pkgs.buildEnv rec {
    name = "elm-pat";
    paths = [ stdenv git elm-compiler elm-make elm-package elm-format ];
    buildInputs = paths;
  };

}
