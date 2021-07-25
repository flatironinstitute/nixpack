let
  lib = import ./lib.nix;

  mergePrefs = a: b:
    if a == null then b else
    if b == null then a else
    # TODO
    a // b;

  versionKeys = s: builtins.sort lib.versionNewer (builtins.attrNames s);

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
    
    build = {
      autotools = package build/autotools;
    };

    gmp = package packages/gmp;
    gcc = package packages/gcc;

    bootstrapPacks = withPrefs { global = { cc = { extern = "/usr"; }; }; };
    cc = bootstrapPacks.gcc;
  });


in packsWithPrefs {
  system = "x86_64-linux";
  global = {};
}
