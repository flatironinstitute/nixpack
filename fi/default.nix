{ target ? "broadwell"
}:

let

lib = corePacks.lib;

isLDep = builtins.elem "link";
isRDep = builtins.elem "run";
isRLDep = d: isLDep d || isRDep d;

corePacks = import ../packs {
  label = "core";
  system = builtins.currentSystem;
  os = "centos7";

  spackSrc = {
    url = "git://github.com/flatironinstitute/spack";
    ref = "fi-nixpack";
    rev = "96c6bbddf13a97de9aa12d5c4cb3432b79f44116";
  };

  spackConfig = {
    config = {
      source_cache = "/mnt/home/spack/cache";
    };
  };
  spackPython = "/usr/bin/python3";
  spackPath = "/bin:/usr/bin";

  nixpkgsSrc = {
    ref = "release-21.05";
    rev = "8ecb35368aacb62d7d3de5ae2a3a1aa0432cfd76";
  };

  repos = [
    ./repo
    ../spack/repo
  ];

  global = {
    inherit target;
    tests = false;
    fixedDeps = true;
    variants = {
      mpi = false;
    };
    resolver = deptype:
      if isRLDep deptype
        then null else corePacks;
  };
  package = {
    compiler = bootstrapPacks.pkgs.gcc;

    aocc = {
      variants = {
        license-agreed = true;
      };
    };
    binutils = {
      variants = {
        gold = true;
        ld = true;
      };
    };
    boost = {
      variants = {
        context = true;
        coroutine = true;
        cxxstd = "14";
      };
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
    cpio = { # some intel installers need this -- avoid compiler dependency
      extern = "/usr";
      version = "2.11";
    };
    cuda = {
      version = "11.3";
    };
    docbook-xml = { # for gtk-doc
      version = "4.3";
    };
    docbook-xsl = {
      version = "1.78.1";
    };
    fftw = {
      version = "3.3.9";
      variants = {
        precision = ["float" "double" "quad" "long_double"];
      };
    };
    freetype = { # for vtk
      version = ":2.10.2";
    };
    gcc = {
      version = "7";
    };
    gsl = {
      variants = {
        external-cblas = true;
      };
    };
    harfbuzz = {
      variants = {
        graphite2 = true;
      };
    };
    hdf5 = {
      version = "1.10";
      variants = {
        hl = true;
        fortran = true;
        cxx = true;
      };
    };
    intel-mpi = { # not available anymore...
      extern = "/cm/shared/sw/pkg/vendor/intel-pstudio/2017-4/compilers_and_libraries_2017.4.196/linux/mpi";
      version = "2017.4.196";
    };
    libepoxy = {
      variants = {
        #glx = false; # ~glx breaks gtkplus
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
    magma = {
      variants = {
        inherit cuda_arch;
      };
    };
    mpfr = {
      version = "3.1.6";
    };
    mpi = corePacks.pkgs.openmpi;
    nccl = {
      variants = {
        inherit cuda_arch;
      };
    };
    nix = {
      variants = {
        storedir = builtins.getEnv "NIX_STORE_DIR";
        statedir = builtins.getEnv "NIX_STATE_DIR";
        sandboxing = false;
      };
    };
    ocaml = {
      /* for unison */ variants = {
        force-safe-string = false;
      };
    };
    openblas = {
      version = "0.3.15";
      variants = {
        threads = "pthreads";
      };
    };
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
        schedulers = {
          none = false;
          slurm = true;
        };
        pmi = true;
        static = false;
        thread_multiple = true;
        legacylaunchers = true;
      };
    };
    pango = {
      version = "1.42.0"; # newer builds are broken (meson #25355)
      variants = {
        X = true;
      };
    };
    petsc = {
      variants = {
        hdf5 = false;
        hypre = false;
        superlu-dist = false;
      };
    };
    psm = bootstrapPacks.pkgs.psm; # needs old gcc
    py-h5py = {
      version = "3.1";
    };
    py-pybind11 = {
      version = "2.6.2";
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
    py-setuptools-scm = {
      variants = {
        toml = true;
      };
    };
    py-torch = {
      variants = {
        inherit cuda_arch;
        valgrind = false;
      };
    };
    python = corePython;
    qt = {
      variants = {
        dbus = true;
        opengl = true;
      };
    };
    r = {
      variants = {
        X = true;
      };
    };
    relion = {
      variants = {
        inherit cuda_arch;
        mklfft = false;
      };
    };
    shadow = {
      extern = "/usr";
      version = "4.6";
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
    visit = {
      variants = {
        python = false; # needs python2
      };
    };
    zstd = {
      variants = {
        multithread = false;
      };
    };
  }
  // blasVirtuals { name = "flexiblas"; };

  repoPatch = {
    openmpi = spec: {
      patches =
        lib.optionals (spec.version == "1.10.7")                  [ ./openmpi-1.10.7.PATCH ] ++
        lib.optionals (lib.versionAtMostSpec spec.version "1.10") [ ./openmpi-1.10-gcc.PATCH ] ++
        lib.optionals (spec.version == "2.1.6")                   [ ./openmpi-2.1.6.PATCH ];
      build = {
        setup = ''
          configure_args = pkg.configure_args()
          configure_args.append('CPPFLAGS=-I/usr/include/infiniband')
          pkg.configure_args = lambda: configure_args
        '';
        post = ''
          mca_conf_path = os.path.join(pkg.prefix.etc, "openmpi-mca-params.conf")
          with open(mca_conf_path, 'a') as f:
              f.write("""
          oob_tcp_if_exclude = idrac,lo,ib0
          btl_tcp_if_exclude = idrac,lo,ib0

          btl_openib_if_exclude = i40iw0,i40iw1,mlx5_1
          btl_openib_warn_nonexistent_if = 0
          """)
              if spec.satisfies("@4.0:"):
                  f.write("""
          #btl_openib_receive_queues=P,128,2048,1024,32:S,2048,2048,1024,64:S,12288,2048,1024,64:S,65536,2048,1024,64
          btl=^openib,usnix
          mtl=^psm,ofi
          pml=ucx
          pml_ucx_tls=any
          """)
        '';
      };
    };
  };
};

bootstrapPacks = corePacks.withPrefs {
  label = "bootstrap";
  global = {
    target = "haswell";
    resolver = null;
  };
  package = {
    compiler = {
      name = "gcc";
      version = "4.8.5";
      extern = "/usr";
    };

    autoconf = {
      extern = "/usr";
      version = "2.69";
    };
    automake = {
      extern = "/usr";
      version = "1.13.4";
    };
    bzip2 = {
      extern = "/usr";
      version = "1.0.6";
    };
    diffutils = {
      extern = "/usr";
      version = "3.3";
    };
    libtool = {
      extern = "/usr";
      version = "2.4.2";
    };
    m4 = {
      extern = "/usr";
      version = "1.4.16";
    };
    ncurses = {
      extern = "/usr";
      version = "5.9.20130511";
      variants = {
        termlib = true;
        abi = "5";
      };
    };
    openssl = {
      extern = "/usr";
      version = "1.0.2k";
      variants = {
        fips = false;
      };
    };
    perl = {
      extern = "/usr";
      version = "5.16.3";
    };
    pkgconfig = {
      extern = "/usr";
      version = "0.27.1";
    };
    psm = {};
    zlib = {
      extern = "/usr";
      version = "1.2.7";
    };
  };
};

blasVirtuals = blas: {
  blas      = blas;
  lapack    = blas;
  scalapack = blas;
};

cuda_arch = { "60" = true; "70" = true; "80" = true; none = false; };

mkCompilers = base: gen:
  builtins.map (compiler: gen (rec {
    inherit compiler;
    isCore = compiler == corePacks.pkgs.compiler;
    packs = if isCore then base else
      base.withCompiler compiler;
    defaulting = pkg: { default = isCore; inherit pkg; };
  }))
  [
    corePacks.pkgs.compiler
    (corePacks.pkgs.gcc.withPrefs { version = "10.2"; })
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

flexiBlases = {
  openblas = {
    FLEXIBLAS_LIBRARY_PATH = "/lib";
    FLEXIBLAS              = "/lib/libopenblas.so";
  };
  intel-mkl = {
    FLEXIBLAS_LIBRARY_PATH = "/mkl/lib/intel64";
    FLEXIBLAS              = "/mkl/lib/intel64/libmkl_rt.so";
  };
  intel-oneapi-mkl = {
    FLEXIBLAS_LIBRARY_PATH = "/mkl/latest/lib/intel64";
    FLEXIBLAS              = "/mkl/latest/lib/intel64/libmkl_rt.so";
  };
};

blasPkg = pkg: {
  inherit pkg;
  environment = {
    set = builtins.mapAttrs (v: path: "{prefix}" + path) flexiBlases.${pkg.spec.name};
  };
  postscript = ''
    family("blas")
  '';
};

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

pyView = pl: corePacks.pythonView {
  pkgs = lib.findDeps (x: isRDep x.deptype && lib.hasPrefix "py-" x.name) pl;
};

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
    #rstudio?
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
    aocc
    blast-plus
    cmake
    cuda
    cudnn
    curl
    disBatch
    distcc
    (emacs.withPrefs { variants = { X = true; toolkit = "athena"; }; })
    fio
    flexiblas
    gdal
    (gdb.withPrefs { fixedDeps = false; })
    ghostscript
    git
    git-lfs
    go
    gperftools
    { pkg = gromacs.withPrefs { variants = { cuda = true; }; };
      projection = "{name}/{version}-singlegpu";
    }
    (hdfview.withPrefs { fixedDeps = false; })
    imagemagick
    (blasPkg intel-mkl)
    (blasPkg (intel-mkl.withPrefs { version = "2017.4.239"; }))
    intel-mpi
    intel-oneapi-compilers
    (blasPkg intel-oneapi-mkl)
    intel-oneapi-mpi
    intel-oneapi-vtune
    julia
    keepassxc
    lftp
    libzmq
    likwid
    mercurial
    mplayer
    mpv
    mupdf
    nccl
    #nix #too old/broken
    node-js
    (node-js.withPrefs { version = ":12"; })
    nvhpc
    octave
    openjdk
    openmm
    #pdftk #needs gcc java (gcj)
    perl
    petsc
    postgresql
    qt
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
    #visit #needs qt <= 5.14.2
    vtk
    #xscreensaver
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
  ++
  map (v: {
    pkg = intel-parallel-studio.withPrefs
      { inherit (v) version; extern = "/cm/shared/sw/pkg/vendor/intel-pstudio/${v.path}"; };
    environment = {
      set = {
        INTEL_LICENSE_FILE = "28518@lic1.flatironinstitute.org";
      };
    }; }) [
      { version = "cluster.2017.4"; path = "2017-4"; }
      { version = "cluster.2019.0"; path = "2019"; }
      { version = "cluster.2019.3"; path = "2019-3"; }
      { version = "cluster.2020.0"; path = "2020"; }
      { version = "cluster.2020.4"; path = "2020-4"; }
    ]
  ;

  compilers = mkCompilers corePacks (comp: comp // {
    pkgs = with comp.packs.pkgs; [
      (comp.defaulting compiler)
      arpack-ng
      boost
      eigen
      ffmpeg
      (fftw.withPrefs { version = ":2"; variants = { precision = { long_double = false; quad = false; }; }; })
      fftw
      gsl
      gmp
      (hdf5.withPrefs { version = "1.8"; })
      hdf5 # default 1.10
      (hdf5.withPrefs { version = "1.12"; })
      healpix-cxx
      hwloc
      libdrm
      magma
      mesa
      mpc
      mpfr
      netcdf-c
      nfft
      (blasPkg (openblas.withPrefs { variants = { threads = "none"; }; }) // {
        projection = "{name}/{version}-single";
      })
      (blasPkg (openblas.withPrefs { variants = { threads = "openmp"; }; }) // {
        projection = "{name}/{version}-openmp";
      })
      (blasPkg (openblas.withPrefs { variants = { threads = "pthreads"; }; }) // {
        projection = "{name}/{version}-threaded";
      })
      pgplot
      ucx

      { name = "openmpi-opa";
        context = {
          short_description = "Load openmpi4 for Omnipath fabric";
        };
        environment = {
          set = {
            "OMPI_MCA_pml" = "cm";
          };
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
        py-pycuda
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
        py-numpy
        py-scipy
        py-yt
        #py-pyqt5 #install broken: tries to install plugins/designer to qt
      ];
    });
  });

  clangcpp = rec {
    packs = corePacks.withPrefs {
      package = {
        compiler = corePacks.pkgs.llvm;
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
    elinks
    #evince
    feh
    #gimp
    #git
    #i3-env
    #inkscape
    #jabref
    #keepassx2
    #libreoffice
    #meshlab
    #pass
    #pdftk
    #rxvt-unicode
    #sage
    #slack
    vscode
    #wecall
    xscreensaver
  ];

  static = [
    {
      name = "cuda-dcgm";
      prefix = "/cm/local/apps/cuda-dcgm/current";
      projection = "{name}";
    }
    {
      name = "fdcache";
      environment = {
        prepend_path = {
          LD_PRELOAD = "/cm/shared/sw/pkg/flatiron/fdcache/src/libfdcache.so";
        };
      };
      projection = "{name}";
    }
    {
      name = "gpfs";
      prefix = "/usr/lpp/mmfs";
      projection = "{name}";
    }
    { name = "jupyter-kernels";
      prefix = "/cm/shared/sw/pkg/flatiron/jupyter-kernels";
      environment = {
        prepend_path = {
          PYTHONPATH = "{prefix}/bin";
        };
      };
      context = {
        short_description = "Tools to manage custom jupyter kernels";
      };
      projection = "{name}";
    }
    { name = "modules-traditional";
      context = {
        short_description = "Make old modules available";
        has_modulepath_modifications = true;
        unlocked_paths = ["/cm/shared/sw/modules"];
      };
      projection = "{name}";
    }
  ];

};

# missing things:
#  amd/aocl
#  amd/uprof
#  pvfmm, stkfmm: robert
#  triqs/...
#  py jaxlib cuda
#  py deadalus mpi: robert

jupyterBase = pyView (with corePacks.pkgs; [
  python
  py-jupyterhub
  py-jupyterlab
  py-batchspawner
  node-js
]);

jupyter = jupyterBase.extendView (
  map (import ../jupyter/kernel corePacks) (
    with pkgStruct;
    builtins.concatMap (comp: with comp;
      builtins.concatMap (py: with py;
        let k = {
          pkg = view;
          prefix = "${py.packs.pkgs.python.name}-${py.packs.pkgs.compiler.name}";
          note = "${lib.specName py.packs.pkgs.python.spec}%${lib.specName py.packs.pkgs.compiler.spec}";
        }; in [
          (k // {
            env = builtins.mapAttrs (var: path:
              py.packs.pkgs.openblas + path) flexiBlases.openblas;
          })
          (k // {
            prefix = k.prefix + "-mkl";
            note = k.note+"+mkl";
            env = builtins.mapAttrs (var: path:
              py.packs.pkgs.intel-oneapi-mkl + path) flexiBlases.intel-oneapi-mkl;
          })
        ]
      ) pythons
    ) compilers
    ++
    [
      { pkg = rView;
        kernelSrc = import ../jupyter/kernel/ir corePacks {
          pkg = rView;
          jupyter = jupyterBase;
        };
        prefix = "${rView.name}";
        note = "${lib.specName rView.spec}";
        env = {
          R_LIBS_SITE = "${rView}/rlib/R/library";
        };
      }
    ]
  )
);

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
    ]) pythons
  ) compilers
  ++
  map (pkg: { inherit pkg; projection = "{name}/{version}-libcpp"; })
    clangcpp.pkgs
  ++
  [ { pkg = jupyter;
      projection = "jupyterhub";
    }
  ]
  ++
  map (p: builtins.parseDrvName p.name // {
    prefix = p;
    context = {
      short_description = p.meta.description or null;
      long_description = p.meta.longDescription or null;
    };
  })
    nixpkgs
  ++
  static
;

in

corePacks // {
  inherit pkgStruct;

  mods = corePacks.modules {
    coreCompilers = map (p: p.pkgs.compiler) [
      corePacks
      bootstrapPacks
      pkgStruct.clangcpp.packs
    ];
    config = {
      hierarchy = ["mpi"];
      hash_length = 0;
      projections = {
        # warning: order is lost
        "gromacs+plumed" = "{name}/{version}-plumed";
      };
      prefix_inspections = {
        "" = ["{name}_BASE"];
      };
      all = {
        autoload = "none";
        prerequisites = "direct";
        suffixes = {
          "^mpi" = "mpi";
        };
        filter = {
          environment_blacklist = ["CC" "FC" "CXX" "F77"];
        };
      };
      boost = {
        environment = {
          set = {
            BOOST_ROOT = "{prefix}";
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
      openmpi = {
        environment = {
          set = {
            OPENMPI_VERSION = "{version}";
          };
        };
      };
      py-mpi4py = {
        autoload = "direct";
      };
    };

    pkgs = modPkgs;

  };

  inherit bootstrapPacks jupyter;

  traceModSpecs = lib.traceSpecTree (builtins.concatMap (p:
    let q = p.pkg or p; in
    q.pkgs or (if q ? spec then [q] else [])) modPkgs);
}
