packs:
{ name ? "modules"
, modtype ? "lmod" /* lmod or tcl */
, config ? {}
, pkgs /* packages to include */
, coreCompilers ? [packs.pkgs.compiler]
, defaults ? []
, static ? {}
}:
let
jsons = {
  inherit config pkgs coreCompilers defaults static;
};
in
packs.spackBuilder ({
  args = [./modules.py];
  inherit name modtype;
} // builtins.mapAttrs (name: builtins.toJSON) jsons // {
  passAsFile = builtins.attrNames jsons;
})
