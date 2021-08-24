{ system ? builtins.currentSystem
, target ? builtins.head (builtins.split "-" system)
}:

let

nixpkgs = fetchGit {
  url = "git://github.com/NixOS/nixpkgs";
  ref = "master";
  rev = "72bab23841f015aeaf5149a4e980dc696c59d7ca";
};

args = {
  localSystem = {
    inherit system;
    gcc = { arch = target; };
  };
  config = {
    replaceStdenv = import ./stdenv.nix;
    nix = {
      storeDir = builtins.getEnv "NIX_STORE_DIR";
      stateDir = builtins.getEnv "NIX_STATE_DIR";
    };
    allowUnfree = true;
    cudaSupport = true;
  };
  overlays = [(import ./overlay.nix)];
};

in

import nixpkgs args
