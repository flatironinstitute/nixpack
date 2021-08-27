packs:
{ pkg
, name ? pkg.name
, jupyter
}:

derivation {
  inherit (packs) system;
  builder = ./builder.sh;
  rBuilder = ./builder.R;
  name = "jupyter-kernel-ir-${name}";
  inherit pkg jupyter;
}
