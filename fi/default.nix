/* these preferences can be overriden on the command-line (and are on popeye by fi/run) */
{ os ? "rocky8"
, target ? "broadwell"
, cudaarch ? "70,80,90"
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
    rev = "c5f09b6ab6aaa589ac4ee15d366523c12d514e24";
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
    url = "https://github.com/NixOS/nixpkgs";
    ref = "release-24.11";
    rev = "ff5fd5aff0b38eca6461d9a4d64e3ea672077939";
  };

  repos = [
    ./repo
    ../spack/repo
    ./spack/var/spack/repos/builtin
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
    at-spi2-core = {
      # for gtkplus
      version = "2.48";
    };
    binutils = {
      variants = {
        gas = true;
        gold = true;
        headers = true;
        ld = true;
        compress_debug_sections = "none";
      };
    };
    blender = {
      variants = {
        cycles = true;
        ffmpeg = true;
        opensubdiv = true;
      };
    };
    blt = {
      # for raja
      #version = "0.5";
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
        fiber = true;
        filesystem = true;
        graph = true;
        #icu = true;
        iostreams = true;
        #locale = true;
        log = true;
        math = true;
        numpy = true;
        program_options = true;
        python = true;
        random = true;
        regex = true;
        serialization = true;
        signals = true;
        #stacktrace = true;
        system = true;
        test = true;
        thread = true;
        timer = true;
        cxxstd = "14";
      };
    };
    c-blosc = {
      # for openvdb
      version = "1.17.0";
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
      # for py-astropy and py-fitsio
      version = "3.49";
    };
    cli11 = {
      # for paraview
      version = "1.9.1";
    };
    conduit = {
      variants = {
        hdf5_compat = false;
        python = true;
      };
    };
    coreutils = {
      # failing
      tests = false;
    };
    cpio = rpmExtern "cpio"; # some intel installers need this -- avoid compiler dependency
    cryptsetup = {
      # needs openssl pkgconfig
      build = opensslPkgconfig;
    };
    cuda = {
      # make sure this is compatible with the image driver
      version = "12.5";
      depends = {
        libxml2 = rpmExtern "libxml2";
      };
    };
    cudnn = {
      # for torch, tensorflow, etc
      version = "8.9";
    };
    curl = {
      variants = {
        libidn2 = true;
        nghttp2 = true;  # for rust
      };
    };
    dbus = {
      variants = {
        build_system = "autotools";
      };
    };
    dejagnu = {
      # failing
      tests = false;
    };
    e2fsprogs = {
      variants = {
        fuse2fs = true;
      };
    };
    elfutils = {
      # for gdb
      variants = {
        debuginfod = true;
      };
      build = opensslPkgconfig;
    };
    embree = {
      # for blender
      variants = {
        ispc = false;
      };
    };
    ffmpeg = {
      version = "4"; # 5 has incorrect configure args
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
    fmt = {
      # for seacas, for vtk
      version = "9";
    };
    gcc = {
      version = "13";
      target = if target == "skylake-avx512" then "skylake" else target;
      variants = {
        languages = ["c" "c++" "fortran" "jit"];
        binutils = false;
      };
      build = {
        post = ''
          os.symlink("gcc", os.path.join(pkg.prefix.bin, "cc"))
        '';
      };
      patches = [./gcc-13.3-nvcc.patch];
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
      version = "1.23";
      # failing
      tests = false;
    };
    gdrcopy = {
      version = "2.4.1"; # match kernel module
      variants = {
        cuda = true;
        inherit cuda_arch;
      };
    };
    gloo = {
      # for py-torch
      variants = {
        cuda = true;
        inherit cuda_arch;
      };
    };
    gnuplot = {
      variants = {
        X = true;
      };
    };
    googletest = {
      variants = {
        cxxstd = "14";
      };
    };
    gperftools = {
      version = "2.15"; # cmake issue
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
        inherit cuda_arch;
      };
    };
    gsl = {
      # for fgsl
      version = "2.7";
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
    gtkplus = {
      variants = {
        build_system = "meson";
      };
    };
    gocryptfs = {
      # needs openssl pkgconfig
      build = opensslPkgconfig;
    };
    harfbuzz = {
      variants = {
        graphite2 = true;
      };
    };
    hdf5 = {
      version = "1.12";
      variants = {
        hl = true;
        fortran = true;
        cxx = true;
      };
    };
    hdfview = {
      build = {
        post = ''
          java_bin = os.path.join(pkg.spec["java"].prefix, "bin", "java")
          hdfview_root = spec.prefix
          with open(os.path.join(hdfview_root, 'bin', 'hdfview'), 'w') as f:
            f.write('#!/bin/bash\n'
                    f'exec {java_bin} -Xmx1024m -Djava.library.path="{hdfview_root}" '
                    f'-Dhdfview.root="{hdfview_root}" -cp "{hdfview_root}/*" hdf.view.HDFView "$@"\n')
        '';
      };
      depends = {
        hdf = {
          variants = {
            external-xdr = false;
            java = true;
            shared = true;
          };
        };
        hdf5 = {
          version = "1.14";
          variants = {
            java = true;
          };
        };
      };
    };
    idl = {
      build = {
        post = ''
          license_path = pkg.prefix.license
          license_file = "lic_server.dat" if spec.satisfies("@8.9:") else "o_licenseserverurl.txt"
          os.symlink(os.path.join("/mnt/sw/fi/licenses/idl",license_file), os.path.join(license_path, license_file))
          for d in ["flexera", "flexera-sv"]:
            dir = os.path.join(license_path, d)
            try:
              os.rmdir(dir)
            except FileNotFoundError:
              pass
            os.symlink("/tmp", dir)
        '';
      };
    };
    keepassxc = {
      variants = {
        # missing minizip dep otherwise
        autotype = true;
      };
    };
    kokkos = {
      # for trilinos
      version = "4.3.01";
    };
    libaio = {
      # needs mke2fs?
      tests = false;
    };
    libarchive = {
      # for elfutils
      variants = {
        iconv = false;
      };
    };
    libcap = rpmExtern "libcap";
    libepoxy = {
      variants = {
        #glx = false; # ~glx breaks gtkplus
      };
    };
    libfabric = {
      variants = {
        fabrics = ["udp" "rxd" "shm" "sockets" "tcp" "rxm" "verbs" "mlx"];
      };
    };
    libglx = {
      name = "opengl";
    };
    libjpeg-turbo = {
      variants = {
        libs = ["shared" "static"];
      };
    };
    libmicrohttpd = {
      # for elfutils
      version = "0.9.50";
    };
    libunwind = {
      # failing
      tests = false;
      variants = {
        # for py-py-spy
        components = {
          none = false;
          ptrace = true;
        };
      };
    };
    libwebp = {
      # for py-pillow
      variants = {
        libwebpmux = true;
        libwebpdemux = true;
      };
    };
    llvm = {
      version = "14";
      variants = {
        lua = false;
        libcxx = "project";
      };
      depends = {
        compiler = {
          # https://github.com/llvm/llvm-project/issues/62396
          version = "11";
        };
      };
    };
    lmod = {
      patches = [./lmod-no-sys-tcl.patch];
    };
    magma = {
      variants = {
        inherit cuda_arch;
      };
    };
    mathematica = {
      build = {
        post = ''
          os.symlink(pkg.global_license_file, os.path.join(pkg.prefix, pkg.license_files[0]))
        '';
      };
    };
    mbedtls = {
      variants = {
        pic = true;
      };
      tests = false;
    };
    meson = {
      # for py-pandas
      #version = "1.2.1";
    };
    mpi = {
      name = "openmpi";
    };
    music = {
      variants = {
        hdf5 = true;
      };
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
        # for netcdfcxx4
        build_system = "cmake";
      };
    };
    nix = {
      variants = {
        storedir = builtins.getEnv "NIX_STORE_DIR";
        statedir = builtins.getEnv "NIX_STATE_DIR";
        sandboxing = false;
      };
    };
    node-js = {
      #version = "19";
    };
    nvhpc = {
      variants = {
        mpi = true;
        stdpar = builtins.head (lib.splitRegex "," cudaarch);
      };
    };
    ocaml = {
      # for unison
      #version = "4.10";
      #variants = {
        #force-safe-string = false;
      #};
    };
    openblas = {
      variants = {
        threads = "pthreads";
      };
    };
    openexr = {
      # for openvdb
      version = "3.1";
    };
    opengl = {
      version = "4.6";
      extern = "/usr";
    };
    openjdk = {
      # for bazel
      version = "11";
    };
    openldap = {
      # for python-ldap
      version = "2.4";
      variants = {
        tls = "openssl";
        sasl = false;
      };
    };
    openmm = {
      variants = {
        # cuda build fails with internal gcc compiler error (11, 12.2)
        inherit cuda_arch;
        cuda = true;
      };
    };
    openmpi = {
      version = "4.0";
      variants = {
        fabrics = {
          none = false;
          ofi = false;
          ucx = true;
          psm = false;
          psm2 = false;
          verbs = true;
        };
        schedulers = {
          none = false;
          slurm = true;
        };
        pmi = true;
        internal-pmix = true;
        static = false;
        legacylaunchers = true;
        romio = false;
      };
    };
    openssl = if os == "rocky8" then opensslExtern else {};
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
    };
    pango = {
      variants = {
        X = true;
      };
    };
    papi = {
      # last official release doesn't support zen (as of 22-06-07)
      # also we have a custom icelake patch (as of 22-06-29)
      #version = "6.0.0.1-fi";
    };
    paraview = {
      variants = {
        hdf5 = true;
        python = true;
        qt = true;
        osmesa = false;
      };
    };
    patchelf = {
      # for intel-oneapi-compilers
      #version = "0.17";
    };
    pegtl = {
      # for paraview
      version = "2.8.3";
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
      version = "2.9.1";
    };
    pmix = {
      version = "4.2.2";
    };
    poppler = {
      variants = {
        glib = true;  # for latex2html
        qt = true;  # for texstudio
      };
    };
    postgresql = {
      # for py-psycopg2
      version = "15";
    };
    proj = {
      # for vtk, paraview
      version = "8.1.0";
    };
    protobuf = {
      # for py-protobuf, paraview
      version = "3.21";
    };
    py-anyio = {
      # for py-jupyter-server
      version = "3";
    };
    py-astroid = {
      depends = {
        py-setuptools = {
          version = "62";
        };
        py-wheel = {
          version = "0.37";
        };
      };
    };
    py-astropy = {
      depends = {
        py-pip = {
          version = ":23.0";
        };
        py-cython = {
          version = "3.0.0";
        };
      };
    };
    py-batchspawner = {
      version = "main.2023-11-01";
    };
    py-bigfile = {
      variants = {
        mpi = true;
      };
    };
    py-blessings = {
      depends = {
        py-setuptools = {
          version = "57";
        };
      };
    };
    py-classylss = {
      depends = {
        py-cython = {
          version = ":2";
        };
      };
    };
    py-cryptography = {
      # py-pyopenssl
      version = "38";
    };
    py-cupy = {
      variants = {
        cuda = true;
        inherit cuda_arch;
      };
      depends = {
        py-cython = {
          version = ":2";
        };
      };
    };
    py-ewah-bool-utils = {
      depends = {
        py-numpy = {
          # build only
          #version = "2";
        };
      };
    };
    py-fastrlock = {
      depends = {
        py-pip = {
          version = ":23.0";
        };
      };
    };
    py-fsspec = {
      # py-pytorch-lightning
      variants = {
        http = true;
      };
    };
    py-gast = {
      # py-pythran
      version = "0.5.3";
    };
    py-globus-sdk = {
      # for py-globus-cli
      version = "3.25.0";
      depends = {
        py-pyjwt = {
          variants = {
            crypto = true;
          };
        };
      };
    };
    py-grpcio = {
      # for py-protobuf
      version = "1.62";
      depends = { 
        py-cython = {
          version = ":2";
        };
      };
    };
    py-h5py = {
      depends = {
        py-cython = {
          version = ":2";
        };
      };
    };
    py-halotools = {
      depends = {
        py-cython = {
          version = "0.29.32";
        };
      };
    };
    py-horovod = {
      variants = {
        inherit cuda_arch;
        frameworks = ["tensorflow" "keras" "pytorch"];
      };
    };
    py-jax = {
      version = "0.4.28";
      variants = {
        inherit cuda_arch;
      };
    };
    py-jaxlib = {
      version = "0.4.28";
      variants = {
        inherit cuda_arch;
      };
      depends = {
        bazel = {
          version = "6.5.0";
        };
      };
    };
    py-jsonschema = {
      variants = {
        format-nongpl = true;
      };
    };
    py-jupyter-server = {
      # for py-jupyterlab 3
      version = "1";
    };
    py-jupyterhub = {
      version = "3";
    };
    py-jupyterlab = {
      # for py-ipyparallel, various widgets
      version = "3";
    };
    py-kdcount = {
      depends = {
        py-cython = {
          version = ":2";
        };
      };
    };
    py-m2r = {
      depends = {
        py-mistune = {
          version = ":1";
        };
      };
    };
    py-mpsort = {
      depends = {
        py-cython = {
          version = ":2";
        };
      };
    };
    py-msgpack = {
      depends = {
        py-cython = {
          version = "0.29";
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
      version = "1";
    };
    py-pandas = {
      depends = {
        py-cython = {
          version = "3.0.5";
        };
        py-meson-python = {
          version = "0.13.1";
        };
      };
    };
    py-partd = {
      # for py-versioneer dep vs py-distributed
      version = "1.4.1";
    };
    py-pfft-python = {
      depends = {
        py-cython = {
          version = ":2";
        };
      };
    };
    py-pillow = {
      variants = {
        freetype = true;
        tiff = true;
        webp = true;
        #webpmux = true;
        jpeg2000 = true;
        imagequant = true;
      };
    };
    py-protobuf = {
      # for py-tensorflow
      version = "4.21";
      variants = {
        cpp = true;
      };
    };
    py-py-cpuinfo = {
      # for py-hdf5plugin
      version = "8.0.0";
    };
    py-pyerfa = {
      depends = {
        py-numpy = {
          # build only
          #version = "2";
        };
      };
    };
    py-pyfftw = {
      version = "0.13"; # for py-numpy@1
      depends = {
        py-setuptools = {
          version = "59";
        };
        py-cython = {
          version = "0.29";
        };
      };
    };
    py-pylint = {
      depends = {
        py-setuptools = {
          version = "62";
        };
        py-wheel = {
          version = "0.37";
        };
      };
    };
    py-pymol = {
      depends = {
        py-pip = {
          version = "23.0";
        };
      };
      build = {
        post = ''
        with open(os.path.join(spec.prefix.bin, 'pymol'), 'w') as fp:
          fp.write('#!/bin/sh\n'
                   'exec python -m pymol "$@"\n'
          )
        '';
      };
    };
    py-pytest-cov = {
      depends = {
        py-coverage = {
          variants = {
            toml = true;
          };
        };
      };
    };
    py-pywavelets = {
      depends = {
        py-setuptools = {
          version = "64";
        };
        py-cython = {
          version = ":2";
        };
      };
    };
    py-pyyaml = {
      depends = {
        py-cython = {
          version = ":2";
        };
      };
    };
    py-runtests = {
      variants = {
        mpi = true;
      };
    };
    py-setuptools-scm = {
      variants = {
        toml = true;
      };
    };
    py-tensorboard = {
      version = "2.17";
    };
    py-tensorflow = {
      # for py-keras
      version = "2.17";
      variants = {
        inherit cuda_arch;
        xla = true;
      };
      depends = {
        bazel = {
          version = "6.5.0";
        };
        compiler = {
          variants = {
            # needs newer assembler
            binutils = true;
          };
        };
      };
    };
    py-urllib3 = {
      # for py-google-auth
      version = "1";
    };
    py-versioneer = {
      # for py-distributed, py-dask
      version = "0.28";
    };
    re2 = {
      # for py-tensorflow
      variants = {
        shared = true;
      };
    };
    py-libclang = {
      # for py-tensorflow
      version = "14";
    };
    py-torch = {
      variants = {
        inherit cuda_arch;
        valgrind = false;
        custom-protobuf = true;
      };
      depends = blasVirtuals {
        name = "openblas";
      }; # doesn't find flexiblas
    };
    # py-torchaudio = {
    #   build = {
    #     # torchaudio will only build in a git checkout.
    #     # spack caches git checkouts, without the .git directory.
    #     # torchaudio will only build without a spack cache!
    #     # TODO: find a better way to disable cache (installer use_cache=False?)
    #     setup = ''
    #       try:
    #         os.unlink(os.path.join(spack.caches.FETCH_CACHE.root, "_source-cache", "git", "pytorch", "audio.git", "v%s.tar.gz"%(pkg.version)))
    #       except OSError:
    #         pass
    #     '';
    #   };
    # };
    py-horovod = {
      build = {
        setup = ''
          try:
            os.unlink(os.path.join(spack.caches.FETCH_CACHE.root, "_source-cache", "git", "horovod", "horovod.git", "v%s.tar.gz"%(pkg.version)))
          except OSError:
            pass
        '';
      };
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
    py-yt = {
      depends = {
        py-numpy = {
          # build only
          #version = "2";
        };
      };
    };
    python = corePython;
    qt = {
      variants = {
        dbus = true;
        opengl = true;
      };
    };
    qmake = { name = "qt"; };
    r = {
      variants = {
        X = true;
      };
    };
    r-xml = {
      build = {
        XMLSEC_CONFIG = "/bin/false";
      };
    };
    relion = {
      variants = {
        inherit cuda_arch;
        mklfft = false;
      };
    };
    rust = {
      # needs openssl pkgconfig
      build = opensslPkgconfig;
      variants = {
        dev = true;
      };
    };
    seacas = {
      # for vtk
      version = "2022";
    };
    shadow = rpmExtern "shadow-utils";
    sleef = {
      # for py-torch
      version = "3.6.0_2024-03-20";
    };
    slurm = rpmExtern "slurm" // {
      variants = {
        #pmix = true;
        hwloc = true;
      };
    };
    sox = {
      variants = {
        mp3 = true;
      };
    };
    suite-sparse = {
      variants = {
        openmp = true;
      };
    };
    tbb = { name = "intel-oneapi-tbb"; };
    trilinos = {
      variants = {
        cxxstd = "17";
        openmp = true;
        cuda = false;
        build_type = "Release";
        amesos2 = true;
        nox = true;
        rol = true;
        stk = true;
        shards = true;
        zoltan = true;
        zoltan2 = true;
        exodus = true;

        hdf5 = true;
      };
      depends = {
        netcdf-c = {
          variants = {
            mpi = true;
            parallel-netcdf = true;
          };
        };
      };
    };
    ucx = {
      variants = {
        thread_multiple = true;
        cma = true;
        rc = true;
        dc = true;
        ud = true;
        mlx5_dv = true;
        ib_hw_tm = true;
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
    zlib-api = { name = "zlib"; };
    zlib-ng = {
      # for hdf5
      variants = {
        new_strategies = false;
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
    gcc = spec: old: {
      build = {
        setup = ''
          builder = getattr(pkg, 'builder', pkg)
          configure_args = builder.configure_args()
          configure_args.extend(('--with-arch=${spec.target}', '--with-tune=${spec.target}'))
          builder.configure_args = lambda: configure_args
        '';
      };
    };
    python = spec: old: {
      patches = if lib.versionMatches spec.version "3.11.4:" then [./python-ncursesw-py-3.11.4.patch] else [./python-ncursesw.patch];
      build = {
        post = ''
          stdlib = f"python{pkg.version.up_to(2)}"
          os.symlink("/mnt/sw/fi/python/EXTERNALLY-MANAGED",
            os.path.join(pkg.prefix.lib, stdlib, "EXTERNALLY-MANAGED"),
            )
        '';
      };
    };
    openmpi = spec: old: {
      build = {
        setup = ''
          builder = getattr(pkg, 'builder', pkg)
          configure_args = builder.configure_args()
          configure_args.append('CPPFLAGS=-I/usr/include/infiniband')
          # avoid openmpi1 internal hwloc libXNVCtrl link
          configure_args.append('enable_gl=no')
          builder.configure_args = lambda: configure_args
        '';
        post = ''
          mca_conf_path = os.path.join(pkg.prefix.etc, "openmpi-mca-params.conf")
          with open(mca_conf_path, 'a') as f:
              f.write("""
          oob_tcp_if_exclude = idrac,lo,ib0,10.250.112.0/20
          btl_tcp_if_exclude = idrac,lo,ib0,10.250.112.0/20

          btl_openib_if_exclude = i40iw0,i40iw1,mlx5_1
          btl_openib_warn_nonexistent_if = 0

          mpi_yield_when_idle = 1
          #btl_openib_receive_queues=P,128,2048,1024,32:S,2048,2048,1024,64:S,12288,2048,1024,64:S,65536,2048,1024,64
          btl=^openib
          pml=ucx
          pml_ucx_tls=any
          """)
        '' + (if lib.versionMatches spec.version "4" then ''
          help_oob_path = os.path.join(pkg.prefix.share, "openmpi/help-oob-tcp.txt")
          with open(help_oob_path, 'r') as f:
              help_oob = f.read()
          with open(help_oob_path, 'w') as f:
              f.write(help_oob.replace(
                "[invalid if_inexclude]\nWARNING: An invalid value was given for oob_tcp_if_%s.  This\nvalue will be ignored.\n\n  Local host: %s\n  Value:      %s\n  Message:    %s\n#\n",
                "[invalid if_inexclude]\nIgnoring value for oob_tcp_if_%s on %s (%s: %s).\n(You can safely ignore this message.)\n#\n"))
        '' else "");
      };
    };
    intel-oneapi-mpi = spec: old: {
      /* hack so we can have a separate set of intel-mpi packages (intel compiler + intel mpi vs. core compiler + intel mpi) */
      depends = removeAttrs old.depends ["compiler"];
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
    py-cython = spec: old: {
      depends = old.depends // {
        py-setuptools = {
          deptype = ["build"];
        };
      };
    };
    py-distributed = spec: old: {
      depends = old.depends // {
        py-tornado = {
          version = "6.0.4:";
        };
      };
    };
    py-jupyterlab = spec: old: {
      depends = old.depends // {
        py-jinja2 = {
          version = "3.0.3:";
          deptype = ["build" "run"];
        };
      };
    };
    py-matplotlib = spec: old: {
      depends = old.depends // {
        freetype = {
          deptype = ["build" "link"];
        };
      };
    };
    py-numpy = spec: old: {
      depends = old.depends // {
        py-setuptools = {
          deptype = ["build"];
        };
      };
    };
    py-pycuda = spec: old: {
      /* overaggresive variants */
      depends = old.depends // {
        boost = if old.depends.boost == null then null else old.depends.boost // {
          variants = {};
        };
      };
    };
    xcb-proto = spec: old: {
      depends = old.depends // {
        python = {
          deptype = ["build"];
        };
      };
    };
    py-gevent = spec: old: {
      # kill py-cython conflict
      conflicts = [];
    };
    py-numexpr = spec: old: {
      depends = old.depends // {
        py-numpy = {
          # allow 1.26?
          deptype = ["build" "run"];
        };
      };
    };
    py-protobuf = spec: old: {
      # kill 3.11 conflict (using whl instead)
      conflicts = [];
    };
    py-tensorflow = spec: old: {
      depends = old.depends // {
        patchelf = {
          deptype = ["build"];
        };
        py-numpy = {
          # remove incorrect upper-bound
          deptype = ["build" "run"];
        };
      };
    };
    py-torch = spec: old: {
      depends = old.depends // {
        py-pybind11 = {
          # remove upper-bound
          deptype = ["build" "link" "run"];
        };
      };
    };
    py-sqlalchemy = spec: old: {
      depends = old.depends // {
        py-typing-extensions = {
          version = "4.2.0:";
          deptype = ["build" "run"];
        };
      };
    };
    /* downloads its own libvips, and spack libvips is broken */
    npm = spec: old: {
      depends = builtins.removeAttrs old.depends ["libvips"];
    };
    texlive = spec: old: {
      # not really sure, but this is what we had
      depends = removeAttrs old.depends ["poppler"];
    };
    /* fix LIBRARY_PATH ordering wrt system /lib64 for libraries with different major versions */
    boost = lib64Link;
    fftw = lib64Link;
    gsl = lib64Link;
    hdf5 = spec: old: lib64Link // {
      depends = builtins.removeAttrs old.depends ["mpich"]; # broken conditional dep
    };

    julia = spec: old: {
      depends = old.depends // {
        llvm = {
          deptype = ["build" "link" "run"];
        };
      };
    };
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
    target = target;
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
    openssl = opensslExtern;
    perl = rpmExtern "perl";
    pkgconfig = {};
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
};

cuda_arch = { none = false; } // builtins.listToAttrs
  (map (a: { name = a; value = true; })
    (if builtins.isString cudaarch then lib.splitRegex "," cudaarch else cudaarch));

format_cudaarch = (dot: sep: builtins.concatStringsSep sep
  (map (v: let L = builtins.stringLength v; in
      builtins.concatStringsSep dot
        [ (builtins.substring 0 (L - 1) v) (builtins.substring (L - 1) 1 v) ]
      )
    (lib.splitRegex "," cudaarch)
  )
);

mkSkylake = base: base.withPrefs {
  global = {
    target = "skylake_avx512";
    resolver = base;
  };
};

mkCompiler = base: compiler: rec {
  inherit compiler;
  isCore = compiler == { name = "gcc"; };
  packs = if isCore then base else
    base.withCompiler compiler;
  defaulting = pkg: { default = isCore; inherit pkg; };
};

mkCompilers = base: gen:
  builtins.map (comp: gen (mkCompiler base comp))
  [ /* -------- compilers -------- */
    { name = "gcc"; }
  ];

mkMpi = comp: mpi: {
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
  isCudaAware = (mpi.variants or {}).cuda or false;
};

mkMpis = comp: gen:
  builtins.map (mpi: gen (mkMpi comp mpi))
  ([ /* -------- mpis -------- */
    { name = "openmpi"; }
  ] ++ lib.optionals comp.isCore [
    { name = "intel-oneapi-mpi"; }
    { name = "openmpi"; version = "4.1"; }
    { name = "openmpi"; version = "5.0"; variants = { legacylaunchers = null; pmi = null; };}
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
            mlx5_dv = true;
            ib_hw_tm = true;
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

opensslExtern = rpmExtern "openssl" // {
  variants = {
    fips = false;
  };
};

linkfiles = name: files: derivation {
  system = builtins.currentSystem;
  inherit name;
  builder = ./linkfiles.sh;
  args = files;
};

opensslPkgconfig = if os == "rocky8" then {
  PKG_CONFIG_PATH = linkfiles "openssl-pkgconfig" [
    "/usr/lib64/pkgconfig/openssl.pc"
    "/usr/lib64/pkgconfig/libssl.pc"
    "/usr/lib64/pkgconfig/libcrypto.pc"
  ];
} else {};

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

corePython = { version = "3.10"; };

mkPython = base: version:
  let python = {
      inherit version;
      variants = {
        tkinter = true; # break dependency cycle
      };
    }; in {
    python = python;
    isCore = version == corePython.version;
    packs = withPython base python;
  };
  
mkPythons = base: gen:
  builtins.map (version: gen (mkPython base version))
  [ /* -------- pythons -------- */
    "3.10"
    "3.11"
  ];

pyCensor = [
  { name = "py-setuptools"; version = ":67"; } # various dep
  { name = "py-pip"; version = ":23.0"; } # py-scipy dep
  { name = "py-wheel"; version = ":0.37"; } # py-scipy dep
  { name = "py-cython"; version = ":3.0.5"; } # various dep
  { name = "py-jupyter-packaging7"; } # py-jupyterlab-widget dep
  { name = "py-meson-python"; version = "0.13.1"; } # py-pandas dep
];

pyView = pl: corePacks.pythonView {
  pkgs = builtins.filter (x: !(builtins.any (lib.specMatches x.spec) pyCensor))
    (lib.findDeps (x: lib.hasPrefix "py-" x.name) pl);
  exclude = "npm-cache";
};

rView = corePacks.view {
  pkgs = lib.findDeps (x: lib.hasPrefix "r-" x.name) (import ./r.nix corePacks);
};

hdf5Pkgs = packs: with packs.pkgs; [
  (hdf5.withPrefs { version = "1.10"; })
  { pkg = hdf5; # default 1.12
    default = true;
  }
  (hdf5.withPrefs { version = "1.14"; })
];

/* packages that we build both with and without mpi */
optMpiPkgs = packs: with packs.pkgs; [
  arpack-ng
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
      version = "1.11";
      build = {
        # https://github.com/spack/spack/issues/32085
        post = ''
          os.symlink("/etc/ssl/certs/ca-certificates.crt", os.path.join(pkg.prefix.share, "julia/cert.pem"))
          os.symlink(os.path.join(pkg.spec["llvm"].prefix, "bin", "lld"), os.path.join(pkg.prefix.bin, "lld"))
        '';
      };
    };
    llvm = {
      version = "16.0.6";
      variants = {
        internal_unwind = false;
        libunwind = "none";
        llvm_dylib = true;
        lld = true;
        link_llvm_dylib = true;
        lua = false;
        targets = {
          none = false;
          amdgpu = true;
          bpf = true;
          nvptx = true;
          webassembly = true;
        };
        version_suffix = "jl";
        shlib_symbol_version = "JL_LLVM_16.0";
      };
      patches = [(builtins.fetchurl 
        "https://raw.githubusercontent.com/spack/patches/d042ae8f41493547d4263d249a13546f2c971972/julia/4997cd3006a3171d9b33f9a72ff9fdadc84e91a7c86aa044dcf495eef3a02893.patch"
      )];
    };
    libuv-julia = {
      version = "1.48.0";
    };
    mbedtls = {
      version = "2.28";
      variants = {
        libs = ["shared"];
        pic = true;
        build_system = "cmake"; # for pkgconfig for curl for elfutils
      };
    };
    nghttp2 = {
      version = "1.59";
    };
    openblas = {
      variants = {
        ilp64 = true;
        symbol_suffix = "64_";
        threads = "openmp";
      };
    };
    openlibm = {
      version = "0.8";
    };
    curl = {
      variants = {
        libssh2 = true;
        nghttp2 = true;
        tls = { mbedtls = true; openssl = false; };
      };
    };
    libblastrampoline = {
      version = "5.11:";
    };
    libgit2 = {
      version = "1.7";
    };
    libssh2 = {
      version = "1.11";
      variants = {
        crypto = "mbedtls";
      };
    };
    suite-sparse = {
      version = "7.7.0";
    };
  } // blasVirtuals {
    /* don't use flexiblas */
    name = "openblas";
  };
};

pkgStruct = {
  pkgs = with corePacks.pkgs; [
    /* ------------ Core modules ------------ */
    (gcc.withPrefs { version = "11"; })
    (gcc.withPrefs { version = "14"; })
    { pkg = llvm;
      default = true;
    }
    { pkg = llvm.withPrefs {
        version = "16";
        variants = {
          libcxx = "runtime";
        };
      };
      environment = {
        append_path = {
          LD_LIBRARY_PATH = "{prefix}/lib/x86_64-unknown-{platform}-gnu";
          LIBRARY_PATH = "{prefix}/lib/x86_64-unknown-{platform}-gnu";
        };
      };
      autoload = [hwloc];
    }
    { pkg = llvm.withPrefs {
        version = "18";
        variants = {
          libcxx = "runtime";
        };
      };
      environment = {
        append_path = {
          LD_LIBRARY_PATH = "{prefix}/lib/x86_64-unknown-{platform}-gnu";
          LIBRARY_PATH = "{prefix}/lib/x86_64-unknown-{platform}-gnu";
        };
      };
      autoload = [hwloc];
    }
    amdlibm
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
    apptainer
    binutils
    blast-plus
    #blender
    btop
    cmake
    { pkg = cuda;
      default = true;
    }
    cudnn
    curl
    distcc
    doxygen
    (emacs.withPrefs { variants = { X = true; toolkit = "athena"; }; })
    fio
    freetype
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
    grace
    graphviz
    hdfview
    imagemagick
    intel-oneapi-advisor
    intel-oneapi-compilers
    (blasPkg intel-oneapi-mkl)
    intel-oneapi-mpi
    intel-oneapi-tbb
    intel-oneapi-vtune
    { pkg = juliaPacks.pkgs.julia; }
    keepassxc
    latex2html
    lftp
    libffi
    libtiff
    libtirpc
    libzmq
    likwid
    mercurial
    mupdf
    {
      pkg = music.withPrefs {variants = { single_prec = false; }; };
      projection = "{name}/double-{version}";
    }
    {
      pkg = music.withPrefs {variants = { single_prec = true; }; };
      projection = "{name}/single-{version}";
    }
    nccl
    #nix #too old/broken
    ninja
    node-js
    { pkg = npm;
      autoload = [node-js];
    }
    (rec { pkg = nvhpc;
      environment = let
        cudaLib = "{prefix}/Linux_x86_64/{version}/cuda/lib64";
      in {
        prepend_path = {
          LD_LIBRARY_PATH = cudaLib;
          LIBRARY_PATH = cudaLib;
        };
      };
      context = {
        # no compiler, no sub-modules
        provides = ["mpi"];
        # need to messily override module paths to only include compiler+mpi packages
        unlocked_paths = ["${pkg.spec.name}/${pkg.spec.version}-${builtins.substring (1 + builtins.stringLength builtins.storeDir) 7 pkg.out}/${pkg.spec.name}/${pkg.spec.version}"];
      };
    })
    nvtop
    octave
    oneapi-level-zero
    openjdk
    openmm
    ilmbase openexr # hidden, deps of openvdb
    { pkg = openvdb;
      autoload = with openvdb.spec.depends; [ilmbase openexr intel-oneapi-tbb];
    }
    p7zip
    papi
    #paraview
    #pdftk #needs gcc java (gcj)
    perl
    petsc
    pixz
    postgresql
    proj
    protobuf
    {
      pkg = py-py-spy;
      # remove leading py-
      projection = "py-spy/{version}";
    }
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
    ruby
    rust
    smartmontools
    sox
    sra-tools
    stress-ng
    subversion
    swig
    texlive
    texstudio
    tmux
    udunits
    #unison #needs ~force-safe-string, incompatible with modern ocaml
    valgrind
    (vim.withPrefs { variants = { features = "huge"; x = true; python = true; gui = true; cscope = true; lua = true; ruby = true; }; })
    #visit #needs qt <= 5.14.2, vtk dep patches?
    vmd
    vtk
    zsh
  ]
  ++
  map (v: mathematica.withPrefs
    { version = v;
    })
    ["12.3.0" "13.2.1"]
  ++
  map (v: matlab.withPrefs
    { version = v;
      variants = {
        key = builtins.replaceStrings ["\n" " "] ["" ""] (builtins.readFile "/mnt/sw/fi/licenses/matlab/install-${v}.key");
      };
    })
    ["R2023a" "R2023b"]
  ++
  map (v: idl.withPrefs
    { version = v;
    })
    ["9.0"]
  ;

  compilers = mkCompilers corePacks (comp: comp // rec {
    pkgs = with comp.packs.pkgs; [
      /* ---------- compiler modules ---------- */
      (comp.defaulting compiler)
      cfitsio
      cgal
      eigen
      fgsl
      ffmpeg
      flexiblas
      gsl
      gmp
      hdf5-blosc
      healpix
      #highway #avx instruction build errors
      hwloc
      jemalloc
      libiconv
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
      #openssl
      pgplot
      {
        pkg = rockstar;
        postscript = ''
          whatis("Short description: Peter Behroozi's Rockstar (https://bitbucket.org/gfcstanford/rockstar)")
          help([[Peter Behroozi's Rockstar (https://bitbucket.org/gfcstanford/rockstar)]])
        '';
      }
      {
        pkg = rockstar.withPrefs { version = "galaxies"; };
        postscript = ''
          whatis("Short description: Andrew Wetzel's rockstar-galaxies (https://bitbucket.org/awetzel/rockstar-galaxies)")
          help([[Andrew Wetzel's rockstar-galaxies (https://bitbucket.org/awetzel/rockstar-galaxies)]])
        '';
      }
      suite-sparse
      ucx
    ] ++
    optMpiPkgs comp.packs
    ;

    mpis = mkMpis comp (mpi: mpi // {
      pkgs = with mpi.packs.pkgs;
        lib.optionals mpi.isOpenmpi ([
          { pkg = mpi.packs.pkgs.mpi; # others are above, compiler-independent
            projection = if mpi.packs.pkgs.mpi.spec.variants.cuda then "{name}/cuda-{version}" else "{name}/{version}";
            default = mpi.isCore;
          }
        ])
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
        ]
        ++
        lib.optionals (comp.isCore && mpi.isCore) [
          { pkg = netlib-scalapack;  # MKL provies Intel ScaLAPACK
            projection = "scalapack/{version}"; }
          (relion.withPrefs { version = "4"; })
        ]
        ++
        lib.optionals mpi.isCudaAware [
          gromacs
          { pkg = gromacs.withPrefs { version = "=2023"; variants = { plumed = true; }; };
            projection = "{name}/mpi-plumed-{version}"; }
          plumed
        ]
        ++
        lib.optionals comp.isCore [
          ior
          valgrind
        ];

      pythons = map (basePython:
        let py = mkPython mpi.packs basePython.python.version; in
        py // {
        /* ---------- python+mpi modules ---------- */
        view = py.packs.pythonView { pkgs = with py.packs.pkgs; [
          py-mpi4py
          py-bigfile
          py-h5py
          py-mpsort
          py-pfft-python
          py-pmesh
          py-runtests
          py-nbodykit
        ]; };
        pkgs = lib.optionals (py.isCore && mpi.isCore && comp.isCore) (with py.packs.pkgs;
          [(pkgMod triqs // {
            postscript = ''
              depends_on("openmpi/${openmpi.spec.version}")
              depends_on("fftw/mpi-${fftw.spec.version}")
              depends_on("hdf5/mpi-${hdf5.spec.version}")
              depends_on("python-mpi/${python.spec.version}")
            '';
            environment = {
              append_path = {
                PYTHONPATH = "${basePython.view}/lib/python${basePython.python.version}/site-packages";
              };
            };
            core = true; # avoid hiding behind gcc/12
          })] ++
          map (p: pkgMod p // { postscript = ''depends_on("triqs/mpi-${triqs.spec.version}")''; core = true; }) [
            triqs-cthyb
            { pkg = triqs-cthyb.withPrefs { variants = { complex = true; }; };
              projection = "{name}-complex/{version}";
            }
            triqs-dft-tools
            triqs-maxent
            triqs-omegamaxent-interface
            triqs-tprf
            triqs-ctseg
            triqs-hartree-fock
            triqs-hubbardi
          ]
        );
      }) pythons;
    });

    pythons = mkPythons comp.packs (py: py // {
      view = with py.packs.pkgs; (pyView ([
        /* ---------- python packages ---------- */
        python
        python-venv
        gettext
        meson
        py-asdf
        py-asdf-standard
        py-asdf-transform-schemas
        py-asdf-unit-schemas
        py-astropy
        py-autopep8
        #py-backports-ssl-match-hostname #conflicts...
        #py-backports-weakref # broken?
        py-biopython
        py-black
        py-bokeh
        py-bottleneck
        py-cachey
        py-cherrypy
        py-classylss
        py-click
        py-corrfunc
        py-coverage
        py-cython
        py-dask
        py-disbatch
        #py-deeptools #pysam broken
        #py-einsum2
        py-emcee
        py-fitsio
        py-flask
        py-flask-socketio
        py-fusepy
        #py-fuzzysearch
        #py-fwrap
        py-globus-cli
        py-globus-sdk
        #py-ggplot
        #py-glueviz
        #py-gmpy2
        py-gpustat
        py-graphviz
        py-h5py
        py-hdf5plugin
        py-healpy
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
        py-kdcount
        #py-leveldb
        #py-llfuse
        py-mako
        #py-matlab-wrapper
        py-matplotlib
        py-meson-python
        py-mypy
        py-mcfit
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
        py-cupy
        py-pyfftw
        py-pygments
        py-pylint
        #py-pyreadline
        #py-pysnmp
        #py-pystan
        py-pytest
        #py-python-gflags
        #py-python-hglib
        py-python-ldap
        py-pyyaml
        #py-ray #needs bazel 3
        py-ruff
        #py-s3fs # botocore deps
        #py-scikit-cuda
        py-scikit-image
        py-scikit-learn
        py-scipy
        py-seaborn
        #py-setuptools
        py-shapely
        py-sharedmem
        #py-sip
        py-sphinx
        py-sqlalchemy
        #py-statistics
        py-sympy
        #py-tess
        py-toml
        py-twisted
        py-typer
        py-virtualenv
        py-wcwidth
        #py-ws4py
        #py-xattr #broken: missing pip dep
        #py-yep
        py-yt

        py-protobuf
        py-torch
        py-torch-scatter
        py-psycopg2
        py-tensorflow

        #py-horovod #incompatible py-torch 2.1
        py-jax
        py-keras
        #py-lightning-fabric #included in pytorch-lightning
        py-pytensor
        py-pytorch-lightning

        # py-torchaudio  # breaks on import
        py-torchvision
        py-halotools
        py-pymc
        py-xarray
      ] ++
      lib.optionals (
        lib.versionMatches py.python.version ":3.10"
        )[
        # Uses old py-sip; won't build against 3.11
        py-envisage
        py-pymol
        py-pyqt5
        py-qtconsole
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

  intel = let comp = mkCompiler corePacks corePacks.pkgs.intel-oneapi-compilers; in comp // rec {
    pkgs = hdf5Pkgs comp.packs ++ [mpi.packs.pkgs.mpi];
    mpi = let mpi = mkMpi comp comp.packs.pkgs.intel-oneapi-mpi; in mpi // {
      pkgs = with mpi.packs.pkgs; [
        osu-micro-benchmarks
      ] /* ++ optMpiPkgs mpi.packs */; # boost broken
    };
  };

  /* -------- clang libcpp modules --------- */
  clangcpp = let comp = mkCompiler corePacks corePacks.pkgs.llvm; in comp // {
    pkgs = [
      (comp.packs.pkgs.boost.withPrefs {
        variants = corePacks.prefs.package.boost.variants // {
          clanglibcpp = true;
          python = false;
          numpy = false;
        };
      })
    ];
  };

  nvhpc = let
    comp = mkCompiler corePacks corePacks.pkgs.nvhpc;
    mpi = mkMpi comp corePacks.pkgs.nvhpc;
    in comp // mpi // {
      pkgs = with mpi.packs.pkgs; [
        (fftw.withPrefs {
          variants = {
            openmp = true;
            precision = ["float" "double" "long_double"];
          };
        })
        osu-micro-benchmarks
      ];
    };

  skylake = rec {
    packs = mkSkylake corePacks;
    mpiPacks = mkSkylake (builtins.head
        (builtins.filter (x: x.isCudaAware) (findCore pkgStruct.compilers).mpis)
      ).packs;
    pkgs = [
      { pkg = mpiPacks.pkgs.gromacs.withPrefs { variants = { mpi = true; }; };
        projection = "{name}/skylake-mpi-{version}";
      }
      { pkg = mpiPacks.pkgs.gromacs.withPrefs { version = "=2023"; variants = { mpi = true; plumed = true; }; };
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
    #(withGL blender)
    elinks
    #evince
    feh
    (ffmpeg-full.override {
      withSamba = false;
      samba = null;
      withFrei0r = false;
      frei0r = null;
      withXavs = false;
      xavs = null;
    } // { name = builtins.replaceStrings ["-full"] [""] ffmpeg-full.name; module = { default = true; }; })
    #gimp
    #git
    #i3-env
    #inkscape
    #jabref
    #keepassx2
    kubectl
    linuxKernel.packages.linux_6_1.perf
    #libreoffice
    #meshlab
    (withGL mplayer // { name = builtins.replaceStrings ["-unstable"] [""] mplayer.name; })
    (withGL mpv // { name = builtins.replaceStrings ["-with-scripts"] [""] mpv.name; })
    neovim
    pandoc
    #pass
    #pdftk
    rav1e
    #rxvt-unicode
    #sage
    #(withGL slack)
    /* (withGL (vscode.overrideAttrs (old: {
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
    }))) */
    #wecall
    xmedcon
    xscreensaver
  ];

  docker = (import ./docker corePacks);

  static = [
    /* -------- misc modules --------- */
    { path = ".modulerc";
      static =
        let alias = {
          "Blast" = "blast-plus";
          "amd/aocc" = "aocc";
          "healpix-cxx" = "healpix";
          "latex" = "texlive";
          "lib/arpack" = "arpack-ng";
          "lib/boost" = "boost";
          "lib/eigen" = "eigen";
          "lib/fftw2" = "fftw/2";
          "lib/fftw3" = "fftw/3";
          "lib/gmp" = "gmp";
          "lib/gsl" = "gsl";
          "lib/hdf5" = "hdf5";
          "lib/healpix" = "healpix";
          "lib/mpc" = "mpc";
          "lib/mpfr" = "mpfr";
          "lib/netcdf" = "netcdf-c";
          "lib/NFFT" = "nfft";
          "lib/openblas" = "openblas";
          "lib/openmm" = "openmm";
          "nodejs" = "node-js";
          "nvidia/nvhpc" = "nvhpc";
          "openmpi4" = "openmpi/4";
          "perl5" = "perl/5";
          "python3" = "python/3";
          "qt5" = "qt/5";
          "singularity" = "apptainer";
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

jupyterPacks = corePacks.withPrefs {
  label = "jupyterhub";
  global = {
    resolver = null;
  };
  package = {
    py-jupyter-remote-desktop-proxy = {
      version = "main";
    };
    py-jupyter-server = {
      version = "2";
    };
    py-jupyterlab = {
      version = "4";
    };
  };
};

jupyterBase = pyView (with jupyterPacks.pkgs; [
  python
  python-venv
  py-jupyterhub
  py-jupyterlab
  py-batchspawner
  node-js
  py-bash-kernel
  py-jupyter-remote-desktop-proxy
  #py-jupyterlmod
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
        ]
      ) pythons
    ) compilers
    ++
    [
      { pkg = rView;
        kernelSrc = import ../jupyter/kernel/ir jupyterPacks {
          pkg = rView;
          jupyter = jupyterBase;
        };
        prefix = "${rView.name}";
        note = "${lib.specName rView.spec}";
        env = {
          R_LIBS_SITE = "${rView}/rlib/R/library";
        };
      }
      { pkg = jupyterPacks.pkgs.py-bash-kernel;
        kernelSrc = import ../jupyter/kernel/bash jupyterPacks {
          pkg = jupyterBase;
          jupyter = jupyterBase;
        };
        env = {
          PYTHONHOME = null;
        };
      }
    ]
  ) ++
  [ (jupyterPacks.nixpkgs.x11vnc.overrideAttrs (old: {
      patches = old.patches ++ [
        (corePacks.nixpkgs.fetchpatch {
          name = "resize.patch";
          url = "https://github.com/LibVNC/x11vnc/pull/107/commits/4b64054bbc05395478cd97012ed5a004338d46ab.patch";
          sha256 = "XYD0s4hsgaBwwtI8f+EF5wLWVhjDbCMQEDBl9CtTosM=";
        })
      ];
    }))
  ]
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
  map (pkg: pkgMod pkg // { projection = "{name}/intel-{version}"; })
    intel.pkgs
  ++
  map (pkg: pkgMod pkg // { projection = "{name}/intel-mpi-{version}"; })
    intel.mpi.pkgs
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
  [ docker.module ]
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
      "^mpi" = "{name}/mpi-{version}"; # no longer works
      "^openmpi" = "{name}/mpi-{version}";
      "^intel-oneapi-mpi" = "{name}/mpi-{version}";
    };
    all = {
      autoload = "none";
      prerequisites = "direct";
      filter = {
        exclude_env_vars = ["CC" "FC" "CXX" "F77"
          "XDG_DATA_DIRS" "GI_TYPELIB_PATH" "XLOCALEDIR"];
      };
    };
    boost = {
      filter = {
        # don't add numpy, setuptools deps:
        exclude_env_vars = ["PYTHONPATH"];
      };
    };
    cuda = {
      environment = {
        set = {
          # set target arches for common cuda software
          TORCH_CUDA_ARCH_LIST = format_cudaarch "." ";";  # 7.0;8.0
          TCNN_CUDA_ARCHITECTURES = format_cudaarch "" ";";  # 70;80
          HOROVOD_BUILD_CUDA_CC_LIST = format_cudaarch "" ",";  # 70,80

          HOROVOD_CUDA_HOME = "{prefix}";
        };
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
          # not really necessary (included in spack intal)
          INTEL_LICENSE_FILE = "/mnt/sw/fi/licenses/intel/license.lic";
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
    python = {
      environment = {
        set = {
          PYTHONNOUSERSITE = "1";
        };
      };
    };
    py-mpi4py = {
      autoload = "direct";
    };
    "python+tkinter" = {
      environment = {
        set = {
          TCLLIBPATH = "{^tk.prefix}/lib";
        };
      };
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
    jupyter
    juliaPacks;

  traceModSpecs =
    let filterSpecs = builtins.concatMap (p:
      let q = p.pkg or p; in
      if q ? pkgs then filterSpecs q.pkgs else if q ? spec then [q] else []);
    in lib.traceSpecTree (filterSpecs modPkgs);
}
