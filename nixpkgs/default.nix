{ system ? builtins.currentSystem
, target ? builtins.head (builtins.split "-" system)
, src ? {}
, overlays ? []
}:

let

nixpkgs = fetchGit ({
  url = "git://github.com/NixOS/nixpkgs";
  ref = "master";
} // src);

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
  overlays = [(import ./overlay.nix)] ++ overlays;
};

in

import nixpkgs args
