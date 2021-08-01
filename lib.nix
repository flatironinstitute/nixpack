rec {

  inherit (builtins)
    all
    any
    attrNames
    catAttrs
    compareVersions
    concatMap
    deepSeq
    elem
    elemAt
    filter
    foldl'
    hasAttr
    head
    isAttrs
    isFunction
    isList
    isString
    length
    listToAttrs
    mapAttrs
    match
    split
    splitVersion
    tail
    trace
    ;

  id = x: x;
  const = x: y: x;
  flip = f: a: b: f b a;
  fix = f: let x = f x; in x;
  when = c: x: if c then x else null;
  coalesce = x: d: if x == null then d else x;
  coalesces = l: let r = filter (x: x != null) l; in when (r != []) (head r);
  coalesceWith = f: a: b: if a == null then b else if b == null then a else f a b;
  mapNullable = f: a: if a == null then a else f a;

  applyOptional = f: x: if isFunction f then f x else f;

  toList = x: if isList x then x else if x == null then [] else [x];
  fromList = x: if isList x && length x == 1 then head x else x;

  traceId = x: trace x x;
  traceLabel = s: x: trace ("${s}: ${builtins.toJSON x}") x;
  traceId' = x: deepSeq x (trace x x);

  remove = e: filter (x: x != e);

  /* is a a prefix of b? */
  listHasPrefix = a: b:
    a == [] || b != [] && head a == head b && listHasPrefix (tail a) (tail b);

  union = a: b: a ++ filter (x: ! elem x a) b;

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
      vs = splitVersion v;
      versionMatch = m: let
        mr = versionRange m;
        in versionAtLeast v mr.min &&
           (versionAtMost v mr.max || listHasPrefix (splitVersion mr.max) vs);
    in any versionMatch (splitRegex "," match);

  versionsOverlap = a: b:
    let
      as = splitRegex "," a;
      bs = splitRegex "," b;
      vo = a: b: let
        ar = versionRange a;
        br = versionRange b;
      in versionAtMost ar.max br.min &&
         versionAtMost br.max ar.min;
    in any (a: any (vo a) bs) as;

  /* does concrete variant v match spec m? */
  variantMatches = v: ms: all (m:
    if isAttrs v then v.${m} else
    if isList v then elem m v else
    v == m) (toList ms);
}
