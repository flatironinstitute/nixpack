/* patches/additions for the repo */
lib:
let nocompiler = spec: old: { depends = old.depends or {} // { compiler = null; }; };
in
{
  /* add compiler paths */
  gcc = spec: {
    paths = {
      cc = lib.when spec.variants.languages.c "bin/gcc";
      cxx = lib.when spec.variants.languages."c++" "bin/g++";
      f77 = lib.when spec.variants.languages.fortran "bin/gfortran";
      fc = lib.when spec.variants.languages.fortran "bin/gfortran";
    };
  };
  llvm = {
    paths = {
      cc = "bin/clang";
      cxx = "bin/clang++";
      f77 = null;
      fc = null;
    };
  };
  openssh = {
    patches = [./openssh-keysign-setuid.patch];
  };

  /* some things don't use a compiler */
  intel = nocompiler;
  intel-mkl = nocompiler;
  intel-mpi = nocompiler;
  intel-oneapi-mkl = nocompiler;
  intel-oneapi-mpi = nocompiler;
  intel-oneapi-tbb = nocompiler;
}
