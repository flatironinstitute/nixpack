packs:
derivation {
  inherit (packs.prefs) system;
  name = "lmodPackage";
  site = ./SitePackage.lua;
  builder = ./builder.sh;
}
