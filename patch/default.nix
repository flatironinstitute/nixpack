/* patches/additions for the repo */
lib:
let
  nocompiler = spec: old: { depends = old.depends or {} // { compiler = null; }; };
  tmphome = {
    build = {
      setup = ''
        os.environ['HOME'] = os.environ['TMPDIR']
      '';
    };
  };
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
    depends = old.depends // {
      compiler = { deptype = ["build"]; };
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
    depends = old.depends // {
      compiler = { deptype = ["build"]; };
    };
  };

  openssh = {
    /* disable installing with setuid */
    patches = [./openssh-keysign-setuid.patch];
  };

  nix = {
    patches = [./nix-ignore-fsea.patch];
  };

  shadow = {
    /* disable installing with set[ug]id */
    patches = [./shadow-nosuid.patch];
  };

  util-linux = {
    build = {
      enable_makeinstall_setuid = "no";
    };
  };

  librsvg = {
    build = {
      /* tries to install into gdk-pixbuf -- TODO: patch and use GDK_PIXBUF_MODULE_FILE (like nixpkgs) */
      enable_pixbuf_loader = "no";
    };
  };

  py-cryptography = {
    build = {
      setup = ''
        os.environ['CARGO_HOME'] = os.path.join(os.environ['TMPDIR'], 'cargo')
      '';
    };
  };

  /* tries to set ~/.gitconfig */
  r-credentials = tmphome;
  r-gert = tmphome;

  paraview = spec: old: {
    /* without explicit libx11 dep, ends up linking system libX11 (perhaps via system libGL) and not working */
    depends = old.depends // {
      libx11 = {
        deptype = ["link"];
      };
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
  ghostscript-fonts = nocompiler;
}
