/* these preferences can be overriden on the command-line (and are on popeye by fi/run) */
{ os ? "centos7"
, target ? "broadwell"
, cudaarch ? "60,70,80,90"
, gitrev ? null
}:

let

lib = corePacks.lib;

isLDep = builtins.elem "link";
isRDep = builtins.elem "run";
isRLDep = d: isLDep d || isRDep d;

rpmVersion = pkg: lib.capture ["/bin/rpm" "-q" "--queryformat=%{VERSION}" pkg] { inherit os; };
rpmExtern = pkg: { extern = "/usr"; version = rpmVersion pkg; };

corePacks = import ../packs {
  label = "core";
  system = builtins.currentSystem;
  inherit os;

  spackSrc = {
    /* -------- upstream spack version -------- */
    url = "https://github.com/flatironinstitute/spack";
    ref = "fi-nixpack";
    rev = "7f4b0a6b52990d66304dc0a3f9783d76694cdef0";
  };

  spackConfig = {
    config = {
      source_cache = "/mnt/home/spack/cache";
      license_dir = "/mnt/sw/fi/licenses";
    };
  };
  spackPython = "/usr/bin/python3";
  spackEnv = {
    PATH = "/bin:/usr/bin";
  };

  nixpkgsSrc = {
    /* -------- upstream nixpkgs version -------- */
    ref = "release-22.05";
    rev = "4f09cfce9c1d54fb56b65125061a632849de1a49";
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
    amdlibm = {
      depends = {
        compiler = corePacks.pkgs.gcc.withPrefs { version = "10"; };
      };
    };
    assimp = {
      version = "5.0";
    };
    bazel = {
      version = "3";
    };
    binutils = {
      variants = {
        gold = true;
        ld = true;
      };
    };
    blender = {
      variants = {
        cycles = true;
        ffmpeg = true;
        opensubdiv = true;
      };
      depends = {
        compiler = corePacks.pkgs.gcc.withPrefs { version = "10"; };
      };
    };
    boost = {
      variants = {
        atomic = true;
        chrono = true;
        container = true;
        context = true;
        coroutine = true;
        date_time = true;
        exception = true;
        filesystem = true;
        graph = true;
        iostreams = true;
        log = true;
        math = true;
        numpy = true;
        program_options = true;
        python = true;
        random = true;
        regex = true;
        serialization = true;
        signals = true;
        system = true;
        test = true;
        thread = true;
        timer = true;
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
    cfitsio = {
      # for healpix-cxx
      version = "3.49";
    };
    cli11 = {
      # for paraview
      version = "1.9.1";
    };
    cmake = {
      # py-torch breakage
      version = "3.22.3";
    };
    coreutils = {
      # failing
      tests = false;
    };
    cpio = rpmExtern "cpio"; # some intel installers need this -- avoid compiler dependency
    cuda = {
      # make sure this matches image driver
      version = "11.8";
      depends = {
        libxml2 = rpmExtern "libxml2";
      };
    };
    cudnn = {
      version = "8.4";
    };
    curl = {
      variants = {
        libidn2 = true;
      };
    };
    dejagnu = {
      # for gcc
      version = "1.4";
      # failing
      tests = false;
    };
    docbook-xml = {
      # for dbus
      version = "4.4";
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
        compiler = corePacks.pkgs.gcc.withPrefs { version = "10"; };
      };
    };
    ffmpeg = {
      variants = {
        libaom = true;
      };
    };
    fftw = {
      variants = {
        openmp = true;
        precision = ["float" "double" "quad" "long_double"];
      };
    };
    fltk = {
      variants = {
        xft = true;
      };
    };
    gcc = {
      version = if os == "centos7" then "7" else "10";
      variants = {
        languages = ["c" "c++" "fortran" "jit"];
      };
      # needs guile, which is broken
      #tests = false;
    };
    gdal = {
      variants = {
        lerc = false; # spack bug finding libLerc.so
      };
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
    gdrcopy = {
      version = "2.3"; # match kernel module
    };
    gnuplot = {
      variants = {
        X = true;
      };
    };
    gpu-burn = {
      variants = {
        inherit cuda_arch;
      };
    };
    grace = {
      depends = {
        fftw = {
          version = "2";
          variants = {
            precision = ["float" "double"];
          };
        };
      };
    };
    gromacs = {
      variants = {
        cuda = true;
      };
    };
    gsl = {
      variants = {
        external-cblas = true;
      };
    };
    gtk-doc = {
      depends = {
        docbook-xml = {
          version = "4.3";
        };
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
          version = "1.10.7";
          variants = {
            java = true;
          };
        };
      };
    };
    htslib = {
      # for samtools/bcftools
      #version = "1.12";
    };
    intel-parallel-studio = {
      build = {
        INTEL_LICENSE_FILE = "28518@lic1.flatironinstitute.org";
      };
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
    libarchive = {
      depends = {
        mbedtls = {
          version = "2";
        };
      };
    };
    libcap = rpmExtern "libcap";
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
        fabrics = ["udp" "rxd" "shm" "sockets" "tcp" "rxm" "verbs" "psm2"] ++ lib.optionals (os == "centos7") ["psm"] ++ ["mlx"];
      };
    };
    libffi = {
      # failing
      tests = false;
    };
    libgit2 = {
      # for rust
      version = "1.3";
    };
    libglx = {
      name = "opengl";
    };
    libunwind = {
      # failing
      tests = false;
    };
    llvm = {
      version = "11";
      build = {
        # install python bindings
        setup = ''
          cmake_args = pkg.cmake_args()
          cmake_args.append("-DCLANG_PYTHON_BINDINGS_VERSIONS=3")
          cmake_args.append("-DLLDB_ENABLE_PYTHON:BOOL=ON")
          pkg.cmake_args = lambda: cmake_args
        '';
      };
    };
    magma = {
      variants = {
        inherit cuda_arch;
      };
    };
    mbedtls = {
      variants = {
        pic = true;
      };
      tests = false;
    };
    mpc = {
      version = "1.1";
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
    netcdf-c = {
      variants = {
        # just to force curl dep
        dap = true;
      };
    };
    neovim = {
      depends = {
        lua = {
          version = "5.1";
        };
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
      #version = "0.3.15";
      variants = {
        threads = "pthreads";
      };
    };
    opengl = {
      version = "4.6";
      extern = "/usr";
    };
    openldap = {
      # for python-ldap
      version = "2.4";
      variants = {
        tls = "openssl";
        sasl = false;
      };
    };
    openmpi = {
      version = "4.0";
      variants = {
        fabrics = {
          none = false;
          ofi = true;
          ucx = true;
          psm = os == "centos7";
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
        legacylaunchers = true;
      };
    };
    openssl = if os == "rocky8" then rpmExtern "openssl" // {
      variants = {
        fips = false;
      };
    } else {};
    opensubdiv = {
      variants = {
        inherit cuda_arch;
        cuda = true;
        openmp = true;
      };
    };
    openvdb = {
      variants = {
        python = true;
      };
      depends = {
        intel-tbb = {
          # doesn't support 2021 (missing headers)
          version = "2020";
        };
      };
    };
    pango = {
      variants = {
        X = true;
      };
    };
    papi = {
      # last official release doesn't support zen (as of 22-06-07)
      # also we have a custom icelake patch (as of 22-06-29)
      version = "6.0.0.1-fi";
    };
    paraview = {
      # 5.10.0 build failure?? graphviz geom.h POINTS_PER_INCH
      #version = "5.9.1";
      variants = {
        python3 = true;
        qt = true;
        osmesa = false;
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
      version = "2.8.0";
    };
    poppler = {
      variants = {
        glib = true;
      };
    };
    postgresql = {
      # for py-psycopg2
      version = ":13";
      variants = {
        client_only = true;
      };
    };
    proj = {
      # for vtk
      version = "7";
    };
    protobuf = {
      # for py-torch
      version = "3.14";
    };
    psm = bootstrapPacks.pkgs.psm; # needs old gcc
    py-aiohttp = {
      # 3.8 build broken
      #version = "3.7";
    };
    py-astroid = {
      # for py-pylint
      #version = "2.5";
      depends = {
        py-setuptools = {
          version = "62";
        };
      };
    };
    py-async-timeout = {
      # for py-aiohttp
      #version = "3";
    };
    py-backports-entry-points-selectable = {
      depends = {
        py-importlib-metadata = {
          version = ":3.8";
        };
      };
    };
    py-blessings = {
      depends = {
        py-setuptools = {
          version = "57";
        };
      };
    };
    py-botocore = {
      # for py-aiobotocore
      version = "1.19.52";
    };
    py-chardet = {
      # for py-aiohttp
      #version = "3";
    };
    py-charset-normalizer = {
      # for py-requests
      version = "2.0";
    };
    py-cppy = {
      # py-setuptools
      #version = "1.1";
      depends = {
        py-setuptools = {
          version = "62:";
        };
      };
    };
    py-cryptography = {
      # for py-oauthlib
      #version = "3";
    };
    py-decorator = {
      # for py-networkx
      #version = "4";
    };
    py-docutils = {
      # for py-sphinx
      #version = "0.17";
    };
    py-filelock = {
      # py-setuptools
      #version = ":3.7";
      depends = {
        py-setuptools = {
          version = "62:";
        };
      };
    };
    py-gevent = {
      depends = {
        py-cython = {
          version = "3";
        };
      };
    };
    py-h5py = {
    };
    py-idna = {
      # for py-requests
      #version = "2";
    };
    py-ipyparallel = {
      depends = {
        py-setuptools = {
          version = "59";
        };
      };
      build = {
        # workaround ipython/ipyparallel#675
        IPP_DISABLE_JS = "1";
      };
    };
    py-jax = {
      variants = {
        inherit cuda_arch;
      };
    };
    py-jupyter-client = {
      # for py-nest-asyncio, py-ipykernel
      #version = "6";
    };
    py-jupyter-packaging = {
      # for py-jupyterlab-widgets
      #version = "0.7";
    };
    py-jupyter-packaging11 = {
      # py-setuptools dep
      #version = ":0.11";
      depends = {
        py-setuptools = {
          version = "62:";
        };
      };
    };
    py-jupyter-server = {
      # py-nbconvert dep
      version = ":1.15";
    };
    py-jupyterlab = {
      # py-jupyter-server dep
      version = ":3.3";
    };
    py-jupyterlab-pygments = {
      # avoid recursive jupyterlab -> jupyter_server -> nbconvert -> dependency
      version = "0.1";
    };
    py-lazy-object-proxy = {
      # to avoid py-setuptools-scm constraint
      #version = "1.4";
    };
    py-mistune = {
      # for py-nbconvert, py-m2r
      version = ":1";
    };
    py-multidict = {
      # for py-aiohttp
      #version = "4";
    };
    py-nbclient = {
      # for py-nbconvert
      version = "0.5";
    };
    py-nbconvert = {
      # py-nbconvert -> py-mistune dep, setuptools
      version = ":6.4";
    };
    py-nbformat = {
      # py-setuptools dep
      #version = ":5.2";
      depends = {
        py-setuptools = {
          version = "62:";
        };
      };
    };
    py-nose = {
      depends = {
        py-setuptools = {
          version = "57";
        };
      };
    };
    py-numpy = {
      # for py-numba
      version = ":1.22";
      depends = {
        py-setuptools = {
          version = "59";
        };
      };
    };
    py-pkgutil-resolve-name = {
      depends = {
        py-flit-core = {
          version = "2";
        };
      };
    };
    py-pybind11 = {
      # for py-torch
      version = "2.6.2";
      # for py-scipy
      #version = ":2.8";
    };
    py-pyqt5 = {
      depends = {
        py-sip = {
          variants = {
            module = "PyQt5.sip";
          };
          version = "4";
        };
      };
    };
    py-scikit-learn = {
      depends = {
        py-setuptools = {
          version = "59";
        };
      };
    };
    py-scipy = {
      depends = {
        py-setuptools = {
          version = "59";
        };
      };
    };
    py-setuptools = {
      # for py-blessings (59 for numpy)
      #version = "57";
      #version = "59";
      version = "62";
    };
    py-setuptools-rust = {
      # py-setuptools dep
      #version = "1.2.0";
      depends = {
        py-setuptools = {
          version = "62:";
        };
      };
    };
    py-setuptools-scm = {
      # for py-matplotlib
      #version = "6";
      variants = {
        toml = true;
      };
    };
    py-testpath = {
      depends = {
        py-flit-core = {
          # for py-testpath
          version = "3.2";
        };
      };
    };
    py-torch = {
      variants = {
        inherit cuda_arch;
        valgrind = false;
      };
      depends = blasVirtuals { name = "openblas"; }; # doesn't find flexiblas
    };
    py-torch-cluster = {
      variants = {
        cuda = true;
        inherit cuda_arch;
      };
    };
    py-torch-geometric = {
      variants = {
        cuda = true;
        inherit cuda_arch;
      };
    };
    py-torch-scatter = {
      variants = {
        cuda = true;
        inherit cuda_arch;
      };
    };
    py-torch-sparse = {
      variants = {
        cuda = true;
        inherit cuda_arch;
      };
    };
    py-torch-spline-conv = {
      variants = {
        cuda = true;
        inherit cuda_arch;
      };
    };
    py-virtualenv = {
      depends = {
        py-setuptools = {
          version = "62:";
        };
      };
    };
    py-wrapt = {
      # for py-astroid
      #version = "1.12";
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
      # for cuda 11.6:
      patches = [(builtins.fetchurl "https://github.com/3dem/relion/commit/554e0ed993e5ac8a3fee4be7c5cf64a62216a8c7.patch")];
    };
    samtools = {
      # to match bcftools
      #version = "1.12";
    };
    shadow = rpmExtern "shadow-utils";
    slurm = rec {
      extern = "/cm/shared/apps/slurm/current";
      version = lib.capture ["/bin/readlink" "-n" extern] { inherit os; };
      variants = {
        sysconfdir = "/cm/shared/apps/slurm/var/etc/slurm";
        pmix = true;
        hwloc = true;
      };
    };
    sra-tools = {
      patches = [(builtins.fetchurl "https://patch-diff.githubusercontent.com/raw/ncbi/sra-tools/pull/664.diff")];
    };
    texlive = {
      depends = {
        poppler = {
          version = ":0.84";
        };
      };
      variants = {
        scheme = "full";
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
        build_type = "Release";
        amesos2 = true;
        rol = true;
        stk = false;
        zoltan = true;
        zoltan2 = true;
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
        verbs = true;
        rdmacm = true;
        dm = true;
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
        programs = true;
      };
    };
  }
  // blasVirtuals { name = "flexiblas"; };

  repoPatch = {
    python = spec: old: {
      patches = [./python-ncursesw.patch];
    };
    openmpi = spec: old: {
      patches =
        lib.optionals (spec.version == "1.10.7")                  [ ./openmpi-1.10.7.PATCH ] ++
        lib.optionals (lib.versionAtMostSpec spec.version "1.10") [ ./openmpi-1.10-gcc.PATCH ] ++
        lib.optionals (spec.version == "2.1.6")                   [ ./openmpi-2.1.6.PATCH ];
      build = {
        setup = ''
          configure_args = pkg.configure_args()
          configure_args.append('CPPFLAGS=-I/usr/include/infiniband')
          # avoid openmpi1 internal hwloc libXNVCtrl link
          configure_args.append('enable_gl=no')
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
    /* Blender dependency. Wants ccache and tries to build with -Werror. Override that. */
    openimageio = { build =
      { setup = ''
        cmakeargs = pkg.cmake_args()
        cmakeargs.append('-DUSE_CCACHE=0')
        cmakeargs.append('-DSTOP_ON_WARNING=0')
        pkg.cmake_args = lambda: cmakeargs
      '';
      };
    };
    /* incorrect dependency, see https://github.com/spack/spack/pull/29629 */
    assimp = spec: old: {
      depends = builtins.removeAttrs old.depends ["boost"];
    };
    py-pycuda = spec: old: {
      /* overaggresive variants */
      depends = old.depends // {
        boost = if old.depends.boost == null then null else old.depends.boost // {
          variants = {};
        };
      };
    };
    valgrind = spec: old: {
      /* overaggresive variants */
      depends = old.depends // {
        boost = if old.depends.boost == null then null else old.depends.boost // {
          variants = {};
        };
      };
    };
    /* messed up plumed deps */
    gromacs = spec: old: {
      depends = old.depends // {
        # hack to avoid incorrect version-specific deps
        plumed = [
          (builtins.elemAt old.depends.plumed 0)
          (builtins.elemAt old.depends.plumed 1)
        ];
      };
    };
    /* missing openssl dep */
    openldap = spec: old: {
      depends = old.depends // {
        openssl = {
          deptype = ["build" "link"];
        };
      };
    };
    /* doesn't actually need gtk-doc */
    libcroco = spec: old: {
      depends = builtins.removeAttrs old.depends ["gtk-doc"];
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
    target = if os == "centos7" then "haswell" else target;
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
    libuuid = rpmExtern "libuuid";
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
    pkgconfig = if os == "centos7" then rpmExtern "pkgconfig" else {};
    psm = {};
    uuid = {
      name = "libuuid";
    };
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

mkSkylake = base: base.withPrefs {
  global = {
    target = "skylake_avx512";
    resolver = base;
  };
};

mkCompilers = base: gen:
  builtins.map (compiler: gen (rec {
    inherit compiler;
    isCore = compiler.name == corePacks.pkgs.compiler.name;
    packs = if isCore then base else
      base.withCompiler compiler;
    defaulting = pkg: { default = isCore; inherit pkg; };
  }))
  [ /* -------- compilers -------- */
    (corePacks.pkgs.gcc.withPrefs { version = "7"; })
    (corePacks.pkgs.gcc.withPrefs { version = "10"; })
    (corePacks.pkgs.gcc.withPrefs { version = "11"; })
  ];

mkMpis = comp: gen:
  builtins.map (mpi: gen {
    inherit mpi;
    packs = comp.packs.withPrefs {
      global = {
        variants = {
          mpi = true;
        };
      };
      package = {
        mpi = builtins.removeAttrs mpi ["package"];
        fftw = {
          variants = {
            openmp = true;
            precision = ["float" "double" "long_double"];
          };
        };
      } // mpi.package or {};
    };
    isOpenmpi = mpi.name == "openmpi";
    isCore = mpi == { name = "openmpi"; };
  })
  ([ /* -------- mpis -------- */
    { name = "openmpi"; }
  ] ++ lib.optionals comp.isCore [
    /* { name = "intel-mpi"; } */
    { name = "intel-oneapi-mpi"; }
    { name = "openmpi";
      variants = {
        cuda = true;
      };
      package = {
        hwloc = {
          variants = {
            cuda = true;
          };
        };
        ucx = {
          variants = {
            cuda = true;
            gdrcopy = true;
            thread_multiple = true;
            cma = true;
            rc = true;
            dc = true;
            ud = true;
            mlx5-dv = true;
            ib-hw-tm = true;
            verbs = true;
            rdmacm = true;
            dm = true;
          };
        };
      };
    }
  ]);

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

findCore = l: builtins.head (builtins.filter (x: x.isCore) l);

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
      python = py // {
        resolver = deptype: if isRLDep deptype then packs else corePacks;
      };
    };
    global = {
      resolver = deptype: ifHasPy pyPacks
        (if isRLDep deptype
          then packs
          else corePacks);
    };
  };
  in pyPacks;

corePython = { version = if os == "centos7" then "3.8" else "3.9"; };

mkPythons = base: gen:
  builtins.map (python: gen ({
    python = python;
    isCore = python == corePython;
    packs = withPython base (python // {
      variants = (python.variants or {}) // {
        tkinter = true;
      };
    });
  }))
  [ /* -------- pythons -------- */
    { version = "3.8"; }
    { version = "3.9"; }
    { version = "3.10"; }
  ];

pyBlacklist = [
  { name = "py-pip"; } # already in python
  { name = "py-setuptools"; } # already in python
  { name = "py-cython"; version = "3"; } # py-gevent dep
  { name = "py-flit-core"; version = ":3.2"; } # py-testpath dep
  { name = "py-jupyter-packaging7"; } # py-jupyterlab-widget dep
  { name = "py-importlib-metadata"; version = ":3"; } # py-backports-entry-points-selectable dep
];

pyView = pl: corePacks.pythonView {
  pkgs = builtins.filter (x: !(builtins.any (lib.specMatches x.spec) pyBlacklist))
    (lib.findDeps (x: lib.hasPrefix "py-" x.name) pl);
};

rView = corePacks.view {
  pkgs = lib.findDeps (x: lib.hasPrefix "r-" x.name) (import ./r.nix corePacks);
};

hdf5Pkgs = packs: with packs.pkgs; [
  (hdf5.withPrefs { version = "1.8";
    # spack has decided that 1.8+fortran+shared is broken for some reason #29132
    variants = { fortran = false; };
  })
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

/* julia needs very specific package versions for which dependency resolution isn't enough */
juliaPacks = corePacks.withPrefs {
  label = "julia";
  package = {
    julia = {
      version = "1.7.2";
      patches = [
        "${corePacks.spack}/var/spack/repos/builtin/packages/julia/fix-gfortran.patch"
      ];
      build = {
        # https://github.com/spack/spack/issues/32085
        post = ''
          os.symlink("/etc/ssl/certs/ca-certificates.crt", os.path.join(pkg.prefix.share, "julia/cert.pem"))
        '';
      };
    };
    llvm = {
      version = "12.0.1";
      variants = {
        internal_unwind = false;
        llvm_dylib = true;
        link_llvm_dylib = true;
        targets = {
          none = false;
          amdgpu = true;
          bpf = true;
          nvptx = true;
          webassembly = true;
        };
        version_suffix = "jl";
        omp_as_runtime = false;
      };
      patches = [(builtins.fetchurl "https://github.com/JuliaLang/llvm-project/compare/fed41342a82f5a3a9201819a82bf7a48313e296b...980d2f60a8524c5546397db9e8bbb7d6ea56c1b7.patch")];
    };
    libuv = {
      version = "1.42.0";
      patches = [(builtins.fetchurl "https://raw.githubusercontent.com/spack/patches/89b6d14eb1f3c3d458a06f1e06f7dda3ab67bd38/julia/libuv-1.42.0.patch")];
    };
    mbedtls = {
      version = "2.24";
      variants = {
        libs = ["shared"];
        pic = true;
      };
    };
    curl = {
      version = "7.78";
    };
    openblas = {
      variants = {
        ilp64 = true;
        symbol_suffix = "64_";
      };
    };
    openlibm = {
      version = "0.7";
    };
    curl = {
      variants = {
        libssh2 = true;
        nghttp2 = true;
        tls = { mbedtls = true; };
      };
    };
    libblastrampoline = {
      version = "3";
    };
    libgit2 = {
      version = "1.1";
    };
    libssh2 = {
      version = "1.9";
      variants = {
        crypto = "mbedtls";
      };
    };
    mpfr = {
      version = "4";
    };
  } // blasVirtuals {
    /* don't use flexiblas */
    name = "openblas";
  };
};

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
    (gcc.withPrefs { version = "12"; })
    { pkg = llvm;
      default = true;
    }
    { pkg = llvm.withPrefs { version = "13";
        depends = {
          compiler = corePacks.pkgs.gcc.withPrefs { version = "11"; };
        };
        variants = {
          omp_as_runtime = false;
        };
      };
      core = true;
    }
    { pkg = llvm.withPrefs {
        version = "15";
        depends = {
          compiler = corePacks.pkgs.gcc.withPrefs { version = "11"; };
        };
        variants = {
          cuda_arch = cuda_arch // { "90" = false; };
          # omp_as_runtime = false; # tries to build duplicate OMP targets and fails
          cuda = true;
        };
      };
      core = true;
    }
    { pkg = amdlibm;
      core = true;
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
    #blender
    cmake
    (cmake.withPrefs { version = "3.20"; }) # https://gitlab.kitware.com/cmake/cmake/-/issues/22723
    cuda
    cudnn
    curl
    #disBatch
    distcc
    doxygen
    (emacs.withPrefs { variants = { X = true; toolkit = "athena"; }; })
    fio
    gdal
    gdb
    gdrcopy
    geos
    ghostscript
    git
    git-lfs
    go
    gnuplot
    gperftools
    gpu-burn
    { pkg = gromacs;
      projection = "{name}/singlegpunode-{version}";
      environment = {
        set = { GMX_GPU_DD_COMMS = "true";
                GMX_GPU_PME_PP_COMMS = "true";
                GMX_FORCE_UPDATE_DEFAULT_GPU = "true";
        };
      };
      default = true;
    }
    grace
    hdfview
    imagemagick
    (blasPkg intel-mkl)
    (blasPkg (intel-mkl.withPrefs { version = "2017.4.239"; }))
    intel-tbb
    intel-parallel-studio
    intel-oneapi-compilers
    (blasPkg intel-oneapi-mkl)
    intel-oneapi-mpi
    intel-oneapi-tbb
    intel-oneapi-vtune
    { pkg = juliaPacks.pkgs.julia; core = true; }
    keepassxc
    latex2html
    lftp
    libffi
    libtirpc
    libzmq
    likwid
    #magma
    mercurial
    #mplayer
    #mpv
    mupdf
    nccl
    #neovim
    #nix #too old/broken
    node-js
    npm
    (rec { pkg = nvhpc;
      context = {
        # no compiler, no sub-modules
        provides = ["mpi"];
        # need to messily override module paths to only include compiler+mpi packages
        unlocked_paths = ["${pkg.spec.name}/${pkg.spec.version}-${builtins.substring (1 + builtins.stringLength builtins.storeDir) 7 pkg.out}/${pkg.spec.name}/${pkg.spec.version}"];
      };
    })
    nvtop
    octave
    openjdk
    openmm
    ilmbase openexr # hidden, deps of openvdb
    { pkg = openvdb;
      autoload = with openvdb.spec.depends; [ilmbase openexr intel-tbb];
    }
    p7zip
    papi
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
    sra-tools
    stress-ng
    subversion
    swig
    texlive
    texstudio
    tmux
    udunits
    unison
    valgrind
    (vim.withPrefs { variants = { features = "huge"; x = true; python = true; gui = true; cscope = true; lua = true; ruby = true; }; })
    #visit #needs qt <= 5.14.2, vtk dep patches?
    vmd
    vtk
    wecall
    #xscreensaver
    zsh
  ]
  ++
  map (v: mathematica.withPrefs
    { version = v;
    })
    ["12.1.1" "12.2.0"]
  ++
  map (v: matlab.withPrefs
    { version = v;
      variants = {
        key = builtins.replaceStrings ["\n" " "] ["" ""] (builtins.readFile "/mnt/sw/fi/licenses/matlab/install-${v}.key");
      };
    })
    ["R2022b"]
  ;

  compilers = mkCompilers corePacks (comp: comp // {
    pkgs = with comp.packs.pkgs; [
      /* ---------- compiler modules ---------- */
      (comp.defaulting compiler)
      arpack-ng
      cfitsio
      cgal
      eigen
      ffmpeg
      flexiblas
      gsl
      gmp
      healpix-cxx
      hwloc
      jemalloc
      #libdrm
      magma
      #mesa
      libxc
      mpc
      mpfr
      netcdf-c
      netcdf-fortran
      nfft
      nlopt
      (blasPkg (openblas.withPrefs { variants = { threads = "none"; }; }) // {
        projection = "{name}/single-{version}";
      })
      (blasPkg (openblas.withPrefs { variants = { threads = "openmp"; }; }) // {
        projection = "{name}/openmp-{version}";
      })
      (blasPkg (openblas.withPrefs { variants = { threads = "pthreads"; }; }) // {
        projection = "{name}/threaded-{version}";
      })
      openssl
      pgplot
      ucx
    ] ++
    optMpiPkgs comp.packs
    ;

    mpis = mkMpis comp (mpi: mpi // {
      pkgs = with mpi.packs.pkgs;
        lib.optionals mpi.isOpenmpi ([
          { pkg = mpi.packs.pkgs.mpi; # others are above, compiler-independent
            projection = if mpi.packs.pkgs.mpi.spec.variants.cuda then "{name}/cuda-{version}" else "{name}/{version}";
          }
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
          (trilinos.withPrefs { version = "13.2.0"; })
          (trilinos.withPrefs { version = "12.18.1"; variants = { gotype = "int"; cxxstd = "11"; }; })
        ]
        ++
        lib.optionals (comp.isCore && mpi.isCore) [
          # these are broken with intel...
          gromacs
          { pkg = gromacs.withPrefs { version = "2021.4"; variants = { plumed = true; }; };
            projection = "{name}/mpi-plumed-{version}"; }
          plumed
          (relion.withPrefs { version = "3"; })
          (relion.withPrefs { version = "4"; patches = []; })
        ]
        ++
        lib.optionals comp.isCore [
          ior
          petsc
          valgrind
        ];

      pythons = mkPythons mpi.packs (py: py // {
        /* ---------- python+mpi modules ---------- */
        view = py.packs.pythonView { pkgs = with py.packs.pkgs; [
          py-mpi4py
          py-h5py
        ]; };
        pkgs = lib.optionals (py.isCore && mpi.isCore && lib.versionMatches comp.compiler.spec.version "10:") (with py.packs.pkgs;
          [triqs] ++
          map (p: pkgMod p // { postscript = ''depends_on("triqs")''; }) [
            triqs-cthyb
            { pkg = triqs-cthyb.withPrefs { variants = { complex = true; }; };
              projection = "{name}-complex/{version}";
            }
            triqs-dft-tools
            triqs-maxent
            #triqs-omegamaxent-interface
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
        #py-backports-ssl-match-hostname #conflicts...
        #py-backports-weakref # broken?
        py-biopython
        py-bokeh
        py-bottleneck
        py-cherrypy
        py-cython
        py-dask
        #py-deeptools #pysam broken
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
        #py-ipdb #0.10.1 broken with new setuptools, needs update
        py-ipykernel
        py-ipyparallel
        py-ipywidgets
        py-ipython
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
        #py-pip
        py-pkgconfig
        #py-primefac
        py-prompt-toolkit
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
        py-python-ldap
        py-pyyaml
        py-qtconsole
        #py-ray #needs bazel 3
        py-s3fs
        #py-scikit-cuda
        py-scikit-image
        py-scikit-learn
        py-scipy
        py-seaborn
        #py-setuptools
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
      ] ++ lib.optionals (lib.versionMatches comp.compiler.spec.version "10") [
        # bazel broken with gcc 11
        #py-jax #TODO: broken
        py-torch-geometric
        #py-torchvision #doesn't support sm_90 (but torch does, and inherits archs from it!)
      ] ++ lib.optionals (lib.versionMatches py.python.version ":3.9") [
        py-psycopg2
      ])
      ).overrideView {
        ignoreConflicts = [
          # for py-pyqt/py-sip:
          "lib/python3.*/site-packages/PyQt5/__init__.py"
        ];
        exclude = [
          # cmyt, jupyter-packaging11
          "lib/python3.*/site-packages/tests"
          # torch-scatter, torch-cluster
          "lib/python3.*/site-packages/test"
        ];
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
      } // blasVirtuals corePacks.pkgs.nvhpc;
      global = {
        variants = {
          mpi = true;
        };
      };
    };
    pkgs = builtins.tail (optMpiPkgs packs) # omitting boost
      ++
      (with packs.pkgs; [
        osu-micro-benchmarks
      ]);
  };

  skylake = rec {
    packs = mkSkylake corePacks;
    mpiPacks = mkSkylake (findCore (findCore pkgStruct.compilers).mpis).packs;
    pkgs = [
      { pkg = packs.pkgs.gromacs;
        projection = "{name}/skylake-singlegpunode-{version}";
        environment = {
          set = { GMX_GPU_DD_COMMS = "true";
                  GMX_GPU_PME_PP_COMMS = "true";
                  GMX_FORCE_UPDATE_DEFAULT_GPU = "true";
          };
        };
      }
      { pkg = mpiPacks.pkgs.gromacs.withPrefs { variants = { mpi = true; }; };
        projection = "{name}/skylake-mpi-{version}";
      }
      { pkg = mpiPacks.pkgs.gromacs.withPrefs { version = "2021.4"; variants = { mpi = true; plumed = true; }; };
        projection = "{name}/skylake-mpi-plumed-{version}";
      }
    ];
  };

  nixpkgs = with corePacks.nixpkgs;
    let withGL = p: p // {
      module = (p.module or {}) // {
        environment = {
          append_path = {
            LD_LIBRARY_PATH = "/run/opengl-driver/lib";
          };
        };
      };
    }; in [
    /* -------- nixpkgs modules --------- */
    nix
    (withGL blender)
    elinks
    #evince
    feh
    (ffmpeg.override { libaomSupport = true; })
    #gimp
    #git
    #i3-env
    #inkscape
    #jabref
    #keepassx2
    kubectl
    #libreoffice
    #meshlab
    (withGL mplayer // { name = builtins.replaceStrings ["-unstable"] [""] mplayer.name; })
    (withGL mpv // { name = builtins.replaceStrings ["-with-scripts"] [""] mpv.name; })
    #pass
    #pdftk
    #rxvt-unicode
    #sage
    (withGL slack)
    (withGL (vscode.overrideAttrs (old: {
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
    })))
    #wecall
    xscreensaver
  ];

  static = [
    /* -------- misc modules --------- */
    { path = ".modulerc";
      static =
        let alias = {
          "Blast" = "blast-plus";
          "amd/aocc" = "aocc";
          "intel/mkl" = "intel-mkl";
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
        '' +
        builtins.concatStringsSep "" (builtins.map (n: ''
          hide_version("${n.spec.name}/${n.spec.version}")
        '') (with corePacks.pkgs; [ ilmbase openexr ]))
        ;
    }
  ];

};

# TODO:
#  amd/aocl (amdblis, amdlibflame, amdfftw, amdlibm, aocl-sparse, amdscalapack)
#  amd/uprof
#  py jaxlib cuda
#  py deadalus mpi: robert

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
  map (pkg: pkgMod pkg // { projection = "{name}/libcpp-{version}";
    autoload = [clangcpp.packs.pkgs.compiler]; })
    clangcpp.pkgs
  ++
  map (pkg: pkgMod pkg // { projection = "{name}/nvhpc-{version}"; })
    nvhpc.pkgs
  ++
  skylake.pkgs
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
      "lib" = ["LIBRARY_PATH" "LD_LIBRARY_PATH"];
      "lib64" = ["LIBRARY_PATH" "LD_LIBRARY_PATH"];
      "include" = ["C_INCLUDE_PATH" "CPLUS_INCLUDE_PATH"];
      "" = ["{name}_ROOT" "{name}_BASE"];
    };
    projections = {
      all = "{name}/{version}";
      "^mpi" = "{name}/mpi-{version}";
    };
    all = {
      autoload = "none";
      prerequisites = "direct";
      filter = {
        environment_blacklist = ["CC" "FC" "CXX" "F77"];
      };
    };
    boost = {
      filter = {
        # don't add numpy, setuptools deps:
        environment_blacklist = ["PYTHONPATH"];
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
    intel-oneapi-mpi = {
      environment = {
        set = {
          I_MPI_PMI_LIBRARY = "${corePacks.pkgs.slurm.out}/lib64/libpmi2.so";
        };
      };
    };
    intel-parallel-studio = {
      environment = {
        set = {
          INTEL_LICENSE_FILE = "28518@lic1.flatironinstitute.org";
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
    matlab = {
      environment = {
        set = {
          # not really necessary (included in spack matlab install)
          MLM_LICENSE_FILE = "/mnt/sw/fi/licenses/matlab/license.dat";
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

modsMod = import lmod/modules.nix gitrev corePacks mods;

in

corePacks // {
  inherit
    bootstrapPacks
    pkgStruct
    mods
    modsMod
    jupyter;

  traceModSpecs = lib.traceSpecTree (builtins.concatMap (p:
    let q = p.pkg or p; in
    q.pkgs or (if q ? spec then [q] else [])) modPkgs);
}
