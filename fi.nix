let

cuda_arch = {"35" = true; "60" = true; "70" = true; "80" = true; none = false; };

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

  tests = false;
  fixedDeps = true;

  bootstrap = {
    package = {
      compiler = {
        name = "gcc";
        version = "4.8.5";
        extern = "/usr";
      };
      zlib = {
        extern = "/usr";
        version = "1.2.7";
      };
      diffutils = {
        extern = "/usr";
        version = "3.3";
      };
      bzip2 = {
        extern = "/usr";
        version = "1.0.6";
      };
      perl = {
        extern = "/usr";
        version = "5.16.3";
      };
      m4 = {
        extern = "/usr";
        version = "1.4.16";
      };
      libtool = {
        extern = "/usr";
        version = "2.4.2";
      };
      autoconf = {
        extern = "/usr";
        version = "2.69";
      };
      automake = {
        extern = "/usr";
        version = "1.13.4";
      };
      openssl = {
        extern = "/usr";
        version = "1.0.2k";
        variants = {
          fips = false;
        };
      };
      ncurses = {
        extern = "/usr";
        version = "5.9.20130511";
        variants = {
          termlib = true;
          abi = "5";
        };
      };
    };
  };
  package = {
    compiler = {
      name = "gcc";
      resolver = "bootstrap";
    };
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
    pango = {
      variants = {
        X = true;
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
        schedulers = ["slurm"];
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
        #opengl = true;
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
    /* for gtk-doc */
    docbook-xml = {
      version = "4.3";
    };
    docbook-xsl = {
      version = "1.78.1";
    };
    libepoxy = {
      variants = {
        glx = false;
      };
    };
    /* for unison */
    ocaml = {
      variants = {
        force-safe-string = false;
      };
    };
    /* for vtk */
    freetype = {
      version = ":2.10.2";
    };
    netcdf-c = {
      variants = {
        mpi = false;
      };
    };
    gsl = {
      variants = {
        external-cblas = true;
      };
    };
    cuda = {
      version = "11.3";
    };
    psm = {
      depends = {
        compiler = {
          name = "gcc";
          version = ":5.99";
        };
      };
    };
  };
};

compilers = [
  { name = "gcc"; version = "7"; }
  { name = "gcc"; version = "10.2"; }
  # intel?
];

compilerPacks = map (compiler: packs.withPrefs {
  package = {
    inherit compiler;
    # todo: bootstrap with main compiler?
  };
}) compilers;

mpis = [
  { name = "openmpi"; version = "4.0"; }
  { name = "openmpi"; version = "2.1"; variants = {
    # openmpi 2 on ib reports: "unknown link width 0x10" and is a bit slow
    fabrics = ["ofi" "psm" "psm2" "verbs"];
    internal-hwloc = true;
  }; }
  { name = "openmpi"; version = "1.10"; variants = {
    # without the explicit fabrics ucx is lost in dependencies
    fabrics = ["ofi" "psm" "psm2" "verbs"];
    internal-hwloc = true;
  }; }
  { name = "intel-oneapi-mpi"; }
  { name = "intel-mpi"; }
];

pythons = [
  { name = "python"; version = "3.8"; }
  { name = "python"; version = "3.9"; }
];

mods = (map packs.getPackage compilers) ++ (with packs.pkgs; [
  (llvm.withPrefs { version = "10"; })
  (llvm.withPrefs { version = "11"; })
  (llvm.withPrefs { version = "12"; })
  cmake
  curl
  distcc
  (emacs.withPrefs { variants = { X = true; toolkit = "athena"; }; })
  fio
  gdal
  (gdb.withPrefs { fixedDeps = false; })
  ghostscript
  git
  git-lfs
  go
  gperftools
  (gromacs.withPrefs { variants = { mpi = false; }; })
  (hdfview.withPrefs { fixedDeps = false; })
  #i3 #needs some xcb things
  imagemagick
  intel-mkl
  intel-oneapi-mkl
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
  nvhpc
  octave
  openjdk
  #pdftk #needs gcc java (gcj)
  perl
  (petsc.withPrefs { variants = { mpi = false; hdf5 = false; hypre = false; superlu-dist = false; }; })
  postgresql
  r
  r-irkernel
  rclone
  rust
  singularity
  smartmontools
  subversion
  swig
  (texlive.withPrefs { fixedDeps = false; })
  (texstudio.withPrefs { fixedDeps = false; })
  tmux
  udunits
  unison
  valgrind
  (vim.withPrefs { variants = { features = "huge"; x = true; python = true; gui = true; cscope = true; lua = true; ruby = true; }; })
  vtk
  zsh
  # externs:
  slurm
] ++ map (v: mathematica.withPrefs
    { version = v; extern = "/cm/shared/sw/pkg/vender/mathematica/${v}"; })
  ["11.2" "11.3" "12.1" "12.2"]
  ++ map (v: matlab.withPrefs
    { version = v; extern = "/cm/shared/sw/pkg/vender/matlab/${v}"; })
  ["R2018a" "R2018b" "R2020a" "R2021a"]
) ++ builtins.concatMap (packs: with packs.pkgs; 
  map packs.getPackage (mpis ++ pythons) ++ [
  boost
  cuda
  cudnn
  eigen
  (fftw.withPrefs { version = ":2"; variants = { precision = { long_double = false; quad = false; }; }; })
  fftw
  (gsl.withPrefs { depends = { blas = { provider = { name = "openblas"; variants = { threads = "none"; }; }; }; }; })
  (gsl.withPrefs { depends = { blas = { provider = "intel-oneapi-mkl"; }; }; })
  (hdf5.withPrefs { version = ":1.8"; })
  hdf5
  magma
  nfft
  (openblas.withPrefs { variants = { threads = "none"; }; })
  (openblas.withPrefs { variants = { threads = "openmp"; }; })
  (openblas.withPrefs { variants = { threads = "pthreads"; }; })
  pgplot
  relion # doesn't work with intel-mpi, so just use default openmpi
  openmpi-opa # ^openmpi@4.0.6 fabrics=ofi,ucx,psm,psm2,verbs schedulers=slurm +pmi~static+thread_multiple+legacylaunchers
]) compilerPacks ++ (with packs.pkgs; [
  (boost.withPrefs { depends = { compiler = { provider = "clang"; }; }; variants = { clanglibcpp = true; }; })
]);

modconfig = {
  hierarchy = ["mpi"];
  hash_length = 0;
  projections = {
    "boost+clanglibcpp" = "{name}/{version}-libcpp";
    "gromacs+plumed" = "{name}/{version}-plumed";
    "gsl^intel-oneapi-mkl" = "{name}/{version}-mkl";
    "gsl^openblas" = "{name}/{version}-openblas";
    "openblas threads=none" = "{name}/{version}-single";
    "openblas threads=openmp" = "{name}/{version}-openmp";
    "openblas threads=pthreads" = "{name}/{version}-threaded";
    "openmpi-opa" = "{name}/{^openmpi.version}";
    "py-*^intel-oneapi-mkl" = "python-packages/{^python.version}/{name}/.{version}-mkl";
    "py-*^openblas" = "python-packages/{^python.version}/{name}/.{version}-openblas";
    "python-blas-backend^intel-oneapi-mkl" = "python/{^python.version}-mkl";
    "slurm" = "{name}/current";
    "py-*^python" = "python-packages/{^python.version}/{name}/{version}";
    "modules-traditional" = "{name}";
  };
};

in

packs // {
  inherit compilerPacks;
  modules = packs.modules {
    config = modconfig;
    pkgs = mods;
  };
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
