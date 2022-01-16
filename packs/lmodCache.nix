packs:
src:
derivation (packs.spackEnv // {
  inherit (packs) system;
  name = "lmodCache";
  builder = ./lmodCache.sh;
  lmod = packs.pkgs.lmod;
  MODULEPATH = "${src}/${packs.platform}-${packs.os}-${packs.target}/Core";
})
