let
  lib = import ./lib.nix;

  mergePrefs = a: b:
    if a == null then b else
    if b == null then a else
    # TODO
    a // b;

  versionKeys = s: builtins.sort lib.versionNewer (builtins.attrNames s);

  isPackage = p: p ? withPrefs;

  packsWithPrefs = prefs: lib.fix (packs: with packs; {
    inherit lib versionKeys prefs;
    withPrefs = p: packsWithPrefs (mergePrefs prefs p);

    /* given a requested prefence, and a package attribute, compute the resolved argument */
    resolveArg = pref: name: arg:
      if builtins.isAttrs arg then
        /* dependency */
        if builtins.isAttrs pref && pref ? withPrefs then
          /* forced package */
          if arg ? withPrefs then pref else pref.withPrefs arg
        else if arg ? withPrefs then
          arg.withPrefs pref
        else
          /* pull from packs */
          packs.${name}.withPrefs (mergePrefs arg pref)
      else if pref == null then
        /* no preference: use default */
        if builtins.isList arg then builtins.head arg else arg
      else if name == "version" then let
        /* special version matching: a (list of) version constraint */
          v = builtins.filter (v: lib.allIfList (p: lib.versionMatches p v) pref) arg;
        in if v == [] then throw "no version matching ${toString pref} from ${builtins.concatStringsSep "," pref}" else builtins.head v
      else if builtins.isList arg then
        /* list of options */
        if builtins.elem pref arg
          then pref
          else throw "invalid arg ${name}: ${pref} (of ${builtins.concatStringsSep "," pref})"
      else if builtins.typeOf arg == builtins.typeOf pref then
        /* a simple value: any value of that type */
        pref
      else throw "invalid arg ${name}: ${pref} (for ${toString pref})";

    resolveArgs = pprefs: args:
      builtins.mapAttrs (name: resolveArg (pprefs.${name} or null) name) args;

    packageWithPrefs = pprefs: gen: let 
        self = { extern = ""; } // (if builtins.isPath gen then import gen packs else gen) args;
        name = self.name;
        args = resolveArgs (mergePrefs (mergePrefs prefs.global (prefs.${name} or null)) pprefs)
          (removeAttrs self ["name" "build"]);
        defaults = {
          inherit (prefs) system;
          builder = ./builder.sh;
          name = "${name}-${args.version}";
        };
        overrides = {
          prefs = pprefs;
          withPrefs = p: packageWithPrefs (mergePrefs pprefs p) gen;
        };
        drv = if args.extern != "" then { outPath = args.extern; } else
          derivation (defaults // self.build);
      in drv // overrides;

    package = packageWithPrefs null;

    spack = builtins.fetchGit prefs.spackGit;

    spackPackageWithPrefs = 
      let
        resolveEach = resolver: pref:
          builtin.mapAttrs (name: resolver name (pref.${name} or null));
        resolvers = {
          version = pref: arg:
            let
            /* special version matching: a (list of) version constraint */
              v = builtins.filter (v: lib.allIfList (p: lib.versionMatches p v) pref) arg;
            in if v == [] then throw "no version matching ${toString pref} from ${builtins.concatStringsSep "," pref}" else builtins.head v;
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
          depends = resolveEach (name: pref: arg:
            if isPackage pref then
              /* forced package */
              pref
            else if isPackage arg then
              arg.withPrefs pref
            else if arg == null then
              null
            else
              /* pull from packs */
              packs.${name}.withPrefs (mergePrefs arg pref));
          extern = lib.coalesce;
        };
        defaults = {
          version = [];
          variants = {};
          defs = {};
          extern = null;
        };
      in
      pprefs: gen: let
        self = defaults //
          (if builtins.isPath gen then import gen packs else gen) args;
        name = self.name;
        mprefs = mergePrefs (mergePrefs prefs.global (prefs.${name} or null)) pprefs;
        args = builtins.mapAttrs (name: resolve: resolve (mprefs.${name} or null) self.${name}) resolvers;
        build = {
          inherit (prefs) system os;
          PYTHONPATH = "${spack}/lib/spack:${spack}/lib/spack/external";
          builder = "/usr/bin/python3";
          args = [build/spack/builder.py];
          name = "${name}-${args.version}";
        };
        overrides = {
          prefs = pprefs;
          withPrefs = p: spackPackageWithPrefs (mergePrefs pprefs p) gen;
        };
        drv = if args.extern != null then { outPath = args.extern; } else
          derivation (build // self.build or {});
      in drv // overrides;

    spackPackage = spackPackageWithPrefs null;
    
    m4 = spackPackage (args: {
      name = "m4";
      version = ["1.4.19" "1.4.18" "1.4.17"];
      variants = {
        sigsegv = true;
      };
      depends = {
        libsigsegv = if args.variants.sigsegv then {} else null;
      };
      tags = ["build-tolls"];
    });

    gcc = package packages/gcc;

    bootstrapPacks = withPrefs { global = { cc = { extern = "/usr"; }; }; };
    cc = bootstrapPacks.gcc;
  });

in packsWithPrefs (import ./prefs.nix)
