packs:
{ pkg
, kernelSrc ? pkg
, include ? []
, env ? {}
, prefix ? pkg.name
, note ? ""
}:

derivation {
  inherit (packs) system;
  builder = packs.prefs.spackPython;
  args = [./builder.py];
  name = "${pkg.name}-kernel";
  inherit pkg kernelSrc include prefix note;
  env = builtins.toJSON env;
}
