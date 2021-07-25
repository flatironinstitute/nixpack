packs:
args:
with packs;
with args;

{
  name = "autotools";
  version = "";
  m4 = {};
  autoconf = {};
  automake = {};
  libtool = {};
  force_autoreconf = false;
  build = {
    #runDeps = [m4 autoconf automake libtool];
    phases = "install";
    buildSrc = ./builder.sh;
    install = ''
      mkdir -p $out
      cp $buildSrc $out/builder.sh
    '';
  };
}
