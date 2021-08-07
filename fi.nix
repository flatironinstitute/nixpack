let

cuda_arch = ["35" "60" "70" "80"];

packs = import ./packs {
  system = builtins.currentSystem;
  target = "broadwell";
  os = "centos7";

  spackSrc = {
    url = "git://github.com/flatironinstitute/spack";
    ref = "fi";
  };
  spackConfig = {
    config = {
      source_cache = "/mnt/home/spack/cache";
      build_jobs = 28;
    };
  };
  spackPython = "/usr/bin/python3";
  spackPath = "/bin:/usr/bin";

  repoPatch = {
  };

  global = {
    tests = false;
  };
  bootstrapCompiler = {
    name = "gcc";
    version = "4.8.5";
    extern = "/usr";
  };
  compiler = {
    name = "gcc";
  };
  package = {
    cpio = {
      /* some intel installers need this -- avoid compiler dependency */
      extern = "/usr";
      version = "2.11";
    };
    mpi = {
      provider = [ "openmpi" ];
    };
    blas      = { provider = "openblas"; };
    lapack    = { provider = "openblas"; };
    scalapack = { provider = "openblas"; };
    gcc = {
      version = "7";
    };
    mpfr = {
      version = "3.1.6";
    };
    binutils = {
      variants = {
        gold = true;
        ld = true;
      };
    };
    zstd = {
      variants = { multithread = false; };
    };
    cairo = {
      variants = {
        X = true;
        fc = true;
        ft = true;
        gobject = true;
        pdf = true;
        png = true;
        svg = false;
      };
    };
    py-setuptools-scm = {
      variants = {
        toml = true;
      };
    };
    slurm = {
      extern = "/cm/shared/apps/slurm/current";
      version = "20.02.5";
      variants = {
        sysconfdir = "/cm/shared/apps/slurm/var/etc/slurm";
        pmix = true;
        hwloc = true;
      };
    };
    intel-mpi = {
      # not available anymore...
      extern = "/cm/shared/sw/pkg/vendor/intel-pstudio/2017-4/compilers_and_libraries_2017.4.196/linux/mpi";
      version = "2017.4.196";
    };
    openmpi = {
      version = "4.0";
      variants = {
        fabrics = ["ofi" "ucx" "psm" "psm2" "verbs"];
        schedulers = "slurm";
        pmi = true;
        static = false;
        thread_multiple = true;
        legacylaunchers = true;
      };
    };
    ucx = {
      variants = {
        thread_multiple = true;
        cma = true;
        rc = true;
        dc = true;
        ud = true;
        mlx5-dv = true;
        ib-hw-tm = true;
      };
    };
    libfabric = {
      variants = {
        fabrics = ["udp" "rxd" "shm" "sockets" "tcp" "rxm" "verbs" "psm2" "psm" "mlx"];
      };
    };
    llvm = {
      version = "10";
    };
    openblas = {
      version = "0.3.15";
      variants = {
        threads = "pthreads";
      };
    };
    hdf5 = {
      version = "1.10";
      variants = {
        hl = true;
        fortran = true;
        cxx = true;
        mpi = false;
      };
    };
    fftw = {
      version = "3.3.9";
      variants = {
        mpi = false;
        precision = ["float" "double" "quad" "long_double"];
      };
    };
    py-torch = {
      variants = {
        inherit cuda_arch;
        mpi = false;
        valgrind = false;
      };
    };
    nccl = {
      variants = {
        inherit cuda_arch;
      };
    };
    magma = {
      variants = {
        inherit cuda_arch;
      };
    };
    relion = {
      variants = {
        inherit cuda_arch;
        mklfft = false;
      };
    };
    py-bind11 = {
      version = "2.6.2";
    };
    qt = {
      variants = {
        dbus = true;
        opengl = true;
      };
    };
    harfbuzz = {
      variants = {
        graphite2 = true;
      };
    };
    valgrind = {
      variants = {
        mpi = false;
      };
    };
    vtk = {
      variants = {
        mpi = false;
      };
    };
    r = {
      variants = {
        X = true;
      };
    };
  };

  fixedDeps = true;
};

compilers = [
  { name = "gcc"; version = "7"; }
  { name = "gcc"; version = "10.2"; }
  # intel?
];

compilerPacks = map (compiler: packs.withPrefs {
  inherit compiler;
  # todo: bootstrap with main compiler?
});

mpis = [
  { name = "openmpi"; version = "4.0"; }
  { name = "openmpi"; version = "2.1"; variants = {
    # openmpi 2 on ib reports: "unknown link width 0x10" and is a bit slow
    fabrics = ["ofi" "psm" "psm2" "verbs"];
  }; }
  { name = "openmpi"; version = "1.10"; variants = {
    # without the explicit fabrics ucx is lost in dependencies
    fabrics = ["ofi" "psm" "psm2" "verbs"];
  }; }
  { name = "intel-oneapi-mpi"; }
  { name = "intel-mpi"; }
];

pythons = [
  { name = "python"; verison = "3.8"; }
  { name = "python"; verison = "3.9"; }
];

modules = (map packs.getPackage compilers) ++ (with packs.pkgs; [
    (llvm.withPrefs { version = "10"; })
    (llvm.withPrefs { version = "11"; })
    (llvm.withPrefs { version = "12"; })
    cmake
    curl
    distcc
    (emacs.withPrefs { variants = { X = true; toolkit = "athena"; }; })
    fio
    gdal
    #gdb # needs python+debug
    ghostscript
    git
    git-lfs
    go
    gperftools
    (gromacs.withPrefs { variants = { mpi = false; }; })
    hdfview
    #i3 #needs some xcb things
    imagemagick
    julia
    keepassxc
    lftp
    likwid
    mercurial
    mplayer
    mpv
    mupdf
    node-js
    (node-js.withPrefs { version = ":12"; })
    (octave.withPrefs { variants = { openblas = false; }; })
    openjdk
    #pdftk #needs gcc java (gcj)
    perl
    (petsc.withPrefs { variants = { mpi = false; }; })
    postgresql
    r
    r-irkernel
    rclone
    rust
    singularity
    smartmontools
    subversion
    swig
    texlive
    texstudio
    tmux
    udunits
    unison
    valgrind
    (vim.withPrefs { variants = { features = "huge"; x = true; python = true; gui = true; cscope = true; lua = true; ruby = true; }; })
    vtk
    zsh
  ]);

in

packs // {
  modules = packs.modules { pkgs = modules; };
}
/*
let 
  testdeps = findDeps (x: builtins.elem "run" x.deptype) (with pkgs; [
    python
    py-cherrypy
    py-flask
    py-pip
    py-ipython
    py-pyyaml
    py-pylint
    py-autopep8
    py-sqlalchemy
    py-nose
    py-mako
    py-pkgconfig
    py-virtualenv
    py-sympy
    py-pycairo
    py-sphinx
    py-pytest
    py-hypothesis
    py-cython
    py-ipykernel
  ]);

  testview = pythonView { pkgs = testdeps; };
in
packs // {
  testdeps = map (x: x.name) testdeps;
  inherit testview;
  testmod = modules { pkgs = [testview]; };
}
*/
