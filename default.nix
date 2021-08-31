let

packs = import ./packs {
  /* packs prefs */
  system = builtins.currentSystem;
  os = "centos7";

  /* where to get the spack respository. Can also be a path (string) to an
     existing spack install, however this will eliminate the dependency and
     break purity, and can cause your repo metadata to get out of sync,
     so is not recommended for production. */
  spackSrc = {
    /* default:
    url = "git://github.com/spack/spack"; */
    ref = "develop";
    #rev = "b4c6c11e689b2292a1411e4fc60dcd49c929246d";
  };
  /* extra config settings for spack itself.  Can contain any standard spack
     configuration, but don't put compilers (automatically generated), packages
     (based on package preferences below), or modules (passed to modules
     function) here. */
  spackConfig = {
    config = {
      /* must be set to somewhere your nix builder(s) can write to */
      source_cache = "/tmp/spack_cache";
    };
  };
  /* environment for running spack. spack needs things like python, cp, tar,
     etc.  These can be string paths to the system or to packages/environments
     from nixpkgs or similar, but regardless need to be external to nixpacks. */
  spackPython = "/usr/bin/python3";
  spackPath = "/bin:/usr/bin";

  /* packs can optionally include nixpkgs for additional packages or bootstrapping.
     omit to disable. */
  nixpkgsSrc = {
    #url = "git://github.com/NixOS/nixpkgs";
    ref = "master";
    #rev = "72bab23841f015aeaf5149a4e980dc696c59d7ca";
  };

  repoPatch = {
    /* updates or additions to the spack repo (see patch/default.nix)
    package = [spec: [old:]] {
      new...
    };
    */
  };
  /* global defaults for all packages */
  global = {
    /* spack architecture targets */
    target = "broadwell";
    /* print build logs during spack bulids (to be captured by nix).
       regardless, spack also keeps logs in .spack */
    logs = false;
    /* enable tests and test deps (not fully implemented) */
    tests = false;
    /* how to resolve dependencies, similar to concretize together or separately.
       fixedDeps = false:  Dependencies are resolved dynamically based on
         preferences and constraints imposed by each depender.  This can result
         in many different versions of each package existing in packs.
       fixedDeps = true:  Dependencies are resolved only by user prefs, and an
         error is produced if dependencies don't conform to their dependers'
         constraints.  This ensures only one version of each dependent package
         exists within packs.  Different packs with different prefs may have
         different versions.  Top-level packages explicitly resolved with
         different prefs or dependency prefs may also be different.  Virtuals
         are always resolved (to a package name) dynamically.
       this can be overridden per-package for only that package's dependencies.
     */
    fixedDeps = false;
  };
  package = {
    /* compiler is an implicit virtual dependency for every package */
    compiler = bootstrapPacks.pkgs.gcc;
    /* preferences for individual packages or virtuals */
    /* get cpio from system:
    cpio = {
      extern = "/usr";
      version = "2.11";
    }; */
    /* specify virtual providers: can be (lists of) package or { name; ...prefs }
    mpi = [ packs.pkgs.openmpi ];
    java = { name = "openjdk"; version = "10"; }; */
    /* use gcc 7.x:
    gcc = {
      version = "7";
    }; */
    /* enable cairo+pdf:
    cairo = {
      variants = {
        pdf = true;
      };
    }; */
    /* use an external slurm:
    slurm = {
      extern = "/cm/shared/apps/slurm/current";
      version = "20.02.5";
      variants = {
        sysconfdir = "/cm/shared/apps/slurm/var/etc/slurm";
        pmix = true;
        hwloc = true;
      };
    }; */
    nix = {
      variants = {
        storedir = let v = builtins.getEnv "NIX_STORE_DIR"; in if v == "" then "none" else v;
        statedir = let v = builtins.getEnv "NIX_STATE_DIR"; in if v == "" then "none" else v;
      };
    };
  };

};

bootstrapPacks = packs.withPrefs {
  package = {
    /* must be set to an external compiler capable of building compiler (above) */
    compiler = {
      name = "gcc";
      version = "4.8.5";
      extern = "/usr";
      /* can also have multiple layers of bootstrapping, where each compiler is built by another */
    };
    /* can speed up bootstrapping by providing more externs
    zlib = {
      extern = "/usr";
      version = "...";
    }; ... */
  };
};

in

packs
