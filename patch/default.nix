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
  /* nipack can't deal with the conditional dependencies in LuaPackage so just censor luajit for now (should really depend on variant setting) */
  noluajit = spec: old: {
    depends = removeAttrs old.depends ["lua-luajit" "lua-luajit-openresty"];
  };
  cargohome = {
    build = {
      setup = ''
        os.environ['CARGO_HOME'] = os.path.join(os.environ['TMPDIR'], 'cargo')
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
    compiler_spec = "clang";
  };

  nvhpc = spec: old: {
    provides = old.provides or {} // {
      compiler = ":";
    };
  };

  aocc = spec: old: {
    paths = {
      cc = "bin/clang";
      cxx = "bin/clang++";
      f77 = "bin/flang";
      fc = "bin/flang";
    };
    depends = old.depends // {
      compiler = null;
      llvm = {
        # uses llvm package
        deptype = ["build"];
      };
    };
  };

  apptainer = spec: old: {
    depends = old.depends // {
      # imports package
      singularityce = { deptype = ["build"]; };
    };
  };

  intel-oneapi-compilers = spec: old: {
    compiler_spec = "oneapi"; # can be overridden as "intel" with prefs
    provides = old.provides or {} // {
      compiler = ":";
    };
  };

  intel-parallel-studio = spec: old: {
    compiler_spec = "intel@19.1.3.304"; # version may need correcting
    provides = old.provides or {} // {
      compiler = ":";
    };
    depends = old.depends or {} // {
      compiler = null;
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
    build = cargohome.build // {
      /* tries to install into gdk-pixbuf -- TODO: patch and use GDK_PIXBUF_MODULE_FILE (like nixpkgs) */
      enable_pixbuf_loader = "no";
    };
  };

  py-cryptography = cargohome;
  py-maturin = cargohome;
  py-rpds-py = cargohome;
  py-ruff = cargohome;

  /* for pdflatex */
  r = {
    build = {
      setup = ''
        os.environ['TEXMFVAR'] = os.path.join(os.environ['TMPDIR'], 'texmf')
      '';
    };
  };
  /* tries to set ~/.gitconfig */
  r-credentials = tmphome;
  r-gert = tmphome;

  /* creates various cache stuff */
  npm = tmphome;

  /* uses npm */
  py-jupyter-server = tmphome;
  py-jupyter-server-proxy = tmphome;
  py-jupyterlmod = tmphome;
  py-ipyparallel = tmphome;

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

  git-lfs = spec: old: {
    build = {
      setup = ''
        os.environ['GOPATH'] = os.path.join(os.environ['TMPDIR'], 'gopath')
        os.environ['GOCACHE'] = os.path.join(os.environ['TMPDIR'], 'gocache')
      '';
    };
  };

  go = spec: old: {
    build = {
      setup = ''
        os.environ['GOCACHE'] = os.path.join(os.environ['TMPDIR'], 'go-cache')
      '';
    };
  };

  rust = spec: old: {
    build = cargohome.build // {
      # workaround for https://github.com/rust-lang/cargo/issues/10303
      CARGO_NET_GIT_FETCH_WITH_CLI = "true";
    };
  };

  vtk = spec: old: {
    depends = old.depends // {
      # imports package
      boost = { deptype = ["build"]; };
    };
  };

  /* some things don't use a compiler */
  intel-mkl = nocompiler;
  intel-mpi = nocompiler;
  intel-oneapi-mkl = nocompiler;
  intel-oneapi-mpi = nocompiler;
  intel-oneapi-tbb = nocompiler;
  cuda = nocompiler;
  cudnn = nocompiler;
  ghostscript-fonts = nocompiler;
  matlab = nocompiler;
  mathematica = nocompiler;

  lua-bit32 = noluajit;
  lua-bitlib = noluajit;
  lua-lpeg = noluajit;
  lua-luafilesystem = noluajit;
  lua-luaposix = noluajit;
  lua-mpack = noluajit;
  lua-sol2 = noluajit;
}
