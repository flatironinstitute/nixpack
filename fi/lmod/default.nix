packs:
derivation {
  inherit (packs.prefs) system;
  name = "lmodSite";
  site = ./SitePackage.lua;
  builder = ./builder.sh;
}
