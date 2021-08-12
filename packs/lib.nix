with builtins;
rec {

  id = x: x;
  const = x: y: x;
  flip = f: a: b: f b a;
  fix = f: let x = f x; in x;
  when = c: x: if c then x else null;
  coalesce = x: d: if x == null then d else x;
  coalesces = l: let r = remove null l; in when (r != []) (head r);
  coalesceWith = f: a: b: if a == null then b else if b == null then a else f a b;
  mapNullable = f: a: if a == null then a else f a;

  applyOptional = f: x: if isFunction f then f x else f;

  cons = x: l: [x] ++ l;
  toList = x: if isList x then x else if x == null then [] else [x];
  fromList = x: if isList x && length x == 1 then head x else x;

  traceId = x: trace x x;
  traceLabel = s: x: trace ("${s}: ${toJSON x}") x;
  traceId' = x: deepSeq x (traceId x);

  remove = e: filter (x: x != e);
  nub = l:
    if l == [] then l else
    let x = head l; r = nub (tail l); in
    if elem x r then r else cons x r;
  nubBy = eq: l:
    if l == [] then l else
    let x = head l; in
    cons x (nubBy eq (filter (y: ! (eq x y)) (tail l)));

  /* is a a prefix of b? */
  listHasPrefix = a: b:
    a == [] || b != [] && head a == head b && listHasPrefix (tail a) (tail b);

  union = a: b: a ++ filter (x: ! elem x a) b;

  /* do the elements of list a all appear in-order in list b? */
  subsetOrdered = a: b:
    a == [] || (b != [] && subsetOrdered (tail a) (if head a == head b then tail b else b));

  mapKeys = f: set:
    listToAttrs (map (a: { name = f a; value = set.${a}; }) (attrNames set));

  mergeWithKeys = f: a: b:
    mapAttrs (k: v: if hasAttr k a && hasAttr k b then f k a.${k} v else v) (a // b);

  mergeWith = f: mergeWithKeys (k: f);

  recursiveUpdate = a: b:
    if isAttrs a && isAttrs b then
      mergeWith recursiveUpdate a b
    else b;

  /* should this be lazy? */
  concatAttrs = foldl' (a: b: a // b) {};

  filterAttrs = pred: set:
    listToAttrs (concatMap (name: let v = set.${name}; in if pred name v then [{ inherit name; value = v; }] else []) (attrNames set));

  splitRegex = r: s: filter isString (split r s);

  versionOlder   = v1: v2: compareVersions v1 v2 < 0;
  versionNewer   = v1: v2: compareVersions v1 v2 > 0;
  versionAtLeast = v1: v2: compareVersions v1 v2 >= 0;
  versionAtMost  = v1: v2: compareVersions v1 v2 <= 0;
  versionAtMostMatch = v1: v2: versionAtMost v1 v2 || listHasPrefix (splitVersion v2) (splitVersion v1);

  versionIsConcrete = v: v != null && match "[:,]" v == null;

  versionRange = v: let
      s = splitRegex ":" v;
      l = length s;
    in
      if l == 1 then { min = v; max = v; } else
      if l == 2 then { min = head s; max = elemAt s 1; } else
      throw "invalid version range ${v}";

  /* spack version spec semantics: does concrete version v match spec m? */
  versionMatches = v: match:
    if match == null then true else
    if isList match then all (versionMatches v) match else
    let
      versionMatch = m: let
        mr = versionRange m;
        in versionAtLeast v mr.min &&
           (versionAtMostMatch v mr.max);
    in any versionMatch (splitRegex "," match);

  versionsOverlap = a: b:
    let
      as = splitRegex "," a;
      bs = splitRegex "," b;
      vo = a: b: let
        ar = versionRange a;
        br = versionRange b;
      in versionAtMostMatch ar.max br.min &&
         versionAtMostMatch br.max ar.min;
    in any (a: any (vo a) bs) as;

  /* does concrete variant v match spec m? */
  variantMatches = v: ms: all (m:
    if isAttrs v then v.${m} else
    if isList v then elem m v else
    v == m) (toList ms);

  /* a very simple version of Spec.format */
  specFormat = fmt: spec: let
    variantToString = n: v:
           if v == true  then "+"+n
      else if v == false then "~"+n
      else " ${n}="+
          (if isList v then concatStringsSep "," v
      else if isAttrs v then concatStringsSep "," (map (n: variantToString n v.${n}) (attrNames v))
      else toString v);
    fmts = {
      inherit (spec) name version;
      variants = concatStringsSep "" (map (v: variantToString v spec.variants.${v})
        (sort (a: b: typeOf spec.variants.${a} < typeOf spec.variants.${b}) (attrNames spec.variants)));
    };
    in replaceStrings (map (n: "{${n}}") (attrNames fmts)) (attrValues fmts) fmt;

  /* simple name@version */
  specName = specFormat "{name}@{version}";

  /* like spack default format */
  specToString = specFormat "{name}@{version}{variants}";

  /* check that a given spec conforms to the specified preferences */
  specMatches = spec:
    { version ? null
    , variants ? {}
    , patches ? []
    , depends ? {}
    , provides ? {}
    , extern ? spec.extern
    } @ prefs:
       versionMatches spec.version version
    && all (name: variantMatches (spec.variants.${name} or null) variants.${name}) (attrNames variants)
    && subsetOrdered patches spec.patches
    && all (name: specMatches spec.depends.${name} depends.${name}) (attrNames depends)
    && all (name: versionsOverlap spec.provides.${name} provides.${name}) (attrNames provides)
    && spec.extern == extern;

  /* unify two prefs, making sure they're compatible */
  prefsIntersect = let
      err = a: b: throw "incompatible prefs: ${toJSON a} vs ${toJSON b}";
      intersectScalar = a: b: if a == b then a else err a b;
      intersectors = {
        version = a: b: union (toList a) (toList b);
        variants = mergeWith (a: b: if a == b then a else
          if isList a && isList b then union a b
          else err a b);
        patches = a: b: a ++ b;
        depends = mergeWith prefsIntersect;
        extern = intersectScalar;
        tests = intersectScalar;
        fixedDeps = intersectScalar;
        resolver = intersectScalar;
        deptype = union;
      };
    in coalesceWith (mergeWithKeys (k: getAttr k intersectors));

  /* unify a list of package prefs, making sure they're compatible */
  prefsIntersection = l: if builtins.isList l then foldl' prefsIntersect null l else l;

}
