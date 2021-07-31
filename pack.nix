let

lib = import ./lib.nix;

prefsUpdate = lib.recursiveUpdate; # TODO

/* unify two prefs, making sure they're compatible */
prefsIntersect = let
    err = a: b: throw "incompatible prefs: ${builtins.toJSON a} vs ${builtins.toJSON b}";
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
  in lib.coalesceWith (lib.mergeWithKeys (k: intersectors.${k} or intersectScalar));

/* unify a list of package prefs, making sure they're compatible */
prefsIntersection = builtins.foldl' prefsIntersect null;

versionsUnion = l:
    let l' = builtins.filter (x: x != null) l;
  in if l' == [] then null else builtins.concatStringsSep "," l';

isRDepType = t:
  builtins.elem "link" t || builtins.elem "run" t;

isRDepend = d: isRDepType (d.type or []);

/* default package descriptor */
defaultDesc = {
  namespace = "builtin";
  version = [];
  variants = {};
  depends = {
    compiler = {
      type = ["build"];
    };
  };
  provides = {};
  paths = {};
  extern = null;
};

/* overrides to the spack repo */
repoOverrides = {
  gcc = {
    paths = {
      cc = "bin/gcc";
      cxx = "bin/g++";
      f77 = "bin/gfortran";
      fc = "bin/gfortran";
    };
  };
};

packsWithPrefs = packPrefs: lib.fix (packs: with packs; {
  label = packPrefs.label or "root";
  prefs = packPrefs;
  withPrefs = p: packsWithPrefs (prefsUpdate packPrefs p);
  inherit lib;

  spack = builtins.fetchGit ({ url = "git://github.com/spack/spack"; name = "spack"; } //
    packPrefs.spackGit);

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

  /* look up a package requirement and resolve it with prefs */
  getSpec = arg:
    if /* builtins.trace "${label}.${builtins.toJSON arg}" */ arg == null then
      pref: null
    else if builtins.isString arg then
      resolvers.${arg} or (throw "package ${arg} not found")
    else if arg ? name then
      pref: getSpec arg.name (prefsIntersect (builtins.removeAttrs arg ["name"]) pref)
    else throw "invalid package";

  /* resolve a named package descriptor into a concrete spec (concretize) */
  resolveSpec = name:
    let
      uprefs = prefsUpdate packPrefs.global packPrefs.package.${name} or null;
      /* combining preferences with descriptor to get concrete package spec */
      resolveEach = resolver: arg: pref:
        builtins.mapAttrs (name: resolver name pref.${name} or null) arg;
      resolveVersion = arg: pref:
        /* special version matching: a (list of intersected) version constraint */
        let v = builtins.filter (v: lib.versionMatches v pref) arg;
        in if v == []
          then throw "${name}: no version matching ${toString pref} from ${builtins.concatStringsSep "," arg}"
          else builtins.head v;
      resolveVariants = resolveEach (vname: pref: arg:
        let err = throw "${name}: invalid variant ${vname}: ${toString pref} (for ${toString arg})"; in
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
      resolveDepends = tests: arg: pref: let
          types = lib.mapAttrs (name: dep: (if tests then lib.id else lib.remove "test") dep.type or []) arg;
          tdeps = builtins.partition (n: isRDepType types.${n})
            (builtins.filter (n: types.${n} != []) (builtins.attrNames arg));
          makeDeps = l: builtins.listToAttrs (map (name: { inherit name;
            value = prefsIntersect (builtins.removeAttrs arg.${name} ["type"]) pref.${name} or null; }) l);
          rdeps = makeDeps tdeps.right;
          odeps = makeDeps tdeps.wrong;
          deps = builtins.mapAttrs (name: dep: prefsIntersect dep { depends = rdeps; }) rdeps // odeps;
        /* resolve an actual package */
        in builtins.mapAttrs getSpec deps;

      /* resolving a real package */
      package = gen:
        { version ? uprefs.version or null
        , variants ? {}
        , depends ? {}
        , extern ? uprefs.extern or null
        , tests ? uprefs.tests or null
        }: let
          desc = lib.recursiveUpdate defaultDesc (gen spec) // repoOverrides.${name} or {};
          spec = desc // {
            inherit name;
            tests    = lib.coalesce tests false;
            extern   = lib.coalesce extern desc.extern;
            version  = resolveVersion  desc.version  version;
            variants = resolveVariants desc.variants (variants // uprefs.variants or {});
            depends = if spec.extern != null then {} else
              resolveDepends spec.tests desc.depends (depends // uprefs.depends or {});
          };
        in spec;

      /* resolving virtual packages, which resolve to a specific package as soon as prefs are applied */
      virtual = providers:
        { version ? uprefs.version or ":"
        , provider ? uprefs.provider or null
        , ...
        } @ prefs: let
          provs = lib.toList (lib.coalesce provider providers);
          opts = builtins.map (o: getSpec o (builtins.removeAttrs prefs ["version" "provider"])) provs;
          check = opt:
            let prov = opt.provides.${name} or null; in 
            prov != null && lib.versionsOverlap version prov;
          choice = builtins.filter check opts;
        in if choice == [] then "no providers for ${name}@${vers}" else builtins.head choice;

    in desc:
      if builtins.isList desc then
        virtual desc
      else if builtins.isFunction desc then
        package desc
      else if builtins.isAttrs desc then
        package (lib.const desc)
      else throw "${name}: invalid package descriptor ${toString (builtins.typeOf desc)}";

  makePackage = spec: let
      name = "${spec.name}-${spec.version}";
      pkg = spec // { depends = builtins.mapAttrs (name: dep: (makePackage dep).spec) spec.depends; };
      drv = if spec.extern != null
        then {
          inherit name;
          outPath = spec.extern;
        }
        else derivation (spackBuilder // {
          args = [spack/builder.py];
          inherit spackCache name;
          spec = builtins.toJSON pkg;
        });
    in drv // {
      spec = pkg // { pkg = drv; };
      paths = builtins.mapAttrs (a: p: "${drv.outPath}/${p}") spec.paths;
    };

  # generate nix package metadata from spack repos
  spackRepo = derivation (spackBuilder // {
    name = "spack-repo.nix";
    args = [spack/generate.py];
    inherit spackCache;
  });

  systemSplit = lib.splitRegex "-" packPrefs.system;
  repoLib = {
    /* utilities needed by the repo */
    inherit (lib) when versionMatches variantMatches;
    inherit prefsIntersection versionsUnion;
    platform = builtins.head systemSplit;
    target = builtins.elemAt systemSplit 1;
    inherit (packPrefs) os;
  };

  bootstrapPacks = packs.withPrefs {
    compiler = packPrefs.bootstrapCompiler;
    label = "bootstrap";
  };

  /* full metadata repo package descriptions */
  repo = import spackRepo repoLib;

  /* partially applied specs, which take preferences as argument */
  resolvers = builtins.mapAttrs resolveSpec repo // {
    compiler = bootstrapPacks.getSpec prefs.compiler;
  };

  /* fully applied resolved packages with default preferences */
  specs = builtins.mapAttrs (name: spec: spec {}) resolvers;

  /* fully applied resolved packages with default preferences */
  pkgs = builtins.mapAttrs (name: makePackage) specs;

});

in packsWithPrefs
