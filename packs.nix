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
      depends = lib.mergeWith prefsIntersect;
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

/* a very simple version of Spec.format */
specFormat = fmt: spec: let
  variantToString = n: v:
         if v == true  then "+"+n
    else if v == false then "~"+n
    else " ${n}="+
        (if builtins.isList v then builtins.concatStringsSep "," v
    else if builtins.isAttrs v then builtins.concatStringsSep "," (map (n: variantToString n v.${n}) (builtins.attrNames v))
    else builtins.toString v);
  fmts = {
    inherit (spec) name version;
    variants = builtins.concatStringsSep "" (map (v: variantToString v spec.variants.${v})
      (builtins.sort (a: b: builtins.typeOf spec.variants.${a} < builtins.typeOf spec.variants.${b}) (builtins.attrNames spec.variants)));
  };
  in builtins.replaceStrings (map (n: "{${n}}") (builtins.attrNames fmts)) (builtins.attrValues fmts) fmt;

/* like spack default format */
specToString = specFormat "{name}@{version}{variants}";

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
      target = builtins.head (lib.splitRegex "-" system);
      modules = [];
    }; }]; } spackConfig);

  spackNixLib = derivation {
    name = "nix-spack-py";
    inherit system;
    builder = spack/install.sh;
    src = spack/nixpack.py;
  };

  /* common attributes for running spack */
  spackBuilder = attrs: builtins.removeAttrs (derivation ({
    inherit (packs) system spackConfig spackCache;
    builder = spackPython;
    PYTHONPATH = "${spackNixLib}:${spack}/lib/spack:${spack}/lib/spack/external";
    PATH = spackPath;
  } // attrs)) ["PYTHONPATH" "PATH" "spackConfig" "spackCache" "passAsFile"];

  /* pre-generated spack repo index cache */
  spackCache = lib.when (builtins.isAttrs spackSrc)
    (spackBuilder {
      name = "spack-cache";
      args = [spack/cache.py];
      spackCache = null;
    });

  /* look up a package requirement and resolve it with prefs */
  getPackage = getPackageWith (name: pref:
    if pref == null || pref == {}
      then pkgs.${name} /* optimization */
      else resolvers.${name} pref);

  /* get the list of packages a given package might depend on (from the repo, makes assumptions about repo structure) */
  getPossibleDepends = name:
    (lib.applyOptional repo.${name} (throw "getPossibleDepends ${name}")).depends or {};

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
      /* these need to happen in parallel due to depend conditionals being evaluated recursively */
      resolveDepends = tests: depends: let
          depargs = builtins.mapAttrs (n: arg: if builtins.isList arg then prefsIntersection arg else arg) depends;
        in resolveEach (dname: dep: pref: let
          type = (if tests then lib.id else lib.remove "test") dep.type or [];
          clean = d: builtins.removeAttrs d ["type"];

          /* dynamic */
          isr = builtins.elem "link" type;
          dpref = prefsIntersect (clean dep) pref;
          /* for link dependencies with dependencies in common with ours, we propagate our prefs down.
             this doesn't entirely ensure consistent linking, but helps in many common cases. */
          pdeps = builtins.intersectAttrs (getPossibleDepends dname) depargs;
          rdeps = prefsIntersect dpref { depends = builtins.mapAttrs (n: clean) pdeps; };
          dyn = getPackage dname (if isr then rdeps else dpref);

          /* static */
          spkg = getPackage dname pref; /* see optimization in getPackage */
          static =
            if specMatches spkg.spec dep then spkg else
            throw "${name} dependency ${dname}: package ${specToString pkg.spec} does not match dependency constraints ${builtins.toJSON dep}";
        in lib.when (type != [])
          (if fixedDeps then static else dyn))
        depargs;

      /* create a package from a spec */
      makePackage = spec: let
          name = "${spec.name}-${spec.version}";
          drv = if spec.extern != null
            then {
              inherit name;
              out = spec.extern;
            }
            else spackBuilder {
              inherit platform target os;
              args = [spack/builder.py];
              inherit name;
              spec = builtins.toJSON spec;
              passAsFile = ["spec"];
            };
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
            version  = if extern != null && lib.versionIsConcrete version then version
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
        /* TODO: remove null/bdeps from final package spec? */

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
  spackRepo = spackBuilder {
    name = "spack-repo.nix";
    args = [spack/generate.py];
  };

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

  view = name: pkgs: spackBuilder {
    spackCache = null;
    spackConfig = null;
    PYTHONPATH = null;
    inherit name;
    args = [./view.py];
    src = pkgs;
    shbang = true;
    ignore = [".spack" ".nixpack.spec"];
  };

});

in packsWithPrefs
