packs:
{ name ? "modules"
, modtype ? "lmod" /* lmod or tcl */
, config ? {}
, pkgs /* packages to include, list of:
   pkg (spack derivation)
   { pkg = pkg; default = true; } (for default module)
   { pkg = pkg; environment = { ... }; projection = "{name}/{version}"; } (overrides config)
   { name = "name"; static = "content"; }
   { name = "name"; static = { template variables }; }
   */
, coreCompilers ? [packs.pkgs.c]
}:
let
jsons = {
  inherit config pkgs coreCompilers;
};
in
packs.spackBuilder ({
  args = [./modules.py];
  inherit name modtype;
  withRepos = true;
  enableParallelBuilding = false; # broken in some cases
} // builtins.mapAttrs (name: builtins.toJSON) jsons // {
  passAsFile = builtins.attrNames jsons;
}) // jsons
