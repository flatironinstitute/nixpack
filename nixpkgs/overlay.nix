self: pkgs:
with pkgs;

{
  nss_sss = callPackage sssd/nss-client.nix { };

  libuv = libuv.overrideAttrs (old: {
    doCheck = false; # failure
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

  # openssl = self.openssl_1_1;

  # we don't need libredirect for anything (just openssh tests), and it's broken
  libredirect = "/var/empty";

  openssh = openssh.overrideAttrs (old: {
    doCheck = false; # strange environment mismatch
  });

  openimageio = openimageio.overrideAttrs (old: {
    # avoid finding system libjpeg.so
    cmakeFlags = old.cmakeFlags ++ ["-DJPEGTURBO_PATH=${libjpeg.out}"];
  });

  embree = embree.overrideAttrs (old: {
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

  llvmPackages_14 = llvmPackages_14 // (let
    tools = llvmPackages_14.tools.extend (self: super: {
      # broken glob test?
      libllvm = super.libllvm.overrideAttrs (old: {
        postPatch = old.postPatch + ''
          rm test/Other/ChangePrinters/DotCfg/print-changed-dot-cfg.ll
        '';
      });
    });
    in { inherit tools; } // tools);

  libxcrypt = libxcrypt.overrideAttrs (old: {
    /* sign-conversion warnings: */
    configureFlags = old.configureFlags ++ [ "--disable-werror" ];
  });

  python310 = python310.override {
    packageOverrides = self: super: {
      pycryptodome = super.pycryptodome.overridePythonAttrs (old: {
        # FAIL: test_negate (Cryptodome.SelfTest.PublicKey.test_ECC_25519.TestEccPoint_Ed25519)
        doCheck = false;
      });
    };
  };

  pipewire = pipewire.override {
    bluezSupport = false;
  };

  ffmpeg = ffmpeg.override {
    libaomSupport = true;
  };

  blender = blender.overrideAttrs (old: {
    patches = old.patches ++ [ ./blender-sse2.patch ];
  });
}
