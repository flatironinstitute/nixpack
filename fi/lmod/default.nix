packs: mods:
derivation {
  name = "lmodSite";
  inherit (mods) system;
  lmod = packs.pkgs.lmod;
  mods = "${mods}/${packs.platform}-${packs.os}-${packs.target}";
  cache = packs.lmodCache mods;
  src = ./.;
  builder = ./builder.sh;
}
