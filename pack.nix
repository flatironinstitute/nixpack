let

lib = import ./lib.nix;

mergePrefs = lib.recursiveUpdate; # TODO

/* unify a list of package prefs, making sure they're compatible */
intersectPrefs = let
    err = a: b: throw "incompatible prefs: ${a} vs ${b}";
    intersectScalar = lib.coalesceWith (a: b: if a == b then a else err a b);
    intersectors = {
      version = a: b:
        if builtins.isList a then
          if builtins.isList b then
            a ++ b
          else
            a ++ [b]
        else if builtins.isList b then
          [a] ++ b
        else
          [a b];
      variants = lib.mergeWith (a: b: if a == b then a else
        if builtins.isList a && builtins.isList b then a ++ b
        else err a b);
    };
  in builtins.foldl' (lib.coalesceWith (lib.mergeWithKeys (k: intersectors.${k} or intersectScalar))) null;

unionVersions = l:
    let l' = builtins.filter (x: x != null) l;
  in if l' == [] then null else builtins.concatStringsSep "," l';

isPackage = p: p ? withPrefs;

packsWithPrefs = packPrefs: lib.fix (packs: with packs; {
  inherit lib intersectPrefs unionVersions;
  inherit (lib) when;
  prefs = packPrefs;
  withPrefs = p: packsWithPrefs (mergePrefs packPrefs p);

  systemSplit = lib.splitRegex "-" packPrefs.system;
  platform = builtins.head systemSplit;
  target = builtins.elemAt systemSplit 1;
  inherit (packPrefs) os;

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
        provides = {};
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
          (repo.${name} or (throw "dependent package ${name} not found")).withPrefs (mergePrefs arg pref);
      resolvers = {
        namespace = lib.coalesce;
        version = pref: arg:
          /* special version matching: a (list of intersected) version constraint */
          let v = builtins.filter (v: lib.versionMatches v pref) arg;
          in if v == []
            then throw "no version matching ${toString pref} from ${builtins.concatStringsSep "," arg}"
            else builtins.head v;
        variants = resolveEach (name: pref: arg:
          let err = throw "invalid variant ${name}: ${toString pref} (for ${toString arg})"; in
          if pref == null then
            /* no preference: use default */
            if builtins.isList arg then builtins.head arg else arg
          else if builtins.isList arg then
            /* list of options */
            if builtins.elem (lib.fromList pref) arg
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
        versionMatches = lib.versionMatches resolved.version;
        variantMatches = v: lib.variantMatches resolved.variants.${v};
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
        inherit (desc) provides;
        inherit prefs args;
        withPrefs = p: spackPackageWithPrefs (mergePrefs prefs p) gen;
        withArgs = gen': spackPackageWithPrefs prefs (args: gen args // gen' args);
        paths = builtins.mapAttrs (a: p: "${drv.outPath}/${p}") desc.paths;
      };
      finalize = desc.finalize;
    in pkg // (if builtins.isFunction desc.finalize then desc.finalize pkg else desc.finalize);

  spackPackage = spackPackageWithPrefs null;

  spackVirtual = name: providers:
    let
      pref = lib.toList (packPrefs.${name} or []);
      opts = builtins.map (p: if isPackage p then p else repo.${p}) (pref ++ providers);
    in {
      withPrefs = prefs: let
          vers = prefs.version or ":";
          checkOpt = opt:
            let prov = opt.provides.${name} or null; in 
            prov != null && lib.versionsOverlap vers prov;
          choice = builtins.filter checkOpt opts;
        in if choice == [] then "no providers for ${name}@${vers}" else builtins.head choice;
    };

  # generate nix package metadata from spack repos
  spackRepo = derivation (spackBuilder // {
    name = "spack-repo";
    args = [spack/generate.py];
    inherit spackCache;
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
    };
  });

  systemGcc = baseGcc.withArgs (args: {
    extern = "/usr";
    version = ["4.8.5"];
  });

  bootstrapPacks = withPrefs { compiler = "systemGcc"; };
  compiler = packs.${prefs.compiler or "gcc"};

  repo = import spackRepo packs // { inherit compiler; };
});

in packsWithPrefs
