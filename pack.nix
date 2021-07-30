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

isPackage = p: p ? withPrefs;

isRDepend = d: let t = d.type or []; in
  builtins.elem "link" t || builtins.elem "run" t;

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

  /* look up a package requirement and instantiate it with prefs */
  getPackage = arg:
    if /* builtins.trace "${label}.${builtins.toJSON arg}" */ arg == null then
      pref: null
    else if builtins.isString arg then
      pkgsWithPrefs.${arg} or (throw "package ${arg} not found")
    else if isPackage arg then
      arg.withPrefs /* is this needed? */
    else if arg ? name then
      pref: getPackage arg.name (prefsIntersect arg pref)
    else throw "invalid package";

  spackPackageWithPrefs = pname:
    let
      /* default package descriptor */
      defaults = {
        namespace = "builtin";
        version = [];
        variants = {};
        depends = {
          compiler = {
            type = ["build"];
          };
        };
        provides = {};
        build = {};
        paths = {};
      };

      /* combining preferences with descriptor to get concrete package spec */
      resolveEach = resolver: arg: pref:
        builtins.mapAttrs (name: resolver name pref.${name} or null) arg;
      resolvers = {
        version = mprefs: arg: pref:
          /* special version matching: a (list of intersected) version constraint */
          let v = builtins.filter (v: lib.versionMatches v pref) arg;
          in if v == []
            then throw "${pname}: no version matching ${toString pref} from ${builtins.concatStringsSep "," arg}"
            else builtins.head v;
        variants = mprefs: resolveEach (name: pref: arg:
          let err = throw "${pname}: invalid variant ${name}: ${toString pref} (for ${toString arg})"; in
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
        depends = mprefs: arg: pref:
          if mprefs.extern or null != null then null else let
            /* filter out disabled or test-only depends */
            select = name: dep: dep != null && (mprefs.tests == true || dep.type != ["test"]);
            /* combine package-specified prefs with user prefs */
            deps = resolveEach (name: prefsIntersect) (lib.filterAttrs select arg) pref;
            /* propagate runtime depends into children */
            rdeps = lib.filterAttrs (name: isRDepend) deps;
            rdeps' = builtins.mapAttrs (name: dep: builtins.removeAttrs dep ["type"]) rdeps;
            depprefs = deps // builtins.mapAttrs (name: dep: 
              prefsIntersect dep { depends = rdeps'; }) rdeps;
          /* resolve an actual package */
          in builtins.mapAttrs getPackage depprefs;
      };

      /* adding metadata environment variables about a package to the build */
      renderVariant = v:
        if builtins.isAttrs v then
          builtins.filter (n: v.${n}) (builtins.attrNames v)
        else v;
      render = lab: pkg:
        let
          prep = p: lib.mapKeys (a: "${p}_${a}");
          vars = builtins.parseDrvName pkg.name // {
              namespace = pkg.spec.namespace;
              variants = builtins.attrNames pkg.spec.variants;
            } // prep "variant" (builtins.mapAttrs (n: renderVariant) pkg.spec.variants)
              // pkg.paths or {};
        in prep lab vars;
      renderDepends = deps:
        let depnames = builtins.attrNames deps;
        in { depends = depnames; } // lib.concatAttrs (map (d:
          { "${d}" = deps.${d}; } // render d deps.${d}) depnames);

      /* constructing a real package */
      package = gen: prefs: let
          desc = lib.recursiveUpdate defaults (gen spec) // repoOverrides.${pname} or {};
          name = "${pname}-${spec.version}";
          mprefs = prefsUpdate (prefsUpdate packPrefs.global packPrefs.package.${pname} or null) prefs;
          resolved = builtins.mapAttrs (a: resolve: resolve mprefs desc.${a} mprefs.${a} or null) resolvers;
          spec = resolved // {
            inherit (desc) namespace;
            versionMatches = lib.versionMatches resolved.version;
            variantMatches = v: lib.variantMatches resolved.variants.${v};
          };
          extern = mprefs.extern or null;
          build = spackBuilder // {
            args = [spack/builder.py];
            inherit spackCache name;
            inherit (mprefs) tests;
          } // render "out" { inherit name spec; }
            // renderDepends spec.depends;
          drv = if extern != null
            then { inherit name; outPath = extern; }
            else derivation (build // desc.build);
        in drv // {
            inherit (desc) provides;
            inherit spec;
            paths = builtins.mapAttrs (a: p: "${drv.outPath}/${p}") desc.paths;
            prefs = mprefs;
            /* overrides */
            withPrefs = p: spackPackageWithPrefs pname gen (prefsUpdate prefs p);
            withDesc = gen': spackPackageWithPrefs pname (args: gen args // gen' args) prefs;
          };

      /* constructing virtual packages, which resolve to a specific package as soon as prefs are applied */
      virtual = providers: prefs: let
          provs = lib.toList (packPrefs.providers.${pname} or providers);
          vers = prefs.version or ":";
          opts = builtins.map (o: getPackage o null) (lib.toList (prefs.provider or provs));
          checkOpt = opt:
            let prov = opt.provides.${pname} or null; in 
            prov != null && lib.versionsOverlap vers prov;
          choice = builtins.filter checkOpt opts;
        in if choice == [] then "no providers for ${pname}@${vers}" else builtins.head choice;

    in desc:
      if builtins.isList desc then
        virtual desc
      else if builtins.isFunction desc then
        package desc
      else if builtins.isAttrs desc then
        package (lib.const desc)
      else throw "${pname}: invalid package descriptor ${toString (builtins.typeOf desc)}";

  spackPackage = name: gen: spackPackageWithPrefs name gen null;

  # generate nix package metadata from spack repos
  spackRepo = derivation (spackBuilder // {
    name = "spack-repo.nix";
    args = [spack/generate.py];
    inherit spackCache;
  });

  systemSplit = lib.splitRegex "-" packPrefs.system;
  repoLib = {
    /* utilities needed by the repo */
    inherit (lib) when;
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

  /* partially applied packages, which take preferences as argument */
  pkgsWithPrefs = builtins.mapAttrs spackPackageWithPrefs repo // {
    compiler = bootstrapPacks.getPackage prefs.compiler;
  };

  /* fully applied resolved packages with default preferences */
  pkgs = builtins.mapAttrs (name: pkg: pkg null) pkgsWithPrefs;

});

in packsWithPrefs
