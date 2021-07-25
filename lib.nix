rec {

  inherit (builtins)
    compareVersions
    elemAt
    head
    isList
    length
    split
    splitVersion
    tail
    trace
    ;

  flip = f: a: b: f b a;
  fix = f: let x = f x; in x;

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

  /* spack version spec semantics: does v match m? */
  versionMatches = m: v:
    let
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
    (if isList x then builtins.all pred else pred) x;
}
