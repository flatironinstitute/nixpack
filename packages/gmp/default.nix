packs:
args:
with packs;
with args;

let
  versionHashes = {
    "6.2.1" = "eae9326beb4158c386e39a356818031bd28f3124cf915f8c5b1dc4c7a36b4d7c";
    "6.1.2" = "5275bb04f4863a13516b2f39392ac5e272f5e1bb8057b18aec1c9b79d73d8fb2";
  };
in {
  name = "gmp";
  version = versionKeys versionHashes;
  cc = {};
  autoconf = {};
  automake = {};
  libtool = {};
  m4 = {};
  build = {
    src = builtins.fetchurl {
      url = "https://ftpmirror.gnu.org/gmp/gmp-${version}.tar.bz2";
      sha256 = versionHashes.${version};
    };
    buildDeps = [cc];# autoconf automake libtool];
  };
}
