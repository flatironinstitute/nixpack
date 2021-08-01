{
  system = builtins.currentSystem;
  os = "centos7";
  /* where to get the spack respository */
  spackGit = {
    /* default:
    url = "git://github.com/spack/spack";
    */
    ref = "develop";
    rev = "b4c6c11e689b2292a1411e4fc60dcd49c929246d";
    /*
    url = "git://github.com/flatironinstitute/spack";
    ref = "scc";
    */
  };
  /* extra config settings for spack itself */
  spackConfig = {
    config = {
      source_cache = "/mnt/home/spack/cache";
      build_jobs = 28; /* overridden by NIX_BUILD_CORES */
    };
  };
  /* which python to run spack with (currently needs to be system, but could be bootstrapped somehow) */
  spackPython = "/usr/bin/python3";
  global = {
    /* preferences to apply to every package -- generally not needed */
    tests = false;
  };
  package = {
    /* preferences for individual packages or virtuals */
    cpio = {
      extern = "/usr";
      version = "2.11";
    };
    openmpi = {
      version = "4.0";
    };
    mpi = {
      /* providers can be (optional) lists of names or { name; ...prefs } */
      provider = [ "openmpi" ];
    };
  };
  compiler = {
    /* preferences for global compiler */
    name = "gcc";
    version = "7.5.0";
  };
  /* must be set to an external compiler capable of building compiler (above) */
  bootstrapCompiler = {
    name = "gcc";
    version = "4.8.5";
    extern = "/usr";
  };
  repoPatch = {
    /* updates or additions to the spack repo (see patch.nix)
    package = [spec: [old:]] {
      new...
    };
    */
  };
}
