self: pkgs:
with pkgs;

{
  gnutls = gnutls.overrideAttrs (old: {
    doCheck = false; # failure test-getaddrinfo
  });
  libgpg-error = libgpg-error.overrideAttrs (old: {
    doCheck = false; # failure FAIL: t-argparse 1.42
  });
  p11-kit = p11-kit.overrideAttrs (old: {
    doCheck = false; # failure ERROR: test-path - missing test plan
  });

  nss_sss = callPackage sssd/nss-client.nix { };

  libuv = libuv.overrideAttrs (old: {
    doCheck = false; # failure
  });

  libffi = libffi.overrideAttrs (old: {
    doCheck = false; # failure
  });

  coreutils = (coreutils.override {
    autoreconfHook = null; # workaround nixpkgs #144747
  }).overrideAttrs (old: {
    preBuild = "touch Makefile.in"; # avoid automake
    doCheck = false; # df/total-verify broken on ceph
                     # failure test-getaddrinfo
  });

  nix = (nix.override {
    withAWS = false;
  }).overrideAttrs (old: {
    patches = [../patch/nix-ignore-fsea.patch];
    doInstallCheck = false;
  });

  # `fetchurl' downloads a file from the network.
  fetchurl = if stdenv.buildPlatform != stdenv.hostPlatform
    then buildPackages.fetchurl # No need to do special overrides twice,
    else makeOverridable (import (pkgs.path + "/pkgs/build-support/fetchurl")) {
      inherit lib stdenvNoCC buildPackages;
      inherit cacert;
      curl = buildPackages.curlMinimal.override (old: rec {
        # break dependency cycles
        fetchurl = stdenv.fetchurlBoot;
        zlib = buildPackages.zlib.override { fetchurl = stdenv.fetchurlBoot; };
        pkg-config = buildPackages.pkg-config.override (old: {
          pkg-config = old.pkg-config.override {
            fetchurl = stdenv.fetchurlBoot;
          };
        });
        perl = buildPackages.perl.override { fetchurl = stdenv.fetchurlBoot; inherit zlib; };
        openssl = buildPackages.openssl.override {
          fetchurl = stdenv.fetchurlBoot;
          buildPackages = {
            coreutils = (buildPackages.coreutils.override rec {
              fetchurl = stdenv.fetchurlBoot;
              inherit perl;
              xz = buildPackages.xz.override { fetchurl = stdenv.fetchurlBoot; };
              gmp = null;
              aclSupport = false;
              attrSupport = false;
              autoreconfHook = null; # workaround nixpkgs #144747
              texinfo = null;
            }).overrideAttrs (_: {
              preBuild = "touch Makefile.in"; # avoid automake
            });
            inherit perl;
          };
          inherit perl;
        };
        libssh2 = buildPackages.libssh2.override {
          fetchurl = stdenv.fetchurlBoot;
          inherit zlib openssl;
        };
        # On darwin, libkrb5 needs bootstrap_cmds which would require
        # converting many packages to fetchurl_boot to avoid evaluation cycles.
        # So turn gssSupport off there, and on Windows.
        # On other platforms, keep the previous value.
        gssSupport =
          if stdenv.isDarwin || stdenv.hostPlatform.isWindows
            then false
            else old.gssSupport or true; # `? true` is the default
        libkrb5 = buildPackages.libkrb5.override {
          fetchurl = stdenv.fetchurlBoot;
          inherit pkg-config perl openssl;
          keyutils = buildPackages.keyutils.override { fetchurl = stdenv.fetchurlBoot; };
        };
        nghttp2 = buildPackages.nghttp2.override {
          fetchurl = stdenv.fetchurlBoot;
          inherit pkg-config;
          enableApp = false; # curl just needs libnghttp2
          enableTests = false; # avoids bringing `cunit` and `tzdata` into scope
        };
      });
    };  git = git.overrideAttrs (old: {
    doCheck = false; # failure
    doInstallCheck = false; # failure
  });

  gtk3 = gtk3.override {
    trackerSupport = false;
  };

  autogen = autogen.overrideAttrs (old: {
    postInstall = old.postInstall + ''
      # remove $TMPDIR/** from RPATHs
      for f in "$bin"/bin/*; do
        local nrp="$(patchelf --print-rpath "$f" | sed -E 's@(:|^)'$TMPDIR'[^:]*:@\1@g')"
        patchelf --set-rpath "$nrp" "$f"
      done
    '';
  });

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

  openssl = self.openssl_1_1;

  openssh = openssh.overrideAttrs (old: {
    doCheck = false; # strange environment mismatch
  });

  openimageio = openimageio.overrideAttrs (old: {
    # avoid finding system libjpeg.so
    cmakeFlags = old.cmakeFlags ++ ["-DJPEGTURBO_PATH=${libjpeg.out}"];
  });

  embree = embree.overrideAttrs (old: {
    # fix build (should be dynamic based on arch? see spack)
    cmakeFlags = old.cmakeFlags ++ [
      "-DEMBREE_ISA_AVX=OFF"
      "-DEMBREE_ISA_SSE2=OFF"
      "-DEMBREE_ISA_SSE42=OFF"];
  });
}

