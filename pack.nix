let
  lib = import ./lib.nix;

  mergePrefs = lib.recursiveUpdate; # TODO

  isPackage = p: p ? withPrefs;

  packsWithPrefs = packPrefs: lib.fix (packs: with packs; {
    inherit lib versionKeys;
    prefs = packPrefs;
    withPrefs = p: packsWithPrefs (mergePrefs packPrefs p);

    spack = builtins.fetchGit ({ url = "git://github.com/spack/spack"; name = "spack"; } // packPrefs.spackGit);
    defaultSpackConfig = {
      bootstrap = { enable = false; };
      config = {
        locks = false;
        install_tree = {
          root = "/rootless-spack";
        };
      };
      compilers = [{ compiler = {
        spec = "null@0";
        paths = {
          cc = null;
          cxx = null;
          f77 = null;
          fc = null;
        };
        operating_system = packPrefs.os;
        modules = [];
      }; }];
    };
    spackConfig = import spack/config.nix packs
      (lib.recursiveUpdate defaultSpackConfig packPrefs.spackConfig);

    spackBuilder = {
      inherit (packPrefs) system os;
      builder = packPrefs.spackPython;
      PYTHONPATH = "${spack}/lib/spack:${spack}/lib/spack/external";
      inherit (packs) spackConfig;
    };

    # pre-generated spack repo index cache
    spackCache = derivation (spackBuilder // {
      name = "spack-cache";
      args = [spack/cache.py];
    });

    spackPackageWithPrefs = 
      let
        defaults = {
          namespace = "builtin";
          version = [];
          variants = {};
          depends = {
            compiler = {};
          };
          build = {};
          extern = null;
          paths = {};
          finalize = {};
        };
        resolveEach = resolver: pref:
          builtins.mapAttrs (name: resolver name pref.${name} or null);
        resolvePackage = name: pref: arg:
          if isPackage pref then
            /* forced package */
            pref
          else if isPackage arg then
            arg.withPrefs pref
          else if arg == false || pref == false || arg == null && pref == null then
            false
          else
            (packs.${name} or (throw "dependent package ${name} not found")).withPrefs (mergePrefs arg pref);
        resolvers = {
          namespace = lib.coalesce;
          version = pref: arg:
            /* special version matching: a (list of intersected) version constraint */
            let v = builtins.filter (v: lib.allIfList (p: lib.versionMatches p v) pref) arg;
            in if v == []
              then throw "no version matching ${toString pref} from ${builtins.concatStringsSep "," arg}"
              else builtins.head v;
          variants = resolveEach (name: pref: arg:
            let err = throw "invalid variant ${name}: ${pref} (for ${toString pref})"; in
            if pref == null then
              /* no preference: use default */
              if builtins.isList arg then builtins.head arg else arg
            else if builtins.isList arg then
              /* list of options */
              if builtins.elem pref arg
                then pref
                else err
            else if builtins.isAttrs arg then
              /* multi */
              let r = arg // (
                  if builtins.isAttrs pref then pref else
                  if builtins.isList pref then
                    builtins.listToAttrs (builtins.map (name: { inherit name; value = true; }) pref)
                  else err); in
                if builtins.attrNames r == builtins.attrNames arg && builtins.all builtins.isBool (builtins.attrValues r) then
                  r
                else err
            else if builtins.typeOf arg == builtins.typeOf pref then
              /* a simple value: any value of that type */
              pref
            else err);
          depends = resolveEach resolvePackage;
          extern = lib.coalesce;
        };
        renderVariant = v:
          if builtins.isAttrs v then
            builtins.filter (n: v.${n}) (builtins.attrNames v)
          else v;
        render = lab: pkg: if pkg == false then {} else
          let
            prep = p: lib.mapKeys (a: "${p}_${a}");
            vars = builtins.parseDrvName pkg.name // {
                namespace = pkg.args.namespace;
                variants = builtins.attrNames pkg.args.variants;
              } // prep "variant" (builtins.mapAttrs (n: renderVariant) pkg.args.variants)
                // pkg.paths or {};
          in prep lab vars;
        renderDepends = deps:
          let depnames = builtins.filter (d: deps.${d} != false) (builtins.attrNames deps);
          in { depends = depnames; } // lib.concatAttrs (map (d:
            { "${d}" = deps.${d}; } // render d deps.${d}) depnames);
      in
      prefs: gen: let
        desc = lib.recursiveUpdate defaults
          ((if builtins.isPath gen then import gen packs else gen) args);
        pname = desc.name;
        name = "${pname}-${args.version}";
        mprefs = mergePrefs (mergePrefs packPrefs.global packPrefs.${pname} or null) prefs;
        resolved = builtins.mapAttrs (a: resolve: resolve mprefs.${a} or null desc.${a}) resolvers;
        args = resolved // {
          whenVersion = v: lib.when (lib.versionMatches v resolved.version);
        };
        extern = args.extern != null;
        build = spackBuilder // {
          args = [spack/builder.py];
          inherit spackCache;
          inherit name;
        } // render "out" { inherit name args; }
          // renderDepends args.depends;
        drv = if extern
          then { inherit name; outPath = args.extern; }
          else derivation (build // desc.build);
        pkg = drv // {
          inherit prefs args;
          withPrefs = p: spackPackageWithPrefs (mergePrefs prefs p) gen;
          withArgs = gen': spackPackageWithPrefs prefs (args: gen args // gen' args);
          paths = builtins.mapAttrs (a: p: "${drv.outPath}/${p}") desc.paths;
        };
        finalize = desc.finalize;
      in pkg // (if builtins.isFunction desc.finalize then desc.finalize pkg else desc.finalize);

    spackPackage = spackPackageWithPrefs null;

    # generate nix package metadata from spack repos
    spackGenerate = derivation (spackBuilder // {
      name = "spack-generate";
      args = [spack/generate.py];
      inherit spackCache;
    });
    
    m4 = spackPackage (args: {
      name = "m4";
      version = ["1.4.19" "1.4.18" "1.4.17"];
      variants = {
        sigsegv = true;
      };
      depends = {
        libsigsegv = lib.when args.variants.sigsegv {};
      };
    });

    libsigsegv = spackPackage (args: {
      name = "libsigsegv";
      version = ["2.13" "2.12" "2.11" "2.10"];
    });

    baseGcc = spackPackage (args: {
      name = "gcc";
      version = ["11.1.0" "10.3.0" "10.2.0" "7.5.0" "4.8.5" "master"];
      paths = {
        cc = "bin/gcc";
        cxx = "bin/g++";
        f77 = "bin/gfortran";
        fc = "bin/gfortran";
      };
      variants = {
        languages = {
          c = true;
          "c++" = true;
          fortran = true;
          ada = false;
          brig = false;
          go = false;
          java = false;
          jit = false;
          lto = false;
          objc = false;
          "obj-c++" = false;
        };
        binutils = false;
        piclibs = false;
        strip = false;
        nvptx = false;
        bootstrap = false;
        graphite = false;
      };
      depends = {
        compiler = false;
      };
    });

    gcc = baseGcc.withArgs (args: {
      depends = {
        compiler = bootstrapPacks.compiler;
        flex = args.whenVersion "master" {};
        gmp = { version = "4.3.2:"; };
        mpfr = lib.coalesce
          (args.whenVersion ":9.9" { version = "2.4.2:3.1.6"; })
          (args.whenVersion "10:" { version = "3.1.0:"; });
        mpc = args.whenVersion "4.5:" { version = "1.0.1:"; };
        isl = lib.when args.variants.graphite (lib.coalesces
          [ args.whenVersion "5.0:5.2" { version = "0.14"; } /* ... */]);
        zlib = args.whenVersion "6:" {};
      };
    });

    systemGcc = baseGcc.withArgs (args: {
      extern = "/usr";
      version = ["4.8.5"];
    });

    bootstrapPacks = withPrefs { compiler = "systemGcc"; };
    compiler = packs.${prefs.compiler or "gcc"};
  });

in packsWithPrefs (import ./prefs.nix)
