{
  description = "Flake for NixPACK";

  inputs.spack = { url="github:spack/spack"; flake=false; };
  #inputs.spack = { url="github:flatironinstitute/spack/fi-nixpack"; flake=false; };
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = inputs: let
    nixpkgsFor = system: import inputs.nixpkgs {
      inherit system;
      config = {
        replaceStdenv = import ./nixpkgs/stdenv.nix;
        allowUnfree = true;
        cudaSupport = true;
      };
      overlays = [(import ./nixpkgs/overlay.nix)];
    };

    nixosPacks = system: let
      pkgs = nixpkgsFor system;
      gccWithFortran = pkgs.wrapCC (pkgs.gcc.cc.override {
        langFortran = true;
      });
    in inputs.self.lib.packs {
      inherit system;
      os = "nixos21";
      global.verbose = "true";
      spackConfig.config.source_cache="/tmp/spack_cache";
      spackPython = "${pkgs.python3}/bin/python3";
      spackEnv   = {
        # pure environment PATH
        PATH=/*"/run/current-system/sw/bin:"
            +*/inputs.nixpkgs.lib.concatStringsSep ":"
            (builtins.map (x: "${x}/bin")
            [
              pkgs.bash
              pkgs.coreutils
              pkgs.gnumake
              pkgs.gnutar
              pkgs.gzip
              pkgs.bzip2
              pkgs.xz
              pkgs.gawk
              pkgs.gnused
              pkgs.gnugrep
              pkgs.glib
              pkgs.binutils.bintools # glib: locale
              pkgs.patch
              pkgs.texinfo
              pkgs.diffutils
              pkgs.pkgconfig
              pkgs.gitMinimal
              pkgs.findutils
            ]);
        #PATH="/run/current-system/sw/bin:${pkgs.gnumake}/bin:${pkgs.binutils.bintools}/bin";
        LOCALE_ARCHIVE="/run/current-system/sw/lib/locale/locale-archive";
        LIBRARY_PATH=/*"/run/current-system/sw/bin:"
            +*/inputs.nixpkgs.lib.concatStringsSep ":"
            (builtins.map (x: "${x}/lib")
            [
              (inputs.nixpkgs.lib.getLib pkgs.binutils.bintools) # ucx (configure fails) libbfd not found
	    ]);
      };

      package = {
        compiler = { name="gcc"; extern=gccWithFortran; version=gccWithFortran.version; };
        perl = { extern=pkgs.perl; version=pkgs.perl.version; };
        openssh = { extern=pkgs.openssh; version=pkgs.openssh.version; };
        openssl = { extern=pkgs.symlinkJoin { name="openssl"; paths = [ pkgs.openssl.all ]; }; version=pkgs.openssl.version; };
        openmpi = {
          version = "4.1";
          variants = {
            fabrics = {
              none = false;
              ucx = true;
            };
            schedulers = {
              none = false;
              slurm = false;
            };
            pmi = false;
            pmix = false;
            static = false;
            thread_multiple = true;
            legacylaunchers = true;
          };
        };
      };
      repoPatch = {
        dyninst = spec: old: {
          patches = [ ./patch/dyninst-nixos.patch ];
        };
        openmpi = spec: old: {
          build = {
            setup = ''
              configure_args = pkg.configure_args()
              if spec.satisfies("~pmix"):
                if '--without-mpix' in configure_args: configure_args.remove('--without-pmix')
              pkg.configure_args = lambda: configure_args
            '';
          };
        };
      };
    };
  in {
    lib = (import packs/lib.nix) // {
      packs = {
        ...
      }@args: import ./packs ({
        inherit (inputs) spack nixpkgs;
      } // args);
    };


    packages.x86_64-linux = nixosPacks "x86_64-linux";

    defaultPackage.x86_64-linux = inputs.self.packages.x86_64-linux.hello;

  };
}
