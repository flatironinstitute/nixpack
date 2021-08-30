packs:
with packs;
derivation {
  name = "nixpack-spack-bin.py";
  builder = ./bin.sh;
  inherit system os spackNixLib spack spackConfig spackCache;
  PATH = spackPath;
  SPACK_PYTHON = spackPython;
}
