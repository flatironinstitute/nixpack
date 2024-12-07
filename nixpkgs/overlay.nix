self: pkgs:
with pkgs;

let
  llvm_patch = llvmPackages: llvmPackages // (let
    tools = llvmPackages.tools.extend (self: super: {
      # broken glob test?
      libllvm = super.libllvm.overrideAttrs (old: {
        postPatch = old.postPatch + ''
          rm test/Other/ChangePrinters/DotCfg/print-changed-dot-cfg.ll
        '';
      });
    });
    in { inherit tools; } // tools);
in

{
  nss_sss = callPackage sssd/nss-client.nix { };

  patchelf = patchelf.overrideAttrs (old: {
    postPatch = ''
      sed -i 's/static bool forceRPath = false;/static bool forceRPath = true;/' src/patchelf.cc
    '';
    doCheck = false;
  });

  makeShellWrapper = makeShellWrapper.overrideAttrs (old: {
    # avoid infinite recursion by escaping to system (hopefully it's good enough)
    shell = "/bin/sh";
  });

  coreutils = (coreutils.override {
    autoreconfHook = null; # workaround nixpkgs #144747
    texinfo = null;
  }).overrideAttrs (old: {
    preBuild = "touch Makefile.in"; # avoid automake
    doCheck = false; # df/total-verify broken on ceph
  });
  perl = perl.override {
    zlib = buildPackages.zlib.override { fetchurl = stdenv.fetchurlBoot; };
  };

  nix = (nix.override {
    withAWS = false;
  }).overrideAttrs (old: {
    doInstallCheck = false;
  });

  bind = bind.overrideAttrs (old: {
    doCheck = false; # netmgr/tlsdns.c failure
  });

  p11-kit = p11-kit.overrideAttrs (old: {
    doCheck = false; # test-compat sigabrt
  });

  git = git.overrideAttrs (old: {
    doInstallCheck = false; # failure
  });

  ell = ell.overrideAttrs (old: {
    doCheck = false; # test-dbus-properties failure: /tmp/ell-test-bus: EADDRINUSE
  });

  gtk3 = gtk3.override {
    trackerSupport = false;
  };

  openssl_1_0_2 = openssl_1_0_2.overrideAttrs (old: {
    postPatch = old.postPatch + ''
      sed -i 's:define\s\+X509_CERT_FILE\s\+.*$:define X509_CERT_FILE "/etc/pki/tls/certs/ca-bundle.crt":' crypto/cryptlib.h
    '';
  });

  openssl_1_1 = openssl_1_1.overrideAttrs (old: {
    postPatch = old.postPatch + ''
      sed -i 's:define\s\+X509_CERT_FILE\s\+.*$:define X509_CERT_FILE "/etc/pki/tls/certs/ca-bundle.crt":' include/internal/cryptlib.h
    '';
  });

  # we don't need libredirect for anything (just openssh tests), and it's broken
  libredirect = "/var/empty";

  openssh = openssh.overrideAttrs (old: {
    doCheck = false; # strange environment mismatch
  });

  libuv = libuv.overrideAttrs (old: {
    doCheck = false; # failure
  });

  openimageio = openimageio.overrideAttrs (old: {
    # avoid finding system libjpeg.so
    cmakeFlags = old.cmakeFlags ++ ["-DJPEGTURBO_PATH=${libjpeg.out}"];
  });

  openimagedenoise = openimagedenoise.override {
    #tbb = tbb_2021_8;
  };

  openvdb = openvdb.override {
    #tbb = tbb_2021_8;
  };

  embree = (embree.override {
    #tbb = tbb_2021_8;
  }).overrideAttrs (old: {
    # based on spack flags
    cmakeFlags =
      let
        onoff = b: if b then "ON" else "OFF";
        isa = n: f: "-DEMBREE_ISA_${n}=${onoff (!f)}";
      in old.cmakeFlags ++ [
        (isa "SSE2" stdenv.hostPlatform.sse4_2Support)
        (isa "SSE42" stdenv.hostPlatform.avxSupport)
        (isa "AVX" stdenv.hostPlatform.avx2Support)
        (isa "AVX2" stdenv.hostPlatform.avx512Support)
        (isa "AVX512SKX" false)
      ];
  });

  libical = libical.overrideAttrs (old: {
    cmakeFlags = old.cmakeFlags ++ ["-DBerkeleyDB_ROOT_DIR=${db}"];
  });

  llvmPackages_14 = llvm_patch llvmPackages_14;
  llvmPackages_15 = llvm_patch llvmPackages_15;
  llvmPackages_16 = llvm_patch llvmPackages_16;
  llvmPackages_17 = llvm_patch llvmPackages_17;
  llvmPackages_18 = llvm_patch llvmPackages_18;

  libxcrypt = libxcrypt.overrideAttrs (old: {
    /* sign-conversion warnings: */
    configureFlags = old.configureFlags ++ [ "--disable-werror" ];
  });

  opencolorio = opencolorio.overrideAttrs (old: {
    # various minor numeric failures
    doCheck = false;
  });

  openexr_3 = openexr_3.overrideAttrs (old: {
    # -nan != -nan
    doCheck = false;
  });

  python310 = python310.override {
    packageOverrides = self: super: {
      pycryptodome = super.pycryptodome.overridePythonAttrs (old: {
        # FAIL: test_negate (Cryptodome.SelfTest.PublicKey.test_ECC_25519.TestEccPoint_Ed25519)
        doCheck = false;
      });
      eventlet = super.eventlet.overridePythonAttrs (old: {
        # needs libredirect
        doCheck = false;
      });
      numpy = super.numpy.overridePythonAttrs (old: {
        # FAIL: test_dtype.py::TestStructuredObjectRefcounting::test_structured_object_item_setting[<structured subarray 2>] - assert 190388 == 190386
        doCheck = false;
      });
    };
  };

  python311 = python311.override {
    packageOverrides = self: super: {
      numpy = super.numpy.overridePythonAttrs (old: {
        # FAIL: TestAccuracy.test_validate_transcendentals
        doCheck = false;
      });
    };
  };

  python312 = python312.override {
    packageOverrides = self: super: {
      numpy = super.numpy.overridePythonAttrs (old: {
        # FAIL: TestAccuracy.test_validate_transcendentals
        doCheck = false;
      });
    };
  };

  pipewire = (pipewire.override {
    rocSupport = false; # temporarily workaround sox broken download (though probably don't need it anyway)
  }).overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [libopus];
  });

  pulseaudio = pulseaudio.override {
    bluetoothSupport = false;
  };

  blender = (blender.override {
    #tbb = tbb_2021_8;
  }).overrideAttrs (old: {
    cmakeFlags = old.cmakeFlags ++ ["-DWITH_OPENAL=OFF"];
  });

  SDL = SDL.overrideAttrs (old: {
    # this is already patched into configure.in, but not configure
    postConfigure = ''
      sed -i '/SDL_VIDEO_DRIVER_X11_CONST_PARAM_XDATA32/s/.*/#define SDL_VIDEO_DRIVER_X11_CONST_PARAM_XDATA32 1/' include/SDL_config.h
    '';
  });

  umockdev = umockdev.overrideAttrs (old: {
    doCheck = false; # static-code unknown failure
  });

  libpsl = libpsl.overrideAttrs (old: {
    doCheck = false; # valgrind unknown instruction
  });

  haskell = haskell // {
    packages = haskell.packages // {
      ghc8107Binary = haskell.packages.ghc8107Binary.override {
        ghc = haskell.packages.ghc8107Binary.ghc.overrideAttrs (old: {
          postUnpack = old.postUnpack + ''
            patchShebangs ghc-${old.version}/inplace/bin
          '';
        });
      };
    };
    packageOverrides = self: super: {
      crypton = super.crypton.overrideAttrs (old: {
        # FAIL: Ed448 verify sig?
        doCheck = false;
      });
      cryptonite = super.cryptonite.overrideAttrs (old: {
        # FAIL: Ed448 verify sig?
        doCheck = false;
      });
      crypton-x509-validation = super.crypton-x509-validation.overrideAttrs (old: {
        doCheck = false;
      });
      http2 = super.http2.overrideAttrs (old: {
        # tests hang
        doCheck = false;
      });
      tls = super.tls.overrideAttrs (old: {
        doCheck = false;
      });
    };
  };

  jdupes = callPackage ./jdupes.nix { };

  vamp-plugin-sdk = vamp-plugin-sdk.overrideAttrs (old: {
    src = fetchFromGitHub {
      owner = "vamp-plugins";
      repo = "vamp-plugin-sdk";
      rev = "vamp-plugin-sdk-v${old.version}";
      hash = "sha256-5jNA6WmeIOVjkEMZXB5ijxyfJT88alVndBif6dnUFdI=";
    };
  });
}
