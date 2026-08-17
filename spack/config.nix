packs: config: derivation ({
  __noChroot = true;
  inherit (packs.prefs) system;
  name = "spackConfig";
  builder = ./config.sh;
  sections = builtins.attrNames config;
} // builtins.mapAttrs (n: v: builtins.toJSON { "${n}" = v; }) config
  // packs.spackEnv)
