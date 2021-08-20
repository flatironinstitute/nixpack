packs:
{ name ? "modules"
, modtype ? "lmod" /* lmod or tcl */
, config ? {}
, pkgs /* packages to include, list of:
   pkg (spack derivation)
   { pkg = pkg; default = true; } (for default module)
   { static = "content"; name = "name"; }
   { static = { template variables }; name = "name"; }
   */
, coreCompilers ? [packs.pkgs.compiler]
}:
let
jsons = {
  inherit config pkgs coreCompilers;
};
in
packs.spackBuilder ({
  args = [./modules.py];
  inherit name modtype;
} // builtins.mapAttrs (name: builtins.toJSON) jsons // {
  passAsFile = builtins.attrNames jsons;
})
