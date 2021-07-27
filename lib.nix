rec {

  inherit (builtins)
    all
    attrNames
    catAttrs
    compareVersions
    concatMap
    elemAt
    head
    isAttrs
    isList
    length
    listToAttrs
    split
    splitVersion
    tail
    trace
    ;

  flip = f: a: b: f b a;
  fix = f: let x = f x; in x;
  coalesce = x: d: if x == null then d else x;

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

  /* spack version spec semantics: does v match m? (TODO: commas) */
  versionMatches = m: v:
    if m == null then true else let
      ms = split ":" m;
      ml = length ms;
      vs = splitVersion v;
      ma = head ms;
      mb = elemAt ms 2;
    in     if ml == 1 then listHasPrefix (splitVersion ma) vs
      else if ml == 3 then versionAtLeast v ma &&
        (versionAtMost v mb || listHasPrefix (splitVersion mb) vs)
      else throw "invalid version match ${m}";

  /* return "pred x" or "all pred x" if x is a list */
  allIfList = pred: x:
    (if isList x then all pred else pred) x;

  mapKeys = f: set:
    listToAttrs (map (a: { name = f a; value = set.${a}; }) (attrNames set));

  /* stolen from nix (could be improved for our case) */
  zipAttrsWith = f: sets:
    listToAttrs (map (name: {
      inherit name;
      value = f name (catAttrs name sets);
    }) (concatMap attrNames sets));

  recursiveUpdate = lhs: rhs:
    let f = attrPath:
      zipAttrsWith (n: values:
        let here = attrPath ++ [n]; in
        if tail values == []
        || !(isAttrs (head (tail values)) && isAttrs (head values)) then
          head values
        else
          f here values
      );
    in f [] [rhs lhs];
}
