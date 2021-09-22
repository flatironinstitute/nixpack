packs:
src:
derivation {
  inherit (packs) system;
  name = "lmodCache";
  builder = ./lmodCache.sh;
  PATH = packs.spackPath;
  lmod = packs.pkgs.lmod;
  MODULEPATH = "${src}/${packs.platform}-${packs.os}-${packs.target}/Core";
}
