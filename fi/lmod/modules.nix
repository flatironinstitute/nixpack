gitrev: packs: mods:
# a simple modules.lua meta-module for adding modules
derivation {
  name = "modules.lua";
  inherit (mods) system;
  mods = "${mods}/${packs.platform}-${packs.os}-${packs.target}";
  src = ./modules.lua;
  git = gitrev;
  builder = ./modules.sh;
}
