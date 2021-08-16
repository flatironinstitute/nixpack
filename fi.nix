let

lib = rootPacks.lib;

rootPacks = import ./packs {
  system = builtins.currentSystem;
  target = "broadwell";
  os = "centos7";

  spackSrc = {
    url = "git://github.com/flatironinstitute/spack";
    ref = "fi-nixpack";
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
    fixedDeps = true;
    variants = {
      mpi = false;
    };
  };
  sets = {
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
  };
  package = {
    compiler = coreCompiler;
    gcc = {
      version = "7";
    };
    mpfr = {
      version = "3.1.6";
    };
    cpio = {
      /* some intel installers need this -- avoid compiler dependency */
      extern = "/usr";
      version = "2.11";
    };
    mpi = "openmpi";
    openmpi = {
      version = "4.0";
      variants = {
        fabrics = {
          none = false;
          ofi = true;
          ucx = true;
          psm = true;
          psm2 = true;
          verbs = true;
        };
        schedulers = { none = false; slurm = true; };
        pmi = true;
        static = false;
        thread_multiple = true;
        legacylaunchers = true;
      };
    };
    blas      = "openblas";
    lapack    = "openblas";
    scalapack = "openblas";
    openblas = {
      version = "0.3.15";
      variants = {
        threads = "pthreads";
      };
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
    hdf5 = {
      version = "1.10";
      variants = {
        hl = true;
        fortran = true;
        cxx = true;
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
    py-pybind11 = {
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
          version = ":5";
        };
      };
    };
    shadow = {
      extern = "/usr";
      version = "4.6";
    };
    petsc = {
      variants = {
        hdf5 = false;
        hypre = false;
        superlu-dist = false;
      };
    };
    py-pyqt5 = {
      depends = {
        py-sip = {
          variants = {
            module = "PyQt5.sip";
          };
        };
      };
    };
  };
};

coreCompiler = {
  name = "gcc";
  resolver = "bootstrap";
};

compilers = [
  coreCompiler
  { name = "gcc"; version = "10.2"; }
  # intel?
];

mpis = [
  { name = "openmpi"; }
  { name = "openmpi";
    version = "2.1";
    variants = {
      # openmpi 2 on ib reports: "unknown link width 0x10" and is a bit slow
      fabrics = {
        ucx = false;
      };
      internal-hwloc = true;
    };
  }
  { name = "openmpi";
    version = "1.10";
    variants = {
      # without the explicit fabrics ucx is lost in dependencies
      fabrics = {
        ucx = false;
      };
      internal-hwloc = true;
    };
  }
  { name = "intel-oneapi-mpi"; }
  { name = "intel-mpi"; }
];

pythons = [
  { version = "3.8"; }
  { version = "3.9"; }
];

pyView = pl: rootPacks.pythonView { pkgs = rootPacks.findDeps (x: builtins.elem "run" x.deptype) pl; };

cuda_arch = { "35" = true; "60" = true; "70" = true; "80" = true; none = false; };

mods =
  # externals
  (with rootPacks.pkgs; [
    slurm
  ]
  ++
  map (v: mathematica.withPrefs
    { version = v; extern = "/cm/shared/sw/pkg/vendor/mathematica/${v}"; })
    ["11.2" "11.3" "12.1" "12.2"]
  ++
  map (v: matlab.withPrefs
    { version = v; extern = "/cm/shared/sw/pkg/vendor/matlab/${v}"; })
    ["R2018a" "R2018b" "R2020a" "R2021a"])
  ++
  # for each compiler
  builtins.concatMap (compiler:
    let
      isCore = compiler == coreCompiler;
      ifCore = lib.optionals isCore;
      compPacks = if isCore then rootPacks else
        rootPacks.withCompiler compiler;
    in
    [ (rootPacks.getPackage compiler) ]
    ++
    (with compPacks.pkgs;
    ifCore [
      (llvm.withPrefs { version = "10"; })
      (llvm.withPrefs { version = "11"; })
      (llvm.withPrefs { version = "12"; })
      cmake
      curl
      disBatch
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
      gromacs
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
      petsc
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
    ]
    ++
    [
      boost
      cuda
      cudnn
      eigen
      (fftw.withPrefs { version = ":2"; variants = { precision = { long_double = false; quad = false; }; }; })
      fftw
      (gsl.withPrefs { depends = { blas = { name = "openblas"; variants = { threads = "none"; }; }; }; })
      (gsl.withPrefs { depends = { blas = "intel-oneapi-mkl"; }; })
      (hdf5.withPrefs { version = ":1.8"; })
      hdf5
      magma
      nfft
      (openblas.withPrefs { variants = { threads = "none"; }; })
      (openblas.withPrefs { variants = { threads = "openmp"; }; })
      (openblas.withPrefs { variants = { threads = "pthreads"; }; })
      pgplot
      relion # doesn't work with intel-mpi, so just use default openmpi
      openmpi-opa # (default) openmpi/4 only
    ])
    ++
    builtins.concatMap (mpi:
      let mpiPacks = compPacks.withPrefs {
        package = {
          inherit mpi;
        };
        global = {
          variants = {
            mpi = true;
          };
        };
      };
      in
      [ (compPacks.getPackage mpi) ]
      ++
      (with mpiPacks.pkgs; [
        boost
        (fftw.withPrefs { version = ":2"; variants = { precision = { long_double = false; quad = false; }; }; })
        (fftw.withPrefs { variants = { precision = { quad = false; }; }; })
        (hdf5.withPrefs { version = ":1.8"; })
        hdf5
        osu-micro-benchmarks
      ] ++
      ifCore [
        #gromacs # broken with intel-oneapi-mpi?
        ior
        petsc
        valgrind
      ])) mpis
    ++
    map (py:
      let pyPacks = compPacks.withPackage "python" py;
      in
      pyView (with pyPacks.pkgs; [
        python
        python-blas-backend # python-blas-backend is a custom package that includes scipy/numpy
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
        (py-h5py.withPrefs { version = ":2"; variants = { mpi = false; }; })
        py-torch
        py-ipykernel
        py-pandas
        py-scikit-learn
        py-emcee
        py-astropy
        py-dask
        py-seaborn
        py-matplotlib
        py-numba
      ] ++
      ifCore [
        py-pyqt5
      ])) pythons
    ++
    ifCore (let
      clangPacks = compPacks.withCompiler {
        name = "llvm";
        variants = { clanglibcpp = true; };
      };
    in with clangPacks.pkgs; [
      boost
    ])
  ) compilers
  ++
  [
    /*
    { name = "openmpi-opa";
      static = {
        short_description = "Load openmpi4 for Omnipath fabric";
        environment_modifications = [
          [ "SetEnv" { name = "OMPI_MCA_pml"; value = "cm"; } ]
        ];
        # prereq: openmpi/4?
      };
    }
    */
    { name = "modules-traditional";
      static = {
        short_description = "Make old modules available";
        has_modulepath_modifications = true;
        unlocked_paths = ["/cm/shared/sw/modules"];
      };
    }
  ];

in

rootPacks // { mods =
rootPacks.modules {
  config = {
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
    };
    all = {
      autoload = "none";
      prerequisites = "direct";
      environment = {
        set = {
          "{name}_BASE" = "{prefix}";
        };
      };
      suffixes = {
        "^mpi" = "mpi";
      };
      filter = {
        environment_blacklist = ["CC" "FC" "CXX" "F77"];
      };
    };
    openmpi = {
      environment = {
        set = {
          OPENMPI_VERSION = "{version}";
        };
      };
    };
    openmpi-opa = {
      environment = {
        set = {
          OMPI_MCA_pml = "cm";
        };
      };
    };
    matlab = {
      environment = {
        set = {
          MLM_LICENSE_FILE = "/cm/shared/sw/pkg/vendor/matlab/src/network.lic";
        };
      };
    };
    slurm = {
      environment = {
        set = {
          CMD_WLM_CLUSTER_NAME = "slurm";
          SLURM_CONF = "/cm/shared/apps/slurm/var/etc/slurm/slurm.conf";
        };
      };
    };
    hdf5 = {
      environment = {
        set = {
          HDF5_ROOT = "{prefix}";
        };
      };
    };
    boost = {
      environment = {
        set = {
          BOOST_ROOT = "{prefix}";
        };
      };
    };
  };

  pkgs = mods;

};
}
