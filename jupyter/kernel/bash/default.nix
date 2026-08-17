packs:
{ pkg
, name ? pkg.name
, jupyter
}:

derivation {
  __noChroot = true;
  inherit (packs) system;
  builder = ./builder.sh;
  inherit name pkg jupyter;
}
