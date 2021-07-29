{
  system = builtins.currentSystem;
  os = "centos7";
  /* where to get the spack respository */
  spackGit = {
    /* default:
    url = "git://github.com/spack/spack";
    */
    rev = "4a19741a3681e6dcae5d35a22be1a7aa95022a13";
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
  };
  package = {
    /* preferences for individual packages:
    */
  };
  compiler = {
    /* preferences for global compiler */
    name = "gcc";
    version = "7.5.0";
  };
  bootstrapCompiler = {
    name = "gcc";
    version = "4.8.5";
    extern = "/usr";
  };
  providers = {
    /* global preferences for virtual providers */
    mpi = [ {
        name = "openmpi";
        version = "4.0,1.0";
      }
    ];
  };
}
