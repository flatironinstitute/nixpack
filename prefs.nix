{
  system = builtins.currentSystem;
  target = "broadwell";
  os = "centos7";
  /* where to get the spack respository. Can also be a path (string) to an
     existing spack install, however this will eliminate the dependency and
     break purity, and can cause your repo metadata to get out of sync,
     so is not recommended for production. */
  spackSrc = {
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
    mpfr = {
      version = "3.1.6";
    };
    zstd = {
      variants = { multithread = false; };
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
  /* how to resolve dependencies, similar to concretize together or separately.
     dynamic = true:  Each package is resolved dynamically based on preferences
       and constraints imposed by its dependers.  This can result in many
       different versions of each package existing in packs.
     dynamic = false:  Packages are resolved only by user prefs, and an error
       is produced if dependencies don't conform to their dependers
       constraints.  This ensures only one version of each dependent package
       exists within packs.  Different packs with different prefs may have
       different versions.  Top-level packages explicitly resolved with
       different prefs or dependency prefs may also be different.
   */
  dynamic = false;
}
