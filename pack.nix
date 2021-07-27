let
  lib = import ./lib.nix;

  mergePrefs = a: b:
    if a == null then b else
    if b == null then a else
    # TODO
    lib.recursiveUpdate a b;

  versionKeys = s: builtins.sort lib.versionNewer (builtins.attrNames s);

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
        operating_system = prefs.os;
        modules = [];
      }; }];
    };
    spackConfig = import spack/config.nix packs
      (lib.recursiveUpdate defaultSpackConfig packPrefs.spackConfig);

    spackPackageWithPrefs = 
      let
        defaults = {
          namespace = "builtin";
          version = [];
          variants = {};
          depends = {
            compiler = null;
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
          else if arg == false || pref == false then
            false
          else
            packs.${name}.withPrefs (mergePrefs arg pref);
        resolvers = {
          namespace = lib.coalesce;
          version = pref: arg:
            /* special version matching: a (list of intersected) version constraint */
            let v = builtins.filter (v: lib.allIfList (p: lib.versionMatches p v) pref) arg;
            in if v == []
              then throw "no version matching ${toString pref} from ${builtins.concatStringsSep "," arg}"
              else builtins.head v;
          variants = resolveEach (name: pref: arg:
            if pref == null then
              /* no preference: use default */
              if builtins.isList arg then builtins.head arg else arg
            else if builtins.isList arg then
              /* list of options */
              if builtins.elem pref arg
                then pref
                else throw "invalid arg ${name}: ${pref} (of ${builtins.concatStringsSep "," pref})"
            else if builtins.typeOf arg == builtins.typeOf pref then
              /* a simple value: any value of that type */
              pref
            else throw "invalid arg ${name}: ${pref} (for ${toString pref})");
          depends = resolveEach resolvePackage;
          extern = lib.coalesce;
        };
        render = lab: pkg: if pkg == false then {} else
          let
            prep = p: lib.mapKeys (a: "${p}_${a}");
            vars = builtins.parseDrvName pkg.name // {
                namespace = pkg.args.namespace;
                variants = builtins.attrNames pkg.args.variants;
              } // prep "variant" pkg.args.variants
                // pkg.paths or {};
          in prep lab vars;
        renderDepends = deps:
          let depnames = builtins.filter (d: deps.${d} != false) (builtins.attrNames deps);
          in { depends = depnames; } // lib.concatAttrs (map (d:
            { "${d}" = d; } // render d deps.${d}) depnames);
      in
      prefs: gen: let
        desc = lib.recursiveUpdate defaults
          ((if builtins.isPath gen then import gen packs else gen) args);
        pname = desc.name;
        name = "${pname}-${args.version}";
        mprefs = mergePrefs (mergePrefs packPrefs.global packPrefs.${pname} or null) prefs;
        args = builtins.mapAttrs (a: resolve: resolve mprefs.${a} or null desc.${a}) resolvers;
        extern = args.extern != null;
        build = {
          inherit (packPrefs) system os;
          PYTHONPATH = "${spack}/lib/spack:${spack}/lib/spack/external";
          builder = "/usr/bin/python3";
          args = [spack/builder.py];
          inherit (packs) spackConfig;
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
    
    m4 = spackPackage (args: {
      name = "m4";
      version = ["1.4.19" "1.4.18" "1.4.17"];
      variants = {
        sigsegv = false;
      };
      depends = {
        libsigsegv = if args.variants.sigsegv then {} else false;
      };
      tags = ["build-tools"];
    });

    baseGcc = spackPackage (args: {
      name = "gcc";
      version = ["11.1.0" "10.3.0" "10.2.0" "7.5.0" "4.8.5"];
      paths = {
        cc = "bin/gcc";
        cxx = "bin/g++";
        f77 = "bin/gfortran";
        fc = "bin/gfortran";
      };
      depends = {
        compiler = false;
      };
    });

    gcc = baseGcc.withPrefs {
      depends = {
        compiler = bootstrapPacks.compiler;
      };
    };

    systemGcc = baseGcc.withPrefs {
      extern = "/usr";
      version = ["4.8.5"];
    };

    bootstrapPacks = withPrefs { compiler = "systemGcc"; };
    compiler = packs.${prefs.compiler or "gcc"};
  });

in packsWithPrefs (import ./prefs.nix)
