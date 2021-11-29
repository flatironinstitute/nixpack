gitrev: packs: mods:
# this just wraps modules.nix in a directory/symlink layer for nix-env
derivation {
  name = "lmodSite";
  inherit (mods) system;
  mod = import ./modules.nix gitrev packs mods;
  src = ./.;
  builder = ./builder.sh;
}
