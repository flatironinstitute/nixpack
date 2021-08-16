/* patches/additions for the repo */
lib:
let nocompiler = spec: old: { depends = old.depends or {} // { compiler = null; }; };
in
{
  /* compiler pseudo-virtual */
  compiler = ["gcc" "llvm"];

  /* add compiler paths, providers */
  gcc = spec: old: {
    provides = old.provides or {} // {
      compiler = ":";
    };
    paths = {
      cc = lib.when spec.variants.languages.c "bin/gcc";
      cxx = lib.when spec.variants.languages."c++" "bin/g++";
      f77 = lib.when spec.variants.languages.fortran "bin/gfortran";
      fc = lib.when spec.variants.languages.fortran "bin/gfortran";
    };
  };
  llvm = spec: old: {
    provides = old.provides or {} // {
      compiler = ":";
    };
    paths = {
      cc = "bin/clang";
      cxx = "bin/clang++";
      f77 = null;
      fc = null;
    };
  };

  openssh = {
    /* disable installing with setuid */
    patches = [./openssh-keysign-setuid.patch];
  };

  shadow = {
    /* disable installing with set[ug]id */
    patches = [./shadow-nosuid.patch];
  };

  git-lfs = {
    build = {
      # don't use home for GOCACHE
      setup = ''
        os.environ['GOCACHE'] = os.path.join(os.environ['TMPDIR'], 'go-cache')
      '';
    };
  };

  /* some things don't use a compiler */
  intel = nocompiler;
  intel-mkl = nocompiler;
  intel-mpi = nocompiler;
  intel-oneapi-mkl = nocompiler;
  intel-oneapi-mpi = nocompiler;
  intel-oneapi-tbb = nocompiler;
  cuda = nocompiler;
  cudnn = nocompiler;
}
