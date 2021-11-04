/* patches/additions for the repo */
packs:
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
      # gcc bin detection is non-deterministic
      cc = packs.lib.when spec.variants.languages.c "bin/gcc";
      cxx = packs.lib.when spec.variants.languages."c++" "bin/g++";
      f77 = packs.lib.when spec.variants.languages.fortran "bin/gfortran";
      fc = packs.lib.when spec.variants.languages.fortran "bin/gfortran";
    };
    depends = old.depends // {
      compiler = { deptype = ["build"]; };
    };
    build = {
      # make cc -> gcc symlink
      post = ''
        os.symlink('gcc', os.path.join(pkg.prefix, 'bin/cc'))
      '';
    };
  };

  llvm = spec: old: {
    depends = old.depends // {
      compiler = { deptype = ["build"]; };
    };
  };

  nvhpc = spec: old: {
    provides = old.provides or {} // {
      compiler = ":";
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

  emacs = spec: old: {
    depends = old.depends // {
      fontconfig = {
        deptype = ["build" "link"];
      };
      libxft = {
        deptype = ["build" "link"];
      };
      libjansson = {
        deptype = ["build" "link"];
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
