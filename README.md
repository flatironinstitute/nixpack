# nixpack = [nix](https://nixos.org/nix)+[spack](https://spack.io/)

A hybrid of the [nix package manager](https://github.com/NixOS/nix) and [spack](https://github.com/spack/spack) where nix (without nixpkgs) is used to solve and manage packages, using the package repository and builds from spack.

If you love nix's expressiveness and efficiency, but don't need nixpkgs purity (in the sense of independence from the host system), if you like the spack packages but are tired of managing roots and concretizations, this may be for you.

Nix on the outside, spack on the inside.

This is a terrible, horrible work in progress, and you probably shouldn't touch it yet unless you understand both systems well.

## Implementation and terminology

In nixpkgs, there's mainly the concept of package, and arguments that can be overridden.
In spack, there are packages and specs, and specs are used in many different ways.

### package descriptor

The metadata for a spack package.
These are generated by spack/generate.py from the spack repo `package.py`s and loaded into `packs.repo`.
They look like this:

```nix
example = {
  namespace = "builtin";
  version = ["2.0" "1.2" "1.0"]; # in decreasing order of preference
  variants = {
    flag = true;
    option = ["a" "b" "c"]; # first is default
    multi = {
      a = true;
      b = false;
    };
  };
  depends = {
    /* package preferences for dependencies (see below) */
    compiler = {}; # usually implicit
    deppackage = {
      version = "1.5:2.1";
    };
    notused = null;
  };
  provides = {
    virtual = "2:"
  };
  build = {}; # extra build parameters (not usually used)
  extern = null; # a prefix string for an external installation (overrides depends, build)
  paths = {}; # paths to tools provided by this package (like cc)
};
```

Most things default to empty.
In practice, these are constructed as functions that take a resolved package spec as an argument.
This lets dependencies and such be conditional on a specific version and variants.

### package preferences

Constraints for a package that come from a dependency specifier or the user.
These are used in package descriptor depends and in user global or package preferences.
They look similar to package descriptors and can be used to override or constrain some of their values.

```
example = {
  namespace = "builtin";
  version = "1.3:1.5";
  variants = {
    flag = true;
    option = "b";
    multi = ["a" "b"];
    multi = {
      a = true;
      b = false;
    };
  };
  depends = {
    compiler = {
      name = "clang";
    };
    deppackage = {
      version = ...
    };
    virtualdep = {
      version = "virtual version";
      provider = [{ # list optional
        name = "package";
        version = "package version";
        ...
      }];
    };
  };
  extern = "/opt/local/mypackage";
};
```

### package spec

A resolved (concrete) package specifier created by applying (optional) package preferences to a package descriptor.
These are 

### package

An actual derivation.
These contain `desc`, `prefs`, and `spec` metadata attributes with the above things.

### preferences

Global user preferences.
See `prefs.nix`.

### `packs`

The world, like `nixpkgs`.
Package descriptions are in `repo`, and resolved packages are in `pkgs`.
