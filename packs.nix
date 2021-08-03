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
      patches = a: b: a ++ b;
    };
  in lib.coalesceWith (lib.mergeWithKeys (k: intersectors.${k} or intersectScalar));

/* unify a list of package prefs, making sure they're compatible */
prefsIntersection = builtins.foldl' prefsIntersect null;

versionsUnion = l:
  if builtins.isList l then
    let l' = lib.remove null l;
  in lib.when (l' != []) (builtins.concatStringsSep "," l')
  else l;

isRDepType = t:
  builtins.elem "link" t || builtins.elem "run" t;

isRDepend = d: isRDepType (d.type or []);

/* default package descriptor */
defaultDesc = {
  namespace = "builtin";
  version = [];
  variants = {};
  patches = [];
  depends = {
    compiler = {
      type = ["build"];
    };
  };
  conflicts = [];
  provides = {};
  paths = {};
  extern = null;
};

variantToString = n: v:
       if v == true  then "+"+n
  else if v == false then "~"+n
  else " ${n}="+
      (if builtins.isList v then builtins.concatStringsSep "," v
  else if builtins.isAttrs v then builtins.concatStringsSep "," (map (n: variantToString n v.${n}) (builtins.attrNames v))
  else builtins.toString v);

/* like spack default format */
specToString = spec:
  "${spec.name}@${spec.version}"
  + builtins.concatStringsSep "" (map (v: variantToString v spec.variants.${v})
    (builtins.sort (a: b: builtins.typeOf spec.variants.${a} < builtins.typeOf spec.variants.${b}) (builtins.attrNames spec.variants)));

/* check that a given spec conforms to the specified preferences */
specMatches = spec:
  { version ? null
  , variants ? {}
  , patches ? []
  , depends ? {}
  , extern ? spec.extern
  , ... /* don't care about tests */
  } @ prefs:
     lib.versionMatches spec.version version
  && builtins.all (name: lib.variantMatches (spec.variants.${name} or null) variants.${name}) (builtins.attrNames variants)
  && lib.subsetOrdered patches spec.patches
  && builtins.all (name: specMatches spec.depends.${name} depends.${name}) (builtins.attrNames depends)
  && spec.extern == extern;

getPackageWith = get: arg:
  if arg == null then
    pref: null
  else if builtins.isString arg then
    builtins.addErrorContext "getting package ${arg}" (get arg)
  else if arg ? name then
    pref: getPackageWith get arg.name (prefsIntersect (builtins.removeAttrs arg ["name"]) pref)
  else throw "invalid package";

patchDesc = patch: gen: spec: let desc = gen spec; in
  desc // lib.applyOptional (lib.applyOptional patch spec) desc;
patchRepo = patch: repo: repo //
  builtins.mapAttrs (name: f: patchDesc f (repo.${name} or (spec: {}))) patch;

repoPatches = patchRepo (import ./patch lib);

packsWithPrefs = 
  { system ? builtins.currentSystem
  , os ? "unknown"
  , target ? builtins.head (lib.splitRegex "-" system)
  , platform ? builtins.elemAt (lib.splitRegex "-" system) 1
  , label ? "root"
  , spackSrc ? {}
  , spackConfig ? {}
  , spackPython ? "/usr/bin/python3"
  , spackPath ? "/bin:/usr/bin"
  , repoPatch ? {}
  , global ? {}
  , package ? {}
  , compiler ? { name = "gcc"; }
  , bootstrapCompiler ? compiler // { extern = "/usr"; }
  , fixedDeps ? false
  } @ packPrefs:
lib.fix (packs: with packs; {
  inherit lib;
  prefs = packPrefs;
  inherit system os target platform label;
  withPrefs = p: packsWithPrefs (lib.recursiveUpdate packPrefs p);

  spack = if builtins.isString spackSrc then spackSrc else
    builtins.fetchGit ({ name = "spack"; url = "git://github.com/spack/spack"; } // spackSrc);

  spackConfig = import spack/config.nix packs (lib.recursiveUpdate {
    bootstrap = { enable = false; };
    config = {
      locks = false;
      install_tree = {
        root = "/rootless-spack";
      };
      misc_cache = "$tempdir/cache"; /* overridden by spackCache */
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
      operating_system = os;
      target = target;
      modules = [];
    }; }]; } spackConfig);

  spackNixLib = derivation {
    name = "nix-spack-py";
    inherit system;
    builder = spack/install.sh;
    src = spack/nixpack.py;
  };

  /* common attributes for running spack */
  spackBuilder = {
    inherit system os;
    builder = spackPython;
    PYTHONPATH = "${spackNixLib}:${spack}/lib/spack:${spack}/lib/spack/external";
    PATH = spackPath;
    inherit (packs) spackConfig;
  };

  /* pre-generated spack repo index cache */
  spackCache = lib.when (builtins.isAttrs spackSrc)
    (derivation (spackBuilder // {
      name = "spack-cache";
      args = [spack/cache.py];
    }));

  /* look up a package requirement and resolve it with prefs */
  getPackage = getPackageWith (name: pref:
    if pref == null || pref == {}
      then pkgs.${name} /* optimization */
      else resolvers.${name} pref);

  /* resolve a named package descriptor into a concrete spec (concretize) */
  resolvePackage = name:
    let
      uprefs = prefsUpdate packPrefs.global packPrefs.package.${name} or null;
      /* combining preferences with descriptor to get concrete package spec */
      resolveEach = resolver: arg: pref:
        builtins.mapAttrs (n: a: resolver n a pref.${n} or null) arg;
      resolveVersion = arg: pref:
        /* special version matching: a (list of intersected) version constraint */
        let v = builtins.filter (v: lib.versionMatches v pref) arg;
        in if v == []
          then throw "${name}: no version matching ${toString pref} from ${builtins.concatStringsSep "," arg}"
          else builtins.head v;
      resolveVariants = resolveEach (vname: arg: pref:
        let err = throw "${name} variant ${vname}: invalid ${toString pref} (for ${toString arg})"; in
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
          deparg = builtins.mapAttrs (name: dep: if builtins.isList dep then prefsIntersection dep else dep) arg;
          /* filter out unneded deps */
          types = builtins.mapAttrs (name: dep: (if tests then lib.id else lib.remove "test") dep.type or []) deparg;
          adeps = builtins.filter (n: types.${n} != []) (builtins.attrNames deparg);

        /* dynamic */
          /* split deps into runtime (right) and build (wrong) */
          tdeps = builtins.partition (n: isRDepType types.${n}) adeps;
          /* merge user prefs with package prefs, cleanup */
          makeDeps = l: builtins.listToAttrs (map (name: { inherit name;
            value = prefsIntersect (builtins.removeAttrs deparg.${name} ["type"]) pref.${name} or null; }) l);
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
            let l = lib.nub (lib.remove null
              (map (child: deppkgs.${child}.spec.depends.${dep} or null) tdeps.right));
            in
            if l == [] then pkgs else
            if builtins.length l == 1 then pkgs // { "${dep}" = builtins.head l; } else
            /* really we should also cross-propagate child prefs to avoid this */
            throw "${name}: inconsistent recursive dependencies for ${dep}";
          rrdeps = builtins.foldl' updrec deppkgs tdeps.right;

        /* static */
          sdeps = builtins.listToAttrs (map (dep:
            let pkg = getPackage dep (pref.${dep} or null); /* see {} optimization there */
            in if specMatches pkg.spec deparg.${dep} then { name = dep; value = pkg; } else
            throw "${name} dependency ${dep}: package ${specToString pkg.spec} does not match dependency constraints ${builtins.toJSON arg.${dep}}")
            adeps);
        in if fixedDeps then sdeps else rrdeps;

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

      /* resolving a real package */
      package = gen:
        { version ? uprefs.version or null
        , variants ? {}
        , patches ? uprefs.patches or []
        , depends ? {}
        , extern ? uprefs.extern or null
        , tests ? uprefs.tests or null
        }: let
          desc = lib.recursiveUpdate defaultDesc (gen spec);
          spec = {
            inherit name;
            inherit (desc) namespace paths;
            tests    = lib.coalesce tests false;
            extern   = lib.coalesce extern desc.extern;
            version  = if spec.extern != null && lib.versionIsConcrete version then version
              else     resolveVersion  desc.version  version;
            patches  = desc.patches ++ patches;
            variants = resolveVariants desc.variants (variants // uprefs.variants or {});
            depends = if spec.extern != null then {} else
              resolveDepends spec.tests desc.depends (depends // uprefs.depends or {});
            provides = builtins.mapAttrs (n: versionsUnion) desc.provides;
          };
          conflicts = lib.remove null desc.conflicts;
        in if spec.extern != null || conflicts == [] then makePackage spec
        else throw "${name}: has conflicts: ${toString conflicts}";
        /* TODO: remove bdeps from final package spec? */

      /* resolving virtual packages, which resolve to a specific package as soon as prefs are applied */
      virtual = providers:
        { version ? uprefs.version or ":"
        , provider ? uprefs.provider or null
        , ...
        } @ prefs: let
          provs = lib.toList (lib.coalesce provider providers);
          opts = builtins.map (o: getPackage o (lib.when (! fixedDeps)
            (builtins.removeAttrs prefs ["version" "provider"]))) provs;
          check = opt:
            let
              provtry = builtins.tryEval opt.spec.provides.${name}; /* catch conflicts */
              prov = lib.when provtry.success provtry.value;
            in prov != null && lib.versionsOverlap version prov;
          choice = builtins.filter check opts;
        in if choice == [] then "no providers for ${name}@${version}" else builtins.head choice;

    in builtins.addErrorContext "resolving package ${name}" (desc:
      if builtins.isList desc then
        virtual desc
      else if builtins.isFunction desc then
        package desc
      else if builtins.isAttrs desc then
        package (lib.const desc)
      else throw "${name}: invalid package descriptor ${toString (builtins.typeOf desc)}");

  # generate nix package metadata from spack repos
  spackRepo = derivation (spackBuilder // {
    name = "spack-repo.nix";
    args = [spack/generate.py];
    inherit spackCache;
  });

  bootstrapPacks = packs.withPrefs {
    compiler = bootstrapCompiler;
    label = "bootstrap";
  };

  /* full metadata repo package descriptions */
  repo = patchRepo repoPatch (repoPatches (import spackRepo {
      /* utilities needed by the repo */
      inherit (lib) when versionMatches variantMatches;
      inherit platform target os;
    }));

  /* partially applied specs, which take preferences as argument */
  resolvers = builtins.mapAttrs resolvePackage repo // {
    compiler = bootstrapPacks.getPackage prefs.compiler;
  };

  /* fully applied resolved packages with default preferences */
  pkgs = builtins.mapAttrs (name: res: res {}) resolvers;

});

in packsWithPrefs
