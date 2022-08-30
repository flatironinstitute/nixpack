{ system ? builtins.currentSystem
, target ? builtins.head (builtins.split "-" system)
, nixpkgs
, overlays ? []
}:

let
# gcc arch is x64-64
target_ = builtins.replaceStrings ["x86_64"] ["x86-64"] target;

args = {
  localSystem = {
    inherit system;
    gcc = { arch = target_; };
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
  overlays = [(import ./overlay.nix)] ++ overlays;
};

in

import nixpkgs args
