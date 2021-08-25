{ target ? "broadwell"
}:

let

lib = corePacks.lib;

isLDep = builtins.elem "link";
isRDep = builtins.elem "run";
isRLDep = d: isLDep d || isRDep d;

corePacks = import ./packs {
  label = "core";
  system = builtins.currentSystem;
  inherit target;
  os = "centos7";

  spackSrc = {
    url = "git://github.com/flatironinstitute/spack";
    ref = "fi-nixpack";
    rev = "3e5744d33f5188196874f164fb552101f292731e";
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
    resolver = deptype:
      if isRLDep deptype
        then null else corePacks;
  };
  sets = {
    bootstrap = {
      global = {
        resolver = null;
      };
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
    python = corePython;
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
      version = "1.42.0"; # newer builds are broken (meson #25355)
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
        #glx = false; # ~glx breaks gtkplus
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
    py-protobuf = {
      version = "3.15.7"; # newer have wrong hash (#25469)
    };
    py-h5py = {
      version = ":2";
    };
    boost = {
      variants = {
        context = true;
        coroutine = true;
        cxxstd = "14";
      };
    };
    nix = {
      variants = {
        storedir = builtins.getEnv "NIX_STORE_DIR";
        statedir = builtins.getEnv "NIX_STATE_DIR";
        sandboxing = false;
      };
    };
  }
  // blasVirtuals "openblas";
};

blasVirtuals = blas: {
  blas      = blas;
  lapack    = blas;
  scalapack = blas;
};

cuda_arch = { "35" = true; "60" = true; "70" = true; "80" = true; none = false; };

coreCompiler = {
  name = "gcc";
  resolver = "bootstrap";
};

mkCompilers = base: gen:
  builtins.map (compiler: gen (rec {
    inherit compiler;
    isCore = compiler == coreCompiler;
    packs = if isCore then base else
      base.withCompiler compiler;
    defaulting = pkg: { default = isCore; inherit pkg; };
  }))
  [
    coreCompiler
    { name = "gcc"; version = "10.2"; }
    # intel?
  ];

mkMpis = base: gen:
  builtins.map (mpi: gen {
    inherit mpi;
    packs = base.withPrefs {
      package = {
        inherit mpi;
      };
      global = {
        variants = {
          mpi = true;
        };
      };
      package = {
        fftw = {
          variants = {
            precision = {
              quad = false;
            };
          };
        };
      };
    };
    isOpenmpi = mpi.name == "openmpi";
  })
  [
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
        fabrics = {
          ucx = false;
        };
        internal-hwloc = true;
      };
    }
    { name = "intel-oneapi-mpi"; }
    { name = "intel-mpi"; }
  ];

withPython = packs: py: let
  /* we can't have multiple python versions in a dep tree because of spack's
     environment polution, but anything that doesn't need python at runtime 
     can fall back on default
    */
  ifHasPy = p: o: name: prefs:
    let q = p.getResolver name prefs; in
    if builtins.any (p: p.spec.name == "python") (lib.findDeps (x: isRLDep x.deptype) q)
      then q
      else o.getResolver name prefs;
  pyPrefs = resolver: {
    label = "${packs.label}.python";
    package = {
      python = py;
    };
    global = {
      inherit resolver;
    };
  };
  coreRes = ifHasPy corePyPacks corePacks;
  corePyPacks = corePacks.withPrefs (pyPrefs (deptype: coreRes));
  pyPacks = packs.withPrefs (pyPrefs 
    (deptype: if isRLDep deptype
      then ifHasPy pyPacks packs
      else coreRes));
  in pyPacks;

corePython = { version = "3.8"; };

mkPythons = base: gen:
  builtins.map (python: gen (rec {
    inherit python;
    isCore = python == corePython;
    packs = withPython base python;
    defaulting = pkg: { default = isCore; inherit pkg; };
  }))
  [
    corePython
    { version = "3.9"; }
  ];

pyView = pl: { pkgs ? [], ... } @ args: corePacks.pythonView (args // {
  pkgs = lib.findDeps (x: isRDep x.deptype && lib.hasPrefix "py-" x.name) pl ++ pkgs;
});

rView = corePacks.view {
  pkgs = lib.findDeps (x: isRDep x.deptype && lib.hasPrefix "r-" x.name) (with corePacks.pkgs; [
    r
    r-irkernel
    r-annotationdbi
    r-bh
    r-bsgenome
    r-biasedurn
    r-biocinstaller
    r-biocmanager
    r-deseq2
    r-dt
    #r-diffbind
    r-formula
    r-gostats
    r-gseabase
    r-genomicalignments
    r-genomicfeatures
    r-genomicranges
    r-iranges
    r-keggrest
    r-rbgl
    r-rcurl
    r-r-methodss3
    #r-rsoo
    #r-rsutils
    r-rcpparmadillo
    r-rcppeigen
    #r-rcppgsl
    r-rhdf5lib
    r-rsamtools
    r-rtsne
    r-tfmpvalue
    r-vgam
    #r-venndiagram
    r-acepack
    r-ade4
    r-askpass
    r-assertthat
    r-backports
    r-biomart
    r-biomformat
    r-bit64
    r-bitops
    r-blob
    r-catools
    r-callr
    r-checkmate
    r-cli
    r-clipr
    r-clisymbols
    r-crosstalk
    r-desc
    r-devtools
    r-dplyr
    r-evaluate
    r-formatr
    r-fs
    r-futile-logger
    r-futile-options
    r-gdata
    r-genefilter
    r-getopt
    r-ggplot2
    r-glmnet
    r-glue
    r-gplots
    #r-grimport
    r-gridextra
    r-gtools
    r-hexbin
    r-highr
    #r-huge
    r-hms
    r-htmltable
    r-httpuv
    #r-idr
    r-igraph
    r-ini
    r-jpeg
    r-knitr
    r-lambda-r
    r-later
    r-lattice
    r-latticeextra
    r-lazyeval
    r-limma
    r-markdown
    r-matrixstats
    r-memoise
    r-mime
    r-miniui
    r-multtest
    #r-nabor
    #r-pdsh
    r-pheatmap
    r-phyloseq
    r-pkgbuild
    r-pkgconfig
    r-pkgload
    r-plogr
    r-plotly
    r-png
    r-polynom
    r-powerlaw
    r-preprocesscore
    #r-preseqr
    r-processx
    r-progress
    r-promises
    r-ps
    #r-pulsar
    r-purrr
    r-randomforest
    r-rcmdcheck
    r-readr
    r-remotes
    r-rlang
    r-rprojroot
    r-rstudioapi
    r-rtracklayer
    r-segmented
    r-seqinr
    r-sessioninfo
    #r-sf #needs old proj
    r-shape
    r-shiny
    r-snow
    r-sourcetools
    r-sys
    r-tibble
    r-tidyr
    r-tidyselect
    r-units
    r-viridis
    r-whisker
    r-xfun
    r-xopen
    r-xtable
    r-yaml
    r-zlibbioc
  ]);
};

pkgStruct = {
  pkgs = with corePacks.pkgs; [
    { pkg = slurm;
      environment = {
        set = {
          CMD_WLM_CLUSTER_NAME = "slurm";
          SLURM_CONF = "/cm/shared/apps/slurm/var/etc/slurm/slurm.conf";
        };
      };
      projection = "{name}";
    }
    (llvm.withPrefs { version = "10"; })
    (llvm.withPrefs { version = "11"; })
    (llvm.withPrefs { version = "12"; })
    cmake
    cuda
    cudnn
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
    intel-mpi
    intel-oneapi-mkl
    intel-oneapi-mpi
    julia
    keepassxc
    lftp
    likwid
    mercurial
    mplayer
    mpv
    mupdf
    #nix #too old/broken
    node-js
    (node-js.withPrefs { version = ":12"; })
    nvhpc
    octave
    openjdk
    #pdftk #needs gcc java (gcj)
    perl
    petsc
    postgresql
    { pkg = rView;
      environment = {
        prepend_path = {
          R_LIBS_SITE = "{prefix}/rlib/R/library";
        };
      };
    }
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
  map (v: mathematica.withPrefs
    { version = v; extern = "/cm/shared/sw/pkg/vendor/mathematica/${v}"; })
    ["11.2" "11.3" "12.1" "12.2"]
  ++
  map (v: {
    pkg = matlab.withPrefs
      { version = v; extern = "/cm/shared/sw/pkg/vendor/matlab/${v}"; };
    environment = {
      set = {
        MLM_LICENSE_FILE = "/cm/shared/sw/pkg/vendor/matlab/src/network.lic";
      };
    };
  }) ["R2018a" "R2018b" "R2020a" "R2021a"]
  ;

  compilers = mkCompilers corePacks (comp: comp // {
    pkgs = with comp.packs.pkgs; [
      (comp.defaulting compiler)
      boost
      eigen
      (fftw.withPrefs { version = ":2"; variants = { precision = { long_double = false; quad = false; }; }; })
      fftw
      { pkg = gsl.withPrefs { depends = { blas = { name = "openblas"; variants = { threads = "none"; }; }; }; };
        projection = "{name}/{version}-openblas";
      }
      { pkg = gsl.withPrefs { depends = blasVirtuals "intel-oneapi-mkl"; };
        projection = "{name}/{version}-mkl";
      }
      (hdf5.withPrefs { version = ":1.8"; })
      hdf5
      magma
      nfft
      { pkg = openblas.withPrefs { variants = { threads = "none"; }; };
        projection = "{name}/{version}-single";
      }
      { pkg = openblas.withPrefs { variants = { threads = "openmp"; }; };
        projection = "{name}/{version}-openmp";
      }
      { pkg = openblas.withPrefs { variants = { threads = "pthreads"; }; };
        projection = "{name}/{version}-threaded";
      }
      pgplot

      { name = "openmpi-opa";
        static = {
          short_description = "Load openmpi4 for Omnipath fabric";
          environment_modifications = [
            [ "SetEnv" { name = "OMPI_MCA_pml"; value = "cm"; } ]
          ];
        };
        depends = { mpi = openmpi; };
        projection = "{name}/{^openmpi.version}";
      }
    ];

    mpis = mkMpis comp.packs (mpi: mpi // {
      pkgs = with mpi.packs.pkgs;
        lib.optionals mpi.isOpenmpi [ mpi.packs.pkgs.mpi ] # others are above, compiler-independent
        ++ [
          boost
          (fftw.withPrefs { version = ":2"; variants = { precision = { long_double = false; }; }; })
          fftw
          (hdf5.withPrefs { version = ":1.8"; })
          hdf5
          osu-micro-benchmarks
        ] ++
        lib.optionals comp.isCore (lib.optionals mpi.isOpenmpi [
          # these are broken with intel...
          gromacs
          relion
        ] ++ [
          ior
          petsc
          valgrind
        ]);

      pythons = mkPythons mpi.packs (py: py // {
        view = py.packs.pythonView { pkgs = with py.packs.pkgs; [
          py-mpi4py
          py-h5py
        ]; };
      });
    });

    pythons = mkPythons comp.packs (py: py // {
      view = with py.packs.pkgs; pyView [
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
        py-h5py
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
        #py-pyqt5 #install broken: tries to install plugins/designer to qt
      ] {};
      mkl = 
        let
          mklPacks = withPython (comp.packs.withPrefs # invert py/mkl prefs
              { package = blasVirtuals "intel-mkl"; }) # intel-oneapi-mkl not supported
            py.python;
        in
        # replaces python-blas-backend
        mklPacks.pythonView { pkgs = with mklPacks.pkgs; [
          py-numpy
          py-scipy
        ]; };
    });
  });

  clangcpp = rec {
    packs = corePacks.withPrefs {
      package = {
        compiler = {
          name = "llvm";
          resolver = corePacks;
        };
        boost = {
          variants = {
            clanglibcpp = true;
          };
        };
      };
    };
    pkgs = with packs.pkgs; [
      boost
    ];
  };

  nixpkgs = with corePacks.nixpkgs; [
    nix
    #vscode
  ];

  static = [

    { name = "modules-traditional";
      static = {
        short_description = "Make old modules available";
        has_modulepath_modifications = true;
        unlocked_paths = ["/cm/shared/sw/modules"];
      };
      projection = "{name}";
    }
  ];

};

getPkg = p: p.pkg or p;

modPkgs = with pkgStruct;
  pkgs
  ++
  builtins.concatMap (comp: with comp;
    pkgs
    ++
    builtins.concatMap (mpi: with mpi;
      pkgs
      ++
      builtins.map (py: {
        pkg = py.view;
        default = py.isCore;
        projection = "python-mpi/{^python.version}";
        #autoload = [comp.pythons[py].view]
      }) pythons
    ) mpis
    ++
    builtins.concatMap (py: with py; [
      { pkg = view;
        default = isCore;
      }
      { pkg = mkl;
        default = isCore;
        projection = "python-mkl/{^python.version}";
        autoload = [view];
      }
    ]) pythons
  ) compilers
  ++
  map (pkg: { inherit pkg; projection = "{name}/{version}-libcpp"; })
    clangcpp.pkgs
  ++
  map (p: builtins.parseDrvName p.name // { prefix = p; })
    nixpkgs
  ++
  static
;

jupyter = pyView (with corePacks.pkgs; [
    python
    py-jupyterhub
    py-jupyterlab
    py-batchspawner
    node-js
  ]) {
  name = "jupyter";
  pkgs = map (import jupyter/kernel corePacks) (
    with pkgStruct;
    builtins.concatMap (comp: with comp;
      builtins.concatMap (py: with py;
        let k = {
          pkg = view;
          prefix = "${py.packs.pkgs.python.name}-${py.packs.pkgs.compiler.name}";
          note = "${lib.specName py.packs.pkgs.python.spec}%${lib.specName py.packs.pkgs.compiler.spec}";
        }; in [
          k
          (k // { prefix = k.prefix + "-mkl"; note = k.note+"+mkl"; include = [mkl]; })
        ]
      ) pythons
    ) compilers
  );
};

in

corePacks // {
  inherit pkgStruct;

  mods = corePacks.modules {
    coreCompilers = map (p: p.pkgs.compiler) [
      corePacks
      corePacks.sets.bootstrap
      pkgStruct.clangcpp.packs
    ];
    config = {
      hierarchy = ["mpi"];
      hash_length = 0;
      projections = {
        # warning: order is lost
        "gromacs+plumed" = "{name}/{version}-plumed";
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
      py-mpi4py = {
        autoload = "direct";
      };
    };

    pkgs = modPkgs;

  };

  inherit jupyter;

  traceModSpecs = lib.traceSpecTree (builtins.concatMap (p:
    let q = getPkg p; in
    q.pkgs or (if q ? spec then [q] else [])) modPkgs);

}
