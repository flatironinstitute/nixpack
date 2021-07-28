rec {

  inherit (builtins)
    all
    any
    attrNames
    catAttrs
    compareVersions
    concatMap
    elem
    elemAt
    filter
    foldl'
    hasAttr
    head
    isAttrs
    isList
    isString
    length
    listToAttrs
    mapAttrs
    split
    splitVersion
    tail
    trace
    ;

  flip = f: a: b: f b a;
  fix = f: let x = f x; in x;
  when = c: x: if c then x else null;
  coalesce = x: d: if x == null then d else x;
  coalesces = l: let r = filter (x: x != null) l; in when (r != []) (head r);
  coalesceWith = f: a: b: if a == null then b else if b == null then a else f a b;

  traceId = x: trace x x;

  /* is a a prefix of b? */
  listHasPrefix = a: b:
    let
      la = length a;
      lb = length b;
    in
      la == 0 || lb >= la && head a == head b && listHasPrefix (tail a) (tail b);

  versionOlder   = v1: v2: compareVersions v2 v1 > 0;
  versionNewer   = v1: v2: compareVersions v2 v1 < 0;
  versionAtLeast = v1: v2: compareVersions v2 v1 <= 0;
  versionAtMost  = v1: v2: compareVersions v2 v1 >= 0;

  mapKeys = f: set:
    listToAttrs (map (a: { name = f a; value = set.${a}; }) (attrNames set));

  mergeWithKeys = f: a: b:
    mapAttrs (k: v: if hasAttr k a && hasAttr k b then f k a.${k} v else v) (a // b);

  mergeWith = f: mergeWithKeys (k: f);

  /* like nixpkgs.lib.recursiveUpdate but treat nulls as missing */
  recursiveUpdate = a: b:
    if isAttrs a && isAttrs b then
      mergeWith recursiveUpdate a b
    else if b == null then a
    else b;

  /* should this be lazy? */
  concatAttrs = foldl' (a: b: a // b) {};

  /* spack version spec semantics: does concrete version v match spec m? */
  versionMatches = v: match:
    if match == null then true else
    if isList match then all (versionMatches v) match else
    let
      versionMatch = m: let
        ms = split ":" m;
        ml = length ms;
        vs = splitVersion v;
        ma = head ms;
        mb = elemAt ms 2;
      in     if ml == 1 then listHasPrefix (splitVersion ma) vs
        else if ml == 3 then versionAtLeast v ma &&
          (versionAtMost v mb || listHasPrefix (splitVersion mb) vs)
        else throw "invalid version match ${m}";
    in any versionMatch (filter isString (split "," match));

  /* does concrete variant v match spec m? */
  variantMatches = v: m:
    if isAttrs v then v.${m} else
    if isList v then elem m v else
    v == m;
}
