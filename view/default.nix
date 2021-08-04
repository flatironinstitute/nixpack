packs:
{ name
, pkgs /* packages to include */
, exclude ? [] /* globs of files to exclude (all globs rooted at top) */
, shbang ? ["bin/*"] /* files for which to copy and translate #! paths to new root */
, wrap ? ["bin/python*"] /* files to replace with executable wrapper "exec -a new old" */
, copy ? null /* files to copy as-is (rather than link) */
}:
derivation {
  inherit (packs) system;
  builder = packs.prefs.spackPython;
  args = [./builder.py];
  inherit name shbang wrap copy;
  exclude = [".spack" ".nixpack.spec"] ++ exclude;
  src = pkgs;
}
