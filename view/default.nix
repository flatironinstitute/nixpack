packs:
{ name ? (builtins.head pkgs).name + "-view"
, pkgs /* packages to include */
, exclude ? [] /* globs of files to exclude (all globs rooted at top) */
, shbang ? [] /* files for which to copy and translate #! paths to new root */
, wrap ? [] /* files to replace with executable wrapper "exec -a new old" */
, copy ? [] /* files to copy as-is (rather than link) */
, meta ? builtins.head pkgs /* behave as package in terms of modules and dependencies */
}:
derivation {
  inherit (packs) system;
  builder = packs.prefs.spackPython;
  args = [./builder.py];
  inherit name pkgs exclude shbang wrap copy;
  force = [".spack" ".nixpack.spec"];
  forcePkgs = [meta meta];
} // {
  inherit (meta) spec;
}
