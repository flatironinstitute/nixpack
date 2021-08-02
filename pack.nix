let

lib = import ./lib.nix;

prefsUpdate = lib.recursiveUpdate; # TODO

/* unify two prefs, making sure they're compatible */
prefsIntersect = let
    err = a: b: throw "incompatible prefs: ${builtins.toJSON a} vs ${builtins.toJSON b}";
    intersectScalar = lib.coalesceWith (a: b: if a == b then a else err a b);
    intersectors = {
      version = a: b: lib.union (lib.toList a) (lib.toList b);
      variants = lib.mergeWith (a: b: if a == b then a else
        if builtins.isList a && builtins.isList b then lib.union a b
        else err a b);
      type = lib.union;
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

patchDesc = patch: gen: spec: let desc = gen spec; in
  desc // lib.applyOptional (lib.applyOptional patch spec) desc;
patchRepo = patch: repo: repo //
  builtins.mapAttrs (name: f: patchDesc f (repo.${name} or (spec: {}))) patch;

packsWithPrefs = packPrefs: lib.fix (packs: with packs; {
  label = packPrefs.label or "root";
  prefs = packPrefs;
  withPrefs = p: packsWithPrefs (lib.recursiveUpdate packPrefs p);
  inherit lib;

  systemSplit = lib.splitRegex "-" packPrefs.system;
  target = builtins.head systemSplit;
  platform = builtins.elemAt systemSplit 1;

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
      /* fake null compiler */
      spec = "gcc@0";
      paths = {
        cc = null;
        cxx = null;
        f77 = null;
        fc = null;
      };
      operating_system = packPrefs.os;
      target = target;
      modules = [];
    }; }];
  };
  spackConfig = import spack/config.nix packs
    (lib.recursiveUpdate defaultSpackConfig packPrefs.spackConfig);

  spackNixLib = derivation {
    name = "nix-spack-py";
    inherit (packPrefs) system;
    builder = spack/install.sh;
    src = spack/nixpack.py;
  };

  spackBuilder = {
    inherit (packPrefs) system os;
    builder = packPrefs.spackPython;
    PYTHONPATH = "${spackNixLib}:${spack}/lib/spack:${spack}/lib/spack/external";
    inherit (packs) spackConfig;
  };

  # pre-generated spack repo index cache
  spackCache = derivation (spackBuilder // {
    name = "spack-cache";
    args = [spack/cache.py];
  });

  /* look up a package requirement and resolve it with prefs */
  getPackage = arg:
    if /* builtins.trace "${label}.${builtins.toJSON arg}" */ arg == null then
      pref: null
    else if builtins.isString arg then
      resolvers.${arg} or (throw "package ${arg} not found")
    else if arg ? name then
      pref: getPackage arg.name (prefsIntersect (builtins.removeAttrs arg ["name"]) pref)
    else throw "invalid package";

  /* resolve a named package descriptor into a concrete spec (concretize) */
  resolvePackage = name:
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
          /* split deps into unneeded (filtered), runtime (right), and build (wrong) */
          types = lib.mapAttrs (name: dep: (if tests then lib.id else lib.remove "test") dep.type or []) arg;
          tdeps = builtins.partition (n: isRDepType types.${n})
            (builtins.filter (n: types.${n} != []) (builtins.attrNames arg));
          /* merge user prefs with package prefs, cleanup */
          makeDeps = l: builtins.listToAttrs (map (name: { inherit name;
            value = prefsIntersect (builtins.removeAttrs arg.${name} ["type"]) pref.${name} or null; }) l);
          rdeps = makeDeps tdeps.right;
          odeps = makeDeps tdeps.wrong;
          /* propagate rdep prefs into children */
          deps = builtins.mapAttrs (name: dep: prefsIntersect dep { depends = rdeps; }) rdeps // odeps;
          /* make packages */
          deppkgs = builtins.mapAttrs getPackage deps;
          /* if children have any common rdeps, use grandchildren instead
           * (though really should only if they are also rdeps)
           */
          updrec = pkgs: dep: 
            let l = lib.nub (builtins.filter (x: x != null)
              (map (child: deppkgs.${child}.specs.depends.${dep} or null) tdeps.right));
            in
            if l == [] then pkgs else
            if length l == 1 then pkgs // { "${dep}" = head l; } else
            /* really we should also cross-propagate child prefs to avoid this */
            throw "${name}: inconsistent recursive dependencies for ${dep}";
          rrdeps = builtins.foldl' updrec deppkgs tdeps.right;
        in rrdeps;

      /* resolving a real package */
      package = gen:
        { version ? uprefs.version or null
        , variants ? {}
        , depends ? {}
        , extern ? uprefs.extern or null
        , tests ? uprefs.tests or null
        }: let
          desc = lib.recursiveUpdate defaultDesc (gen spec);
          spec = desc // {
            inherit name;
            tests    = lib.coalesce tests false;
            extern   = lib.coalesce extern desc.extern;
            version  = if spec.extern != null && lib.versionIsConcrete version then version
              else     resolveVersion  desc.version  version;
            variants = resolveVariants desc.variants (variants // uprefs.variants or {});
            depends = if spec.extern != null then {} else
              resolveDepends spec.tests desc.depends (depends // uprefs.depends or {});
          };
        in makePackage spec;

      /* resolving virtual packages, which resolve to a specific package as soon as prefs are applied */
      virtual = providers:
        { version ? uprefs.version or ":"
        , provider ? uprefs.provider or null
        , ...
        } @ prefs: let
          provs = lib.toList (lib.coalesce provider providers);
          opts = builtins.map (o: getPackage o (builtins.removeAttrs prefs ["version" "provider"])) provs;
          check = opt:
            let prov = opt.spec.provides.${name} or null; in 
            prov != null && lib.versionsOverlap version prov;
          choice = builtins.filter check opts;
        in if choice == [] then "no providers for ${name}@${version}" else builtins.head choice;

    in desc:
      if builtins.isList desc then
        virtual desc
      else if builtins.isFunction desc then
        package desc
      else if builtins.isAttrs desc then
        package (lib.const desc)
      else throw "${name}: invalid package descriptor ${toString (builtins.typeOf desc)}";

  /* create a package from a spec */
  makePackage = spec: let
      name = "${spec.name}-${spec.version}";
      drv = if spec.extern != null
        then {
          inherit name;
          out = spec.extern;
        }
        else builtins.removeAttrs (derivation (spackBuilder // {
          args = [spack/builder.py];
          inherit spackCache name;
          spec = builtins.toJSON spec;
          passAsFile = ["spec"];
        })) ["PYTHONPATH" "spackConfig" "spackCache" "passAsFile"];
    in drv // {
      inherit spec;
      #paths = builtins.mapAttrs (a: p: "${drv.out}/${p}") spec.paths;
    };

  # generate nix package metadata from spack repos
  spackRepo = derivation (spackBuilder // {
    name = "spack-repo.nix";
    args = [spack/generate.py];
    inherit spackCache;
  });

  repoLib = {
    /* utilities needed by the repo */
    inherit (lib) when versionMatches variantMatches;
    inherit prefsIntersection versionsUnion platform target;
    inherit (packPrefs) os;
  };

  bootstrapPacks = packs.withPrefs {
    compiler = packPrefs.bootstrapCompiler;
    label = "bootstrap";
  };

  /* full metadata repo package descriptions */
  repo = patchRepo packPrefs.repoPatch
    (patchRepo (import ./patch.nix lib)
    (import spackRepo repoLib));

  /* partially applied specs, which take preferences as argument */
  resolvers = builtins.mapAttrs resolvePackage repo // {
    compiler = bootstrapPacks.getPackage prefs.compiler;
  };

  /* fully applied resolved packages with default preferences */
  pkgs = builtins.mapAttrs (name: res: res {}) resolvers;

});

in packsWithPrefs
