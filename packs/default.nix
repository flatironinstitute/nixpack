let

lib = import ./lib.nix;

prefsUpdate = lib.coalesceWith lib.recursiveUpdate; # TODO

versionsUnion = l:
  if builtins.isList l then
    let l' = lib.remove null l;
  in lib.when (l' != []) (builtins.concatStringsSep "," l')
  else l;

defaultSpackConfig = {
  bootstrap = { enable = false; };
  config = {
    locks = false;
    install_tree = {
      root = "/rootless-spack";
    };
    misc_cache = "$tempdir/cache"; /* overridden by spackCache */
  };
  compilers = [];
};

/* fill in package descriptor with defaults */
fillDesc = name: /* simple name of package */
  { namespace ? "builtin"
  , version ? [] /* list of available concrete versions */
  , variants ? {} /* set of variant to (bool, string, or set of opt to bool) */
  , patches ? [] /* list of patches to apply (after those in spack) */
  , depends ? {} /* dependencies, set of name to {deptype; Constrants} */
  , conflicts ? [] /* list of conflict messages (package is not buildable if non-empty) */
  , provides ? {} /* set of provided virtuals to (version ranges or unioned list thereof) */
  , paths ? {} /* set of tools to path prefixes */
  }: {
    inherit name namespace version variants patches paths;
    depends = {
      compiler = {
        deptype = ["build"];
      };
    } // builtins.mapAttrs (n: lib.prefsIntersection) depends;
    provides = builtins.mapAttrs (n: versionsUnion) provides;
    conflicts = lib.remove null conflicts;
  };

patchDesc = patch: gen:
  if builtins.isFunction gen then
    spec: let desc = gen spec; in
      desc // lib.applyOptional (lib.applyOptional patch spec) desc
  else lib.applyOptional patch gen;
patchRepo = patch: repo: repo //
  builtins.mapAttrs (name: f: patchDesc f (repo.${name} or null)) patch;

repoPatches = patchRepo (import ../patch lib);

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
  , tests ? false
  , fixedDeps ? false
  , package ? {}
  , bootstrap ? {}
  } @ packPrefs:
lib.fix (packs: with packs; {
  inherit lib;
  prefs = packPrefs;
  inherit system os target platform label;
  withPrefs = p: packsWithPrefs (lib.recursiveUpdate packPrefs p);

  spack = if builtins.isString spackSrc then spackSrc else
    builtins.fetchGit ({ name = "spack"; url = "git://github.com/spack/spack"; } // spackSrc);

  makeSpackConfig = import ../spack/config.nix packs;

  spackConfig = makeSpackConfig (lib.recursiveUpdate defaultSpackConfig packPrefs.spackConfig);

  spackNixLib = derivation {
    name = "nix-spack-py";
    inherit system;
    builder = ../spack/install.sh;
    src = ../spack/nixpack.py;
  };

  /* common attributes for running spack */
  spackBuilder = attrs: builtins.removeAttrs (derivation ({
    inherit (packs) system platform target os spackConfig spackCache;
    builder = spackPython;
    PYTHONPATH = "${spackNixLib}:${spack}/lib/spack:${spack}/lib/spack/external";
    PATH = spackPath;
  } // attrs)) ["PYTHONPATH" "PATH" "spackConfig" "spackCache" "passAsFile"];

  /* pre-generated spack repo index cache */
  spackCache = lib.when (builtins.isAttrs spackSrc)
    (spackBuilder {
      name = "spack-cache";
      args = [../spack/cache.py];
      spackCache = null;
    });

  isVirtual = name: builtins.isList repo.${name} or null;

  /* look up a package requirement and resolve it with prefs */
  getResolver = name: pref: builtins.addErrorContext "getting package ${label}.${name}"
    (if pref == null || pref == {}
      then pkgs.${name}
      else resolvers.${name} (prefsUpdate (getPackagePrefs name) pref));

  /* look up a package with default prefs */
  getPackage = arg:
    if arg == null then
      null
    else if builtins.isString arg then
      getResolver arg null
    else if arg ? name then
      getResolver arg.name (builtins.removeAttrs arg ["name"])
    else throw "invalid package";

  /* get the list of packages a given package might depend on (from the repo, makes assumptions about repo structure) */
  getPossibleDepends = name:
    (lib.applyOptional repo.${name} (throw "getPossibleDepends ${name}")).depends or {};

  /* fill in package prefs with defaults */
  fillPrefs =
    { version ? null
    , variants ? {}
    , patches ? []
    , depends ? {}
    , extern ? null
    , provides ? {}
    , tests ? packPrefs.tests or false
    , fixedDeps ? packPrefs.fixedDeps or false
    , resolver ? packs
    }: {
      inherit version variants patches depends extern tests provides fixedDeps;
      resolver = if builtins.isString resolver then packs.${resolver} else resolver;
    };

  getPackagePrefs = name: packPrefs.package.${name} or {};

  /* resolve a named package descriptor into a concrete spec (concretize)

     Resolving a (non-virtual) package requires these sources of information:
     - R = repo.${name}: package desc from repo
     - G: global user prefs = packPrefs.(package.${name})
     - P: specific instance prefs = arg
     We describe this resolution as R(G // P).
     Resolving each dependency x involves these sources of information:
     - R': dependency desc from repo
     - C = R.depends.${x}: constraints from parent desc
     - G': global user prefs
     - P' = (G // P).depends.${x}: inherited prefs from parent
     with fixedDeps = true, we want R'(G' // P'), checked against C.
     with fixedDeps = false, we want R'((G' // P') intersect C)

     Resolving a virtual dependency is a bit different:
     - R': provider list from repo
     - C = R.depends.${x}: virtual version from parent desc
     - G': global provider prefs = packPrefs.package.${name}
     - P': inherited provider prefs from parent.
     If G' // P' is not null or empty, it should be a (list of) specific
     packages names or { name; desc...}, and these are the candidates.
     Otherwise, R' are the canditates.
     with fixedDeps = true, resolve the first candidate and check it against C.
     with fixedDeps = false, try each candidate until one matches C.
  */
  resolvePackage = pname:
    let
      /* combining preferences with descriptor to get concrete package spec */
      resolveEach = resolver: arg: pref:
        builtins.mapAttrs (n: a: resolver n a pref.${n} or null) arg;
      resolveVersion = arg: pref:
        /* special version matching: a (list of intersected) version constraint */
        let v = builtins.filter (v: lib.versionMatches v pref) arg;
        in if v == []
          then throw "${pname}: no version matching ${toString pref} from ${builtins.concatStringsSep "," arg}"
          else builtins.head v;
      resolveVariants = resolveEach (vname: arg: pref:
        let err = throw "${pname} variant ${vname}: invalid ${builtins.toJSON pref} (for ${builtins.toJSON arg})"; in
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
      resolveDepends = depends: pprefs:
        resolveEach (dname: dep: pref: let
          deptype = (t: if pprefs.tests then t else lib.remove "test" t) dep.deptype or [];
          res = pprefs.resolver.getResolver dname;
          clean = d: if d == null then d else builtins.removeAttrs d ["deptype"];
          virtualize = { deptype, version ? ":" }:
            { provides = { "${dname}" = version; }; };
          dep' = (if isVirtual dname then virtualize else clean) dep;

          /* dynamic */
          isr = builtins.elem "link" deptype;
          dpref = lib.prefsIntersect dep' pref;
          /* for link dependencies with dependencies in common with ours, we propagate our prefs down.
             this doesn't entirely ensure consistent linking, but helps in many common cases. */
          pdeps = builtins.intersectAttrs (getPossibleDepends dname) pprefs.depends;
          rdeps = lib.prefsIntersect dpref { depends = builtins.mapAttrs (n: clean) pdeps; };
          dpkg = res (if isr then rdeps else dpref);

          /* static */
          spkg = res pref;

          pkg = (if pprefs.fixedDeps then spkg else dpkg) // { inherit deptype; };
        in lib.when (deptype != [])
        (if lib.specMatches pkg.spec dep' then pkg else
          throw "${pname} dependency ${dname}: package ${builtins.toJSON spkg.spec} does not match dependency constraints ${builtins.toJSON dep'}"))
        depends pprefs.depends;

      /* create a package from a spec */
      makePackage = spec: gen: pprefs: let
          name = "${spec.name}-${spec.version}";
        in if spec.extern != null
        then {
          inherit name spec;
          out = spec.extern;
          /* externs don't provide withPrefs */
        }
        else spackBuilder {
          args = [../spack/builder.py];
          inherit name;
          spec = builtins.toJSON spec;
          passAsFile = ["spec"];
        } // {
          inherit spec;
          withPrefs = p: resolvePackage pname gen (prefsUpdate pprefs p);
        };

      /* resolve a real package into a spec */
      package = gen: pprefs: builtins.addErrorContext "resolving package ${pname}" (let
          desc = fillDesc pname (gen spec);
          prefs = fillPrefs pprefs;
          resolver = if builtins.isString resolver then packs.${resolver} else resolver;
          spec = {
            inherit (desc) name namespace provides paths;
            inherit (prefs) extern tests;
            version = if prefs.extern != null && lib.versionIsConcrete prefs.version then prefs.version
                    else resolveVersion  desc.version  prefs.version;
            patches  = desc.patches ++ prefs.patches;
            variants = resolveVariants desc.variants prefs.variants;
            depends = if prefs.extern != null then {}
                  else resolveDepends  desc.depends  prefs;
            deptypes = builtins.mapAttrs (n: d: d.deptype or null) spec.depends;
          };
        in if spec.extern != null || desc.conflicts == [] then makePackage spec gen pprefs
        else throw "${pname}: has conflicts: ${toString desc.conflicts}");

      /* resolving virtual packages, which resolve to a specific package as soon as prefs are applied */
      virtual = providers: prefs: builtins.addErrorContext "resolving virtual ${pname}" (let
          provs = if builtins.isList prefs || prefs ? name then prefs
            else providers;
          version = prefs.provides.${pname} or ":";

          /* TODO: really need to try multiple versions too (see: java) */
          opts = builtins.map getPackage (lib.toList provs);
          check = opt:
            let
              provtry = builtins.tryEval opt.spec.provides.${pname}; /* catch conflicts */
              prov = lib.when provtry.success provtry.value;
            in prov != null && lib.versionsOverlap prov version;
          choice = if prefs.fixedDeps or packPrefs.fixedDeps or false /* what if prefs is a list? */
            then opts
            else builtins.filter check opts;
        in if choice == []
          then throw "no providers for ${pname}@${version}"
          else builtins.head choice);

    in desc:
      if builtins.isList desc then
        virtual desc
      else if builtins.isFunction desc then
        package desc
      else if builtins.isAttrs desc then
        package (lib.const desc)
      else throw "${pname}: invalid package descriptor ${builtins.typeOf desc}";

  /* generate nix package metadata from spack repos */
  spackRepo = spackBuilder {
    name = "spack-repo.nix";
    args = [../spack/generate.py];
  };

  /* packs with bootstrap prefs, used for bootstrapping */
  bootstrap = packs.withPrefs ({ label = "${label}-bootstrap"; } // packPrefs.bootstrap);

  /* use this packs to bootstrap another */
  bootstrapTo = p: packs.withPrefs ({ bootstrap = packPrefs; } // p);

  /* special case of bootstrapTo where you only replace the compiler */
  withCompiler = compiler: packs.bootstrapTo {
    package = { inherit compiler; };
  };

  /* special case of withPrefs where you only replace one named package */
  withPackage = name: pkg: packs.withPrefs {
    package = { "${name}" = pkg; };
  };

  /* full metadata repo package descriptions */
  repo = patchRepo repoPatch (repoPatches (import spackRepo {
      /* utilities needed by the repo */
      inherit (lib) when versionMatches variantMatches;
      inherit platform target os;
    }));

  /* partially applied specs, which take preferences as argument */
  resolvers = builtins.mapAttrs resolvePackage repo;

  /* fully applied resolved packages with default preferences */
  pkgs = builtins.mapAttrs (name: res: res (getPackagePrefs name)) resolvers;

  /* traverse all dependencies of given package(s) that satisfy pred recursively and return them as a list (in bredth-first order) */
  findDeps = pred:
    let
      adddeps = s: pkgs: add s (builtins.filter
        (p: p != null && ! (builtins.elem p s) && pred p)
        (lib.nub (builtins.concatMap (p: builtins.attrValues p.spec.depends) pkgs)));
      add = s: pkgs: if pkgs == [] then s else adddeps (s ++ pkgs) pkgs;
    in pkg: add [] (lib.toList pkg);

  /* create a view (or an "env" in nix terms): a merged set of packages */
  view = import ../view packs;

  /* view with appropriate settings for python environments */
  pythonView = args: view ({ shbang = ["bin/*"]; wrap = ["bin/python*"]; } // args);

  modules = import ../spack/modules.nix packs;

});

in packsWithPrefs
