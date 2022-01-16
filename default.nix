let

packs = import ./packs {
  /* packs prefs */
  system = builtins.currentSystem;
  os = "centos7";

  /* where to get the spack respository. Note that since everything depends on
     spack, changing the spack revision will trigger rebuilds of all packages.
     Can also be set a path (string) to an existing spack install, which will
     eliminate the dependency and also break purity, so can cause your repo
     metadata to get out of sync, and is not recommended for production.
     See also repos and repoPatch below for other ways of updating packages
     without modifying the spack repo.  */
  spackSrc = {
    /* default:
    url = "git://github.com/spack/spack"; */
    ref = "develop";
    #rev = "a5c0a4dca41d3b14c166af2ca28cb4ee7ca10ca7";
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
  spackEnv = {
    PATH = "/bin:/usr/bin";
  };

  /* packs can optionally include nixpkgs for additional packages or bootstrapping.
     omit to disable. */
  nixpkgsSrc = {
    #url = "git://github.com/NixOS/nixpkgs";
    ref = "release-21.05"; # 21.11 and later affected by #144747
    #rev = "72bab23841f015aeaf5149a4e980dc696c59d7ca";
  };

  /* additional spack repos to include by path, managed by nixpack.
     These should be normal spack repos, including repo.yaml, and are prepended
     to any configured spack repos.
     Repos specified here have the advantage of correctly managing nix
     dependencies, so changing a package will only trigger rebuilds of
     it and dependent packages.
     Theoretically you could copy the entire spack builtins repo here and
     manage package updates that way, leaving spackSrc at a fixed revision.
     However, if you update the repo, you'll need to ensure compatibility with
     the spack core libraries, too. */
  repos = [
    spack/repo
  ];
  /* updates to the spack repo (see patch/default.nix for examples)
  repoPatch = {
    package = [spec: [old:]] {
      new...
    };
  }; */

  /* global defaults for all packages (merged with per-package prefs) */
  global = {
    /* spack architecture target */
    target = "broadwell";
    /* set spack verbose to print build logs during spack bulids (and thus
       captured by nix).  regardless, spack also keeps logs in pkg/.spack.  */
    verbose = false;
    /* enable build tests (and test deps) */
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
       this can be overridden per-package for only that package's dependencies.  */
    fixedDeps = false;
    /* How to find dependencies.  Normally dependencies are pulled from other
       packages in this same packs.  In some cases you may want some or all
       dependencies for a package to come from a different packs, perhaps
       because you don't care if build-only dependencies use the same compiler
       or python version.  This lets you override where dependencies come from.
       It takes two optional arguments:
         * list of dependency types (["build" "link" "run" "test"])
         * the name of the dependent package
       And should return either:
         * null, meaning use the current packs default
         * an existing packs object, to use instead
         * a function taking package preferences to a resolved package (like
           packs.getResolver).  In this case, prefs will be {} if fixedDeps =
           true, or the dependency prefs from the parent if fixedDeps = false.
    resolver = [deptype: [name: <packs | prefs: pkg>]]; */
  };
  /* package-specific preferences */
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

/* A set of packages with different preferences, based on packs above.
   This set is used to bootstrap gcc, but other packs could also be used to set
   different virtuals, versions, variants, compilers, etc.  */
bootstrapPacks = packs.withPrefs {
  package = {
    /* must be set to an external compiler capable of building compiler (above) */
    compiler = {
      name = "gcc";
      version = "4.8.5";
      extern = "/usr"; /* install prefix */
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

packs // {
  mods = packs.modules {
    /* this correspond to module config in spack */
    /* modtype = "lua"; */
    coreCompilers = [packs.pkgs.compiler bootstrapPacks.pkgs.compiler];
    /*
    config = {
      hiearchy = ["mpi"];
      hash_length = 0;
      projections = {
        # warning: order is lost
        "package+variant" = "{name}/{version}-variant";
      };
      prefix_inspections = {
        "dir" = ["VAR"];
      };
      all = {
        autoload = "none";
      };
      package = {
        environment = {
          prepend_path = {
            VAR = "{prefix}/path";
          };
        };
      };
    };
    */
    pkgs = with packs.pkgs; [
      gcc
      { pkg = gcc.withPrefs { # override package defaults
          version = "10";
        };
        default = true; # set as default version
        # extra content to append to module file
        postscript = ''
          LModMessage("default gcc loaded")
        '';
      }
      perl
      /*
      { # a custom module, not from spack
        name = "other-package";
        version = "1.2";
        prefix = "/opt/other";
        # overrides for module config
        environment = {
          prepend_path = {
            VAR = "{prefix}/path";
          };
        };
        projection = "{name}/{version}-local";
        context = { # other variables to set in the template
          short_description = "Some other package";
        };
      }
      */
    ];
  };
}
