packs:
{ pkg
, name ? pkg.name
, jupyter
}:

derivation {
  __noChroot = true;
  inherit (packs) system;
  builder = ./builder.sh;
  rBuilder = ./builder.R;
  name = "jupyter-kernel-ir-${name}";
  inherit pkg jupyter;
}
