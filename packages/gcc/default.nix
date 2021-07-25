packs:
with packs;
args:
with args;

{
  name = "gcc";
  version = ["7.5.0" "11.1.0" "10.3.0"];
  withBinutils = false;
  cc = {};
  gmp = { version = "4.3.2:"; };
  mpfr = { version = if lib.versionMatches version ":9.9" then "2.4.2:3.1.6" else "3.1.0:"; };
  binutils = if withBinutils then { withGas = true; withLd = true; withPlugins = true; withLibiberty = false; } else null;
  build = {
    runDeps = [cc gmp];
  };
}
