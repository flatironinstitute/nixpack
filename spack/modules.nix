packs:
{ name ? "modules"
, modtype ? "lmod" /* lmod or tcl */
, config ? {}
, pkgs /* packages to include */
, coreCompilers ? [packs.pkgs.compiler]
, static ? {}
}:
let
pkgSpec = p: p.spec // { prefix = p.out; };
renderPkgs = pkgs: builtins.toJSON (map pkgSpec pkgs);
in
packs.spackBuilder {
  args = [./modules.py];
  inherit name modtype;
  config = builtins.toJSON config;
  pkgs = renderPkgs pkgs;
  coreCompilers = renderPkgs coreCompilers;
  static = builtins.toJSON static;
  passAsFile = ["config" "pkgs" "coreCompilers" "static"];
}
