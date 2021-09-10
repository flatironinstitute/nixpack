packs:
{ pkg
, name ? pkg.name
, jupyter
}:

derivation {
  inherit (packs) system;
  builder = ./builder.sh;
  inherit name pkg jupyter;
}
