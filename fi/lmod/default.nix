packs: mods:
let
  build = modonly: derivation {
    name = if modonly then "modules.lua" else "lmodSite";
    inherit (mods) system;
    mod = if modonly then null else build true;
    lmod = packs.pkgs.lmod;
    mods = "${mods}/${packs.platform}-${packs.os}-${packs.target}";
    cache = packs.lmodCache mods;
    src = ./.;
    builder = ./builder.sh;
  };
in
build false
