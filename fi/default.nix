/* these preferences can be overriden on the command-line (and are on popeye by fi/run) */
{ target ? "broadwell"
, cudaarch ? "60,70,80"
}:

let

lib = corePacks.lib;

isLDep = builtins.elem "link";
isRDep = builtins.elem "run";
isRLDep = d: isLDep d || isRDep d;

rpmVersion = pkg: lib.capture ["/bin/rpm" "-q" "--queryformat=%{VERSION}" pkg];
rpmExtern = pkg: { extern = "/usr"; version = rpmVersion pkg; };

corePacks = import ../packs {
  label = "core";
  system = builtins.currentSystem;
  os = "centos7";

  spackSrc = {
    /* -------- upstream spack version -------- */
    url = "git://github.com/flatironinstitute/spack";
    ref = "fi-nixpack";
    rev = "2311242d266d90726222002a262b50a165adb6bf";
  };

  spackConfig = {
    config = {
      source_cache = "/mnt/home/spack/cache";
    };
  };
  spackPython = "/usr/bin/python3";
  spackPath = "/bin:/usr/bin";

  nixpkgsSrc = {
    /* -------- upstream nixpkgs version -------- */
    ref = "release-21.05";
    rev = "2fd5c69fa6057870687a6589a8c95da955188f91";
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

    /* ---------- global package preferences ------------
     * Default settings and versions for specific packages should be added here (in alphabetical order).
     */
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
    blender = {
      variants = {
        ffmpeg = true;
      };
    };
    boost = {
      variants = {
        context = true;
        coroutine = true;
        cxxstd = "14";
        python = true;
        numpy = true;
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
    cfitsio = {
      # for healpix-cxx
      version = "3.49";
    };
    coreutils = {
      # failing
      tests = false;
    };
    cpio = rpmExtern "cpio"; # some intel installers need this -- avoid compiler dependency
    cuda = {
      # for cudnn
      version = "11.4";
    };
    cudnn = {
    };
    dejagnu = {
      # for gcc
      version = "1.4";
      # failing
      tests = false;
    };
    docbook-xml = { # for gtk-doc
      version = "4.3";
    };
    docbook-xsl = {
      version = "1.78.1";
    };
    doxygen = {
      # for openmm build failure, gcc conflict
      version = "1.8";
    };
    embree = {
      # for blender
      variants = {
        ispc = false;
      };
      depends = {
        # -mprefer-vector-width=256
        compiler = corePacks.pkgs.gcc.withPrefs { version = "10.2"; };
      };
    };
    fftw = {
      variants = {
        openmp = true;
        precision = ["float" "double" "quad" "long_double"];
      };
    };
    freetype = { # for vtk
      #version = ":2.10.2";
    };
    gcc = {
      version = "7";
      # needs guile, which is broken
      #tests = false;
    };
    gdb = {
      depends = {
        python = {
          variants = {
            debug = true;
          };
        };
      };
    };
    gdbm = {
      # for perl
      version = "1.19";
      # failing
      tests = false;
    };
    gdk-pixbuf = {
      depends = {
        meson = {
          # work around undefined x11 in spack build
          version = "0.59";
        };
      };
    };
    /* external opengl: */
    gl = {
      name = "opengl";
    };
    glx = {
      name = "opengl";
    };
    gsl = {
      variants = {
        external-cblas = true;
      };
    };
    guile = {
      # for autogen
      version = "2.0";
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
    hdfview = {
      depends = {
        hdf = {
          variants = {
            external-xdr = false;
            java = true;
            shared = true;
          };
        };
        hdf5 = {
          variants = {
            java = true;
          };
        };
      };
    };
    htslib = {
      # for samtools/bcftools
      version = "1.12";
    };
    intel-mpi = { # not available anymore...
      extern = "/cm/shared/sw/pkg/vendor/intel-pstudio/2017-4/compilers_and_libraries_2017.4.196/linux/mpi";
      version = "2017.4.196";
    };
    java = {
      # for hdfview (weird issue with 11.0.12)
      name = "openjdk";
      version = "11.0.8_10";
    };
    libaio = {
      # needs mke2fs?
      tests = false;
    };
    libepoxy = {
      variants = {
        #glx = false; # ~glx breaks gtkplus
      };
    };
    libevent = {
      # for pmix
      version = "2.1.8";
    };
    libfabric = {
      variants = {
        fabrics = ["udp" "rxd" "shm" "sockets" "tcp" "rxm" "verbs" "psm2" "psm" "mlx"];
      };
    };
    libffi = {
      # failing
      tests = false;
    };
    libunwind = {
      # failing
      tests = false;
    };
    llvm = {
      version = "11";
      variants = {
        pythonbind = true;
        omp_as_runtime = false;
      };
    };
    magma = {
      variants = {
        inherit cuda_arch;
      };
    };
    mbedtls = {
      # for libarchive
      version = "2";
      variants = {
        pic = true;
      };
      tests = false;
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
    nvhpc = {
      variants = {
        mpi = true;
        stdpar = builtins.head (lib.splitRegex "," cudaarch);
      };
    };
    ocaml = {
      # for unison
      version = "4.11";
      variants = {
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
        pmix = true;
        static = false;
        thread_multiple = true;
        legacylaunchers = true;
      };
    };
    openvdb = {
      variants = {
        python = true;
      };
    };
    pango = {
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
    plumed = {
      # for gromacs
      version = "2.7.2";
    };
    postgresql = {
      # for py-psycopg2
      version = ":13";
    };
    protobuf = {
      # for py-torch
      version = "3.17";
    };
    psm = bootstrapPacks.pkgs.psm; # needs old gcc
    py-astroid = {
      # for py-pylint
      version = "2.5";
    };
    py-botocore = {
      # for aiobotocore
      version = "1.19.52";
    };
    py-chardet = {
      # for py-aiohttp
      version = "3";
    };
    py-decorator = {
      # for py-networkx
      version = "4";
    };
    py-docutils = {
      # for py-sphinx
      version = "0.17";
    };
    py-h5py = {
    };
    py-idna = {
      # for py-requests
      version = "2";
    };
    py-jax = {
      variants = {
        inherit cuda_arch;
      };
    };
    py-jupyter-client = {
      # for py-nest-asyncio
      version = "6";
    };
    py-jupyter-packaging = {
      # for py-jupyterlab-widgets
      version = "0.7";
    };
    py-jupyter-server = {
      # for py-jupyterlab-widgets
      version = "1.9";
    };
    py-jupyterlab = {
      # for py-jupyterlab-widgets
      version = "3.0.14";
    };
    py-numpy = {
      # for numba
      version = "1.20";
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
    py-setuptools = {
      # for py-scipy
      version = "57";
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
    samtools = {
      # to match bcftools
      version = "1.12";
    };
    shadow = rpmExtern "shadow-utils";
    slurm = rec {
      extern = "/cm/shared/apps/slurm/current";
      version = lib.capture ["/bin/readlink" "-n" extern];
      variants = {
        sysconfdir = "/cm/shared/apps/slurm/var/etc/slurm";
        pmix = true;
        hwloc = true;
      };
    };
    texlive = {
      depends = {
        poppler = {
          version = ":0.84";
        };
      };
    };
    texstudio = {
      depends = {
        poppler = {
          variants = {
            qt = true;
          };
        };
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
    vmd = {
      depends = {
        gcc = bootstrapPacks.pkgs.gcc;
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
    openmpi = spec: old: {
      patches =
        lib.optionals (spec.version == "1.10.7")                  [ ./openmpi-1.10.7.PATCH ] ++
        lib.optionals (lib.versionAtMostSpec spec.version "1.10") [ ./openmpi-1.10-gcc.PATCH ] ++
        lib.optionals (spec.version == "2.1.6")                   [ ./openmpi-2.1.6.PATCH ];
      build = {
        setup = ''
          configure_args = pkg.configure_args()
          configure_args.append('CPPFLAGS=-I/usr/include/infiniband')
          if spec.satisfies("~pmix"):
            configure_args.remove('--without-pmix')
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
    /* fix LIBRARY_PATH ordering wrt system /lib64 for libraries with different major versions */
    boost = lib64Link;
    fftw = lib64Link;
    gsl = lib64Link;
    hdf5 = lib64Link;
  };
};

lib64Link = {
  build = {
    post = ''
      os.symlink('lib', pkg.prefix.lib64)
    '';
  };
};

bootstrapPacks = corePacks.withPrefs {
  label = "bootstrap";
  global = {
    target = "haswell";
    resolver = null;
    tests = false;
  };
  package = {
    compiler = {
      name = "gcc";
    } // rpmExtern "gcc";

    autoconf = rpmExtern "autoconf";
    automake = rpmExtern "automake";
    bzip2 = rpmExtern "bzip2";
    diffutils = rpmExtern "diffutils";
    libtool = rpmExtern "libtool";
    m4 = rpmExtern "m4";
    ncurses = rpmExtern "ncurses" // {
      variants = {
        termlib = true;
        abi = "5";
      };
    };
    openssl = rpmExtern "openssl" // {
      variants = {
        fips = false;
      };
    };
    perl = rpmExtern "perl";
    pkgconfig = rpmExtern "pkgconfig";
    psm = {};
    zlib = rpmExtern "zlib";
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
  [ /* -------- compilers -------- */
    corePacks.pkgs.compiler
    (corePacks.pkgs.gcc.withPrefs { version = "10.2"; })
    #(corePacks.pkgs.gcc.withPrefs { version = "11"; })
  ];

mkMpis = base: gen:
  builtins.map (mpi: gen {
    inherit mpi;
    packs = base.withPrefs {
      global = {
        variants = {
          mpi = true;
        };
      };
      package = {
        inherit mpi;
        fftw = {
          variants = {
            openmp = true;
            precision = ["float" "double" "long_double"];
          };
        };
      };
    };
    isOpenmpi = mpi.name == "openmpi";
    isCore = mpi == { name = "openmpi"; };
  })
  [ /* -------- mpis -------- */
    { name = "openmpi"; }
    { name = "openmpi";
      version = "2.1";
      variants = {
        # openmpi 2 on ib reports: "unknown link width 0x10" and is a bit slow
        fabrics = {
          ucx = false;
        };
        internal-hwloc = true;
        pmix = false; # patched to mean internal
      };
    }
    { name = "openmpi";
      version = "1.10";
      variants = {
        fabrics = {
          ucx = false;
        };
        internal-hwloc = true;
        pmix = false;
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
    add_property("lmod","sticky")
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
  [ /* -------- pythons -------- */
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

pkgExtensions = f: pkgs:
  let ext = builtins.concatStringsSep ", " (map
    (p: f (p.spec.name + "/" + p.spec.version)) pkgs);
  in ''
    extensions("${ext}")
  '';

preExtensions = pre: view: pkgExtensions
  (lib.takePrefix pre)
  (builtins.filter (p: lib.hasPrefix pre p.spec.name) view.pkgs);

# XXX these spack names don't quite match the modules
pyExtensions = preExtensions "py-";
rExtensions = preExtensions "r-";

pkgStruct = {
  pkgs = with corePacks.pkgs; [
    /* ------------ Core modules ------------ */
    { pkg = slurm;
      environment = {
        set = {
          CMD_WLM_CLUSTER_NAME = "slurm";
          SLURM_CONF = "/cm/shared/apps/slurm/var/etc/slurm/slurm.conf";
        };
      };
      projection = "{name}";
      postscript = ''
        add_property("lmod","sticky")
      '';
    }
    (llvm.withPrefs { version = "10"; })
    { pkg = llvm;
      default = true;
    }
    (llvm.withPrefs { version = "12"; })
    { pkg = gcc.withPrefs { version = "11"; };
      context = {
        unlocked_paths = ["gcc/10.2.0"]; # XXX use gcc 10 modules
      };
    }
    { pkg = aocc;
      context = {
        provides = []; # not a real compiler
      };
    }
    { pkg = corePacks.view {
        name = "autotools";
        pkgs = [autoconf automake libtool];
      };
      projection = "autotools";
      context = rec {
        name = "autotools";
        short_description = "GNU autotools, including ${autoconf.name}, ${automake.name}, and ${libtool.name}";
        long_description = short_description;
      };
    }
    blast-plus
    blender
    cmake
    (cmake.withPrefs { version = "3.20"; }) # https://gitlab.kitware.com/cmake/cmake/-/issues/22723
    cuda
    cudnn
    curl
    { pkg = disBatch.withPrefs { version = "1"; };
      default = true;
    }
    (disBatch.withPrefs { version = "2"; })
    (disBatch.withPrefs { version = "2.0-pip"; })
    distcc
    (emacs.withPrefs { variants = { X = true; toolkit = "athena"; }; })
    fio
    flexiblas
    gdal
    gdb
    ghostscript
    git
    git-lfs
    go
    gperftools
    { pkg = gromacs.withPrefs { variants = { cuda = true; }; };
      projection = "{name}/{version}-singlegpunode";
      environment = {
        set = { GMX_GPU_DD_COMMS = "true";
                GMX_GPU_PME_PP_COMMS = "true";
                GMX_FORCE_UPDATE_DEFAULT_GPU = "true";
        };
      };
    }
    hdfview
    imagemagick
    (blasPkg intel-mkl)
    (blasPkg (intel-mkl.withPrefs { version = "2017.4.239"; }))
    intel-mpi
    intel-oneapi-compilers
    (blasPkg intel-oneapi-mkl)
    intel-oneapi-mpi
    intel-oneapi-tbb
    intel-oneapi-vtune
    intel-tbb
    julia
    keepassxc
    lftp
    libzmq
    likwid
    magma
    mercurial
    #mplayer
    #mpv
    mupdf
    nccl
    #nix #too old/broken
    node-js
    (node-js.withPrefs { version = ":12"; })
    { pkg = nvhpc;
      context = {
        unlocked_paths =
          # XXX this is very hacky to avoid spack's all-combinations path approach as all nvhpc modules are +mpi
          let
            store = builtins.getEnv "NIX_STORE_DIR";
            storelen = builtins.stringLength store;
            hash = builtins.substring (storelen + (if builtins.substring (storelen - 1) 1 store == "/" then 0 else 1)) 7 nvhpc.outPath;
            ver = nvhpc.spec.version;
          in
          ["nvhpc/${ver}-${hash}/nvhpc/${ver}"];
      };
    }
    octave
    openjdk
    openmm
    ilmbase openexr # hidden, deps of openvdb
    { pkg = openvdb;
      autoload = with openvdb.spec.depends; [ilmbase openexr intel-tbb];
    }
    p7zip
    paraview
    #pdftk #needs gcc java (gcj)
    perl
    petsc
    pixz
    postgresql
    qt
    { pkg = rView;
      environment = {
        prepend_path = {
          R_LIBS_SITE = "{prefix}/rlib/R/library";
        };
      };
      postscript = rExtensions rView;
    }
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
    #visit #needs qt <= 5.14.2
    vmd
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
      #{ version = "cluster.2019.3"; path = "2019-3"; }
      { version = "cluster.2020.0"; path = "2020"; }
      { version = "cluster.2020.4"; path = "2020-4"; }
    ]
  ;

  compilers = mkCompilers corePacks (comp: comp // {
    pkgs = with comp.packs.pkgs; [
      /* ---------- compiler modules ---------- */
      (comp.defaulting compiler)
      arpack-ng
      cfitsio
      eigen
      { pkg = ffmpeg;
        default = true;
      }
      gsl
      gmp
      healpix-cxx
      #hwloc
      #libdrm
      #magma
      #mesa
      libxc
      mpc
      mpfr
      netcdf-c
      netcdf-fortran
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
        /* ---------- MPI modules ---------- */
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
          { pkg = gromacs.withPrefs { version = "2021:2021.0"; variants = { plumed = true; }; };
            projection = "{name}/{version}-plumed"; }
          plumed
          relion
        ] ++ [
          ior
          petsc
          valgrind
        ]);

      pythons = mkPythons mpi.packs (py: py // {
        /* ---------- python+mpi modules ---------- */
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
        /* ---------- python packages ---------- */
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
        py-jax
        py-torch
        py-torchvision
      ])).overrideView {
        # for py-pyqt/py-sip
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
            context = true;
            coroutine = true;
            cxxstd = "14";
            clanglibcpp = true;
          };
        };
      };
    };
    pkgs = with packs.pkgs; [
      /* -------- clang libcpp modules --------- */
      boost
    ];
  };

  nvhpc = rec {
    packs = corePacks.withPrefs {
      package = {
        compiler = corePacks.pkgs.nvhpc;
        mpi = corePacks.pkgs.nvhpc;
        fftw = {
          variants = {
            openmp = true;
            precision = ["float" "double" "long_double"];
          };
        };
        hdf5 = {
          version = "1.10";
          variants = {
            hl = true;
            fortran = true;
            cxx = true;
          };
          depends = {
            cmake = {
              # https://gitlab.kitware.com/cmake/cmake/-/issues/22723
              version = "3.20";
            };
          };
        };
      } // blasVirtuals corePacks.pkgs.nvhpc;
      global = {
        variants = {
          mpi = true;
        };
      };
    };
    pkgs = builtins.tail (optMpiPkgs packs) /* omitting boost */
      ++
      (with packs.pkgs; [
        osu-micro-benchmarks
      ]);
  };

  nixpkgs = with corePacks.nixpkgs; [
    /* -------- nixpkgs modules --------- */
    nix
    elinks
    #evince
    feh
    ffmpeg
    #gimp
    #git
    #i3-env
    #inkscape
    #jabref
    #keepassx2
    kubectl
    #libreoffice
    #meshlab
    mplayer
    (mpv // { name = builtins.replaceStrings ["-with-scripts"] [""] mpv.name; })
    #pass
    #pdftk
    #rxvt-unicode
    #sage
    slack
    (vscode.overrideAttrs (old: {
      preFixup = old.preFixup + ''
        gappsWrapperArgs+=(
          --add-flags --no-sandbox
        )
      '';
      passthru = old.passthru // {
        module = {
          postscript = ''
            depends_on("git")
          '';
        };
      };
    }))
    #wecall
    xscreensaver
  ];

  static = [
    /* -------- misc modules --------- */
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
      projection = "{name}";
      static = ''
        whatis("Switch to the old tcl modules")
        local lm = loaded_modules()
        for i = 1, #lm do
          conflict(lm[i].fullName)
        end
        setenv("ENABLE_LMOD", "0")
        unsetenv("MODULESPATH")
        if mode() == "load" then
          if myShellType() == "csh" then
            execute {cmd="clearLmod ; setenv ENABLE_LMOD 0 ; source /etc/profile.d/modules.csh ;", modeA={"load"}}
          else
            execute {cmd="clearLmod ; export ENABLE_LMOD=0 ; . /etc/profile.d/modules.sh ;", modeA={"load"}}
          end
        end
      '';
    }
    { name = "modules-new";
      projection = "{name}";
      static = ''
        LmodMessage("You are already using the new modules.  You can load 'modules-traditional' to switch to the old ones.")
        os.exit(1)
      '';
    }

    { path = ".modulerc";
      static =
        let alias = {
          "Blast" = "blast-plus";
          "amd/aocc" = "aocc";
          "disBatch/2.0-beta" = "disBatch/2.0-rc3";
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
        # reloading identical aliases triggers a bug in old lmod
        # wrap in hacky conditional (since old lmod runs modulerc without sandbox, somehow)
        ''
          if _VERSION == nil then
        '' +
        builtins.concatStringsSep "" (builtins.map (n: ''
            module_alias("${n}", "${alias.${n}}")
        '') (builtins.attrNames alias))
        + ''
          end
          hide_version("jupyterhub")
          hide_version("modules-new")
        '' +
        builtins.concatStringsSep "" (builtins.map (n: ''
          hide_version("${n.spec.name}/${n.spec.version}")
        '') (with corePacks.pkgs; [ ilmbase openexr ]))
        ;
    }
  ];

};

# TODO:
#  amd/aocl
#  amd/uprof
#  triqs/...
#  py jaxlib cuda
#  py deadalus mpi: robert
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

pkgMod = p: if p ? pkg then p else { pkg = p; };

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
        postscript = pyExtensions py.view +
          # conflicts with non-mpi version
          ''
            conflict("hdf5/${py.packs.pkgs.hdf5.spec.version}")
          '';
      }] ++ py.pkgs) pythons
    ) mpis
    ++
    builtins.concatMap (py: with py; [
      { pkg = view;
        default = isCore;
        postscript = pyExtensions view;
      }
    ]) pythons
  ) compilers
  ++
  map (pkg: pkgMod pkg // { projection = "{name}/{version}-libcpp";
    autoload = [clangcpp.packs.pkgs.compiler]; })
    clangcpp.pkgs
  ++
  map (pkg: pkgMod pkg // { projection = "{name}/{version}-nvhpc"; })
    nvhpc.pkgs
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
    projection = "{name}/{version}-nix";
  } // p.module or {}) nixpkgs
  ++
  static
;

mods = corePacks.modules {
  coreCompilers = map (p: p.pkgs.compiler) [
    corePacks
    bootstrapPacks
    pkgStruct.clangcpp.packs
  ];
  config = {
    hierarchy = ["mpi"];
    hash_length = 0;
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
    intel-mkl = {
      environment = {
        set = {
          MKL_INTERFACE_LAYER    = "GNU,LP64";
          MKL_THREADING_LAYER    = "GNU";
        };
      };
    };
    intel-oneapi-mkl = {
      environment = {
        set = {
          MKL_INTERFACE_LAYER    = "GNU,LP64";
          MKL_THREADING_LAYER    = "GNU";
        };
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

modSite = import ./lmod corePacks mods;

in

corePacks // {
  inherit
    bootstrapPacks
    pkgStruct
    mods
    modSite
    jupyter;

  traceModSpecs = lib.traceSpecTree (builtins.concatMap (p:
    let q = p.pkg or p; in
    q.pkgs or (if q ? spec then [q] else [])) modPkgs);
}
