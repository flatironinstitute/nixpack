{ target ? "broadwell"
, cudaarch ? "60,70,80"
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
    rev = "6456ed7be176d5ceb254b7aa932cf9b1baa9d7c0";
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
    rev = "276671abd104e83ba7cb0b26f44848489eb0306b";
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
    /* any runtime dependencies use the current packs, others fall back to core */
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
        openmp = true;
        precision = ["float" "double" "quad" "long_double"];
      };
    };
    freetype = { # for vtk
      version = ":2.10.2";
    };
    gcc = {
      version = "7";
    };
    gdbm = {
      # for perl
      version = "1.19";
    };
    /* external opengl:
    gl = {
      name = "opengl";
    };
    glx = {
      name = "opengl";
    }; */
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
      variants = {
        pythonbind = true;
      };
    };
    magma = {
      variants = {
        inherit cuda_arch;
      };
    };
    mpfr = {
      version = "3.1.6";
    };
    mpi = {
      name = "openmpi";
    };
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
    opengl = {
      version = "4.6";
      extern = "/usr";
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
    paraview = {
      variants = {
        python3 = true;
        qt = true;
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
    py-botocore = {
      version = "1.19.52"; # for aiobotocore
    };
    py-h5py = {
      version = "3.1";
    };
    py-jax = {
      variants = {
        inherit cuda_arch;
      };
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
      depends = blasVirtuals { name = "openblas"; }; # doesn't find flexiblas
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
    trilinos = {
      variants = {
        openmp = true;
        cuda = false;
        cxxstd = "14";
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
    py-jax = {
      build = {
        setup = ''
          os.environ['TEST_TMPDIR'] = os.path.join(os.environ['TMPDIR'], 'bazel-cache')
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

cuda_arch = { none = false; } // builtins.listToAttrs
  (map (a: { name = a; value = true; })
    (if builtins.isString cudaarch then lib.splitRegex "," cudaarch else cudaarch));

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
    isCore = mpi == { name = "openmpi"; };
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
     can fall back on default */
  ifHasPy = p: o: name: prefs:
    let q = p.getResolver name prefs; in
    if builtins.any (p: p.spec.name == "python") (lib.findDeps (x: isRLDep x.deptype) q)
      then q
      else o.getResolver name prefs;
  pyPacks = packs.withPrefs {
    label = "${packs.label}.python";
    package = {
      python = py;
    };
    global = {
      resolver = deptype: ifHasPy pyPacks
        (if isRLDep deptype
          then packs
          else corePacks);
    };
  };
  in pyPacks;

corePython = { version = "3.8"; };

mkPythons = base: gen:
  builtins.map (python: gen (rec {
    inherit python;
    isCore = python == corePython;
    packs = withPython base python;
  }))
  [
    corePython
    { version = "3.9"; }
  ];

pyView = pl: corePacks.pythonView {
  pkgs = lib.findDeps (x: lib.hasPrefix "py-" x.name) pl;
};

rView = corePacks.view {
  pkgs = lib.findDeps (x: lib.hasPrefix "r-" x.name) (import ./r.nix corePacks);
};

hdf5Pkgs = packs: with packs.pkgs; [
  (hdf5.withPrefs { version = "1.8"; })
  { pkg = hdf5; # default 1.10
    default = true;
  }
  (hdf5.withPrefs { version = "1.12"; })
];

/* packages that we build both with and without mpi */
optMpiPkgs = packs: with packs.pkgs; [
  boost
  (fftw.withPrefs { version = "2"; variants = { precision = { long_double = false; quad = false; }; }; })
  fftw
] ++ hdf5Pkgs packs;

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
    (gcc.withPrefs { version = "11"; })
    aocc
    blast-plus
    cmake
    cuda
    cudnn
    curl
    { pkg = disBatch.withPrefs { version = "1"; };
      default = true;
    }
    (disBatch.withPrefs { version = "2"; })
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
    magma
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
    #paraview #broken?
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
      eigen
      ffmpeg
      gsl
      gmp
      healpix-cxx
      #hwloc
      #libdrm
      #magma
      #mesa
      mpc
      mpfr
      netcdf-c
      nfft
      nlopt
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
    ] ++
    optMpiPkgs comp.packs;

    mpis = mkMpis comp.packs (mpi: mpi // {
      pkgs = with mpi.packs.pkgs;
        lib.optionals mpi.isOpenmpi ([
          mpi.packs.pkgs.mpi # others are above, compiler-independent
        ] ++
          /* static mpi env modules */
          map (p: p // {
            depends = {
              inherit (mpi.packs.pkgs) compiler mpi;
            };
            projection = "{name}/{^openmpi.version}";
          }) ([
            { name = "openmpi-intel";
              context = {
                short_description = "Set openmpi to use Intel compiler (icc)";
              };
              environment = {
                set = {
                  OMPI_CC = "icc";
                  OMPI_CXX = "icpc";
                  OMPI_FC = "ifort";
                  OMPI_F77 = "ifort";
                };
              };
            }
          ]
          ++
          lib.optionals (lib.versionMatches mpi.packs.pkgs.mpi.spec.version "4") [
            { name = "openmpi-opa";
              context = {
                short_description = "Set openmpi4 for Omnipath fabric";
              };
              environment = {
                set = {
                  "OMPI_MCA_pml" = "cm";
                };
              };
            }
          ])
        )
        ++ [
          osu-micro-benchmarks
        ] ++
        optMpiPkgs mpi.packs
        ++
        lib.optionals mpi.isCore [
          pvfmm
          stkfmm
          trilinos
          (trilinos.withPrefs { version = "12.18.1"; })
        ]
        ++
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
        pkgs = lib.optionals (py.isCore && mpi.isCore) (with py.packs.pkgs; [
          triqs
          triqs-cthyb
          triqs-dft-tools
          triqs-maxent
          triqs-omegamaxent-interface
          triqs-tprf
        ]);
      });
    });

    pythons = mkPythons comp.packs (py: py // {
      view = with py.packs.pkgs; (pyView ([
        python
        gettext
        py-astropy
        py-autopep8
        py-backports-ssl-match-hostname
        #py-backports-weakref # broken?
        py-biopython
        py-bokeh
        py-bottleneck
        py-cherrypy
        py-cython
        py-dask
        py-deeptools
        #py-einsum2
        py-emcee
        py-envisage #qt
        py-flask
        py-flask-socketio
        py-fusepy
        #py-fuzzysearch
        #py-fwrap
        #py-ggplot
        #py-glueviz
        #py-gmpy2
        py-gpustat
        py-h5py
        #py-husl
        py-hypothesis
        py-intervaltree
        py-ipdb
        py-ipykernel
        py-ipyparallel
        py-ipywidgets
        py-ipython
        #py-jax
        py-jupyter-console
        #py-jupyter-contrib-nbextensions
        py-jupyter-server
        py-jupyterlab
        py-jupyterlab-server
        #py-leveldb
        #py-llfuse
        py-mako
        #py-matlab-wrapper
        py-matplotlib
        py-netcdf4
        py-nbconvert
        py-nose
        py-notebook
        py-numba
        py-numpy
        py-olefile
        #py-paho-mqtt
        py-pandas
        #py-parmap
        py-partd
        py-pathos
        py-pexpect
        py-pip
        py-pkgconfig
        #py-primefac
        py-prompt-toolkit
        py-psycopg2
        py-pybind11
        py-pycairo
        py-pycuda
        py-pyfftw
        py-pygments
        py-pylint
        py-pymc3
        py-pyqt5
        #py-pyreadline
        #py-pysnmp
        #py-pystan
        py-pytest
        #py-python-gflags
        #py-python-hglib
        py-pyyaml
        py-qtconsole
        #py-ray #needs bazel 4
        py-s3fs
        #py-scikit-cuda
        py-scikit-image
        py-scikit-learn
        py-scipy
        py-seaborn
        py-setuptools
        py-shapely
        #py-sip
        py-sphinx
        py-sqlalchemy
        #py-statistics
        py-sympy
        #py-tensorflow
        #py-tess
        py-toml
        py-twisted
        py-virtualenv
        py-wcwidth
        #py-ws4py
        #py-xattr #broken: missing pip dep
        #py-yep
        py-yt
      ] ++ lib.optionals comp.isCore [
        py-torch
        py-torchvision
      ])).overrideView {
        ignoreConflicts = ["lib/python3.*/site-packages/PyQt5/__init__.py"];
      };
    });
  });

  /* does not work
  intel = rec {
    packs = corePacks.withCompiler corePacks.pkgs.intel-oneapi-compilers;
    pkgs = hdf5Pkgs packs;
  }; */

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
    slack
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

    /* disabled as reloading identical aliases triggers a bug in old lmod
    { path = ".modulerc";
      static =
        let alias = {
          "Blast" = "blast-plus";
          "amd/aocc" = "aocc";
          "disBatch/2.0-beta" = "disBatch/2.0-rc2";
          "intel/mkl" = "intel-mkl";
          "intel/mpi" = "intel-mpi";
          "lib/arpack" = "arpack-ng";
          "lib/boost" = "boost";
          "lib/eigen" = "eigen";
          "lib/fftw2" = "fftw/2";
          "lib/fftw3" = "fftw/3";
          "lib/gmp" = "gmp";
          "lib/gsl" = "gsl";
          "lib/hdf5" = "hdf5";
          "lib/healpix" = "healpix-cxx";
          "lib/mpc" = "mpc";
          "lib/mpfr" = "mpfr";
          "lib/netcdf" = "netcdf-c";
          "lib/NFFT" = "nfft";
          "lib/openblas" = "openblas";
          "lib/openmm" = "openmm";
          "nodejs" = "node-js";
          "nvidia/nvhpc" = "nvhpc";
          "openmpi2" = "openmpi/2";
          "openmpi4" = "openmpi/4";
          "perl5" = "perl/5";
          "python3" = "python/3";
          "qt5" = "qt/5";
        }; in
        builtins.concatStringsSep "" (builtins.map (n: ''
          module_alias("${n}", "${alias.${n}}")
        '') (builtins.attrNames alias));
    } */
  ];

};

# TODO:
#  amd/aocl
#  amd/uprof
#  triqs/...
#  py jaxlib cuda
#  py deadalus mpi: robert
# remove hash on avail display?
# make tcl -> lmod transition smoother
# triqs (and such) -> python dep (confict 3.9?) [lmod doesn't seem to support this fully]

jupyterBase = pyView (with corePacks.pkgs; [
  python
  py-jupyterhub
  py-jupyterlab
  py-batchspawner
  node-js
  py-bash-kernel
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
      { pkg = corePacks.pkgs.py-bash-kernel;
        kernelSrc = import ../jupyter/kernel/bash corePacks {
          pkg = jupyterBase;
          jupyter = jupyterBase;
        };
        env = {
          PYTHONHOME = null;
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
      builtins.concatMap (py: [{
        pkg = py.view;
        default = py.isCore;
        projection = "python-mpi/{^python.version}";
        #autoload = [comp.pythons[py].view]
      }] ++ py.pkgs) pythons
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
        "lib" = ["LIBRARY_PATH"];
        "lib64" = ["LIBRARY_PATH"];
        "include" = ["C_INCLUDE_PATH" "CPLUS_INCLUDE_PATH"];
        "" = ["{name}_ROOT" "{name}_BASE"];
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
      llvm = {
        environment = {
          prepend_path = {
            # see pythonbind
            PYTHONPATH = "{prefix}/lib/python3/site-packages";
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
      pvfmm = {
        environment = {
          set = {
            PVFMM_DIR = "/mnt/ceph/users/scc/pvfmm";
            pvfmm_DIR = "/mnt/ceph/users/scc/pvfmm";
          };
        };
      };
      stkfmm = {
        environment = {
          prepend_path = {
            PYTHONPATH = "{prefix}/lib64/python";
          };
        };
      };
    };

    pkgs = modPkgs;

  };

  inherit bootstrapPacks jupyter;

  traceModSpecs = lib.traceSpecTree (builtins.concatMap (p:
    let q = p.pkg or p; in
    q.pkgs or (if q ? spec then [q] else [])) modPkgs);
}
