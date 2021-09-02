packs:
with packs;
packs.spackBuilder {
  name = "nixpack-spack-bin.py";
  builder = ./bin.sh;
  inherit spackNixLib spack;
  SPACK_PYTHON = spackPython;
  withRepos = true;
}
