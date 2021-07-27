{
  system = builtins.currentSystem;
  os = "centos7";
  spackGit = {
    rev = "4a19741a3681e6dcae5d35a22be1a7aa95022a13";
  };
  spackConfig = {
    config = {
      source_cache = "/mnt/home/spack/cache";
      build_jobs = 28; /* overridden by NIX_BUILD_CORES */
    };
  };
  compiler = "gcc";
  global = {};
}
