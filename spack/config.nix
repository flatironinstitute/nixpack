packs: config: derivation ({
  inherit (packs.prefs) system;
  name = "spackConfig";
  builder = ./config.sh;
  sections = builtins.attrNames config;
} // builtins.mapAttrs (n: v: builtins.toJSON { "${n}" = v; }) config)
