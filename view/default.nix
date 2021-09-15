packs:
packs.lib.fix (makeView:
{ name ? (builtins.head pkgs).name + "-view"
, pkgs /* packages to include */
, exclude ? [] /* globs of files to exclude (all globs rooted at top) */
, shbang ? [] /* files for which to copy and translate #! paths to new root */
, jupyter ? [] /* files for which to translate argv[0] to new root */
, wrap ? [] /* files to replace with executable wrapper "exec -a new old" */
, copy ? [] /* files to copy as-is (rather than link) */
, ignoreConflicts ? [] /* files for which to ignore any conflicts (first package wins) */
, meta ? builtins.head pkgs /* behave as package in terms of modules and dependencies */
} @ args:
derivation {
  inherit (packs) system;
  builder = packs.prefs.spackPython;
  args = [./builder.py];
  inherit name pkgs exclude shbang jupyter wrap copy ignoreConflicts;
  force = [".spack" ".nixpack.spec"];
  forcePkgs = [meta meta];
} // rec {
  inherit (meta) spec;
  overrideView = a: makeView (args // a);
  extendView = p: overrideView { pkgs = pkgs ++ p; };
})
