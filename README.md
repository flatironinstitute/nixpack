# nixpack = [nix](https://nixos.org/nix)+[spack](https://spack.io/)

A hybrid of the [nix package manager](https://github.com/NixOS/nix) and [spack](https://github.com/spack/spack) where nix (without nixpkgs) is used to solve and manage packages, using the package repository and builds from spack.

If you love nix's expressiveness and efficiency, but don't need the purity of nixpkgs (in the sense of independence from the host system)... if you like the spack packages but are tired of managing roots and concretizations, this may be for you.
Nix on the outside, spack on the inside.

While this is largely functional, it is still a work in progress, and you probably shouldn't touch it yet unless you understand both systems well.

## Usage

- install and configure nix sufficient to build derivations
- edit `default.nix` (`bootstrapPacks.package.compiler` is critical)
- run `nix-build -A pkgs.foo` to build the spack package `foo`
- see `fi.nix` for a complete working example with view and modules: `nix-build -A mods fi.nix`

## Compatibility

nixpack uses an unmodified checkout of spack (as specified in `spackSrc`), and should work with other forks as well.
However, it makes many assumptions about the internals of spack builds, so may not work on different versions.

## Implementation and terminology

In nixpkgs, there's mainly the concept of package, and arguments that can be overridden.
In spack, there are packages and specs, and "spec" is used in many different ways.

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
    virtual = "2:";
  };
  paths = {}; # paths to tools provided by this package (like cc)
  patches = []; # extra patches to apply (in addition to those in spack)
  conflicts = []; # any conflicts (non-empty means invalid)
};
```

Most things default to empty.
In practice, these are constructed as functions that take a resolved package spec as an argument.
This lets dependencies and such be conditional on a specific version and variants.

### package preferences

Constraints for a package that come from a dependency specifier or the user.
These are used in package descriptor depends and in user global or package preferences.
They look similar to package descriptors and can be used to override or constrain some of their values.

```nix
example = {
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
      name = "provider";
      version = ...;
      ...
    };
  };
  patches = []; # extra patches to apply (in additon to those in the descriptor)
  extern = "/opt/local/mypackage"; # a prefix string or derivation (e.g., nixpkgs package) for an external installation (overrides depends)
  fixedDeps = false; # only use user preferences to resolve dependencies (see default.nix)
  resolver = "set"; # name of set to use to resolve dependencies
  target = "microarch"; # defaults to currentSystem (e.g., x86_64)
  verbose = true; # to enable nix-build -Q and nix-store -l (otherwise only spack keeps build logs)
};
```

### package spec

A resolved (concrete) package specifier created by applying (optional) package preferences to a package descriptor.

### package

An actual derivation.
These contain a `spec` metadata attribute.

### compiler

Rather than spack's dedicated `%compiler` concept, we introduce a new virtual "compiler" that all packages depend on and is provided by gcc and llvm (by default).
By setting the package preference for compiler, you determine which compiler to use.

### `packs`

The world, like `nixpkgs`.
It contains `repo` with package descriptor generators and `pkgs`.
You can have one or more `packs` instances.

Each instance is defined by a set of global user preferences, as passed to `import ./packs`.
You can also create additional sets based on another using `packs.withPrefs`.
See [`default.nix`](default.nix) for preferences that can be set.
Thus, difference package sets can have different providers or package settings (like a different compiler, mpi version, blas provider, variants, etc.).

### Bootstrapping

The default compiler is specified in `default.nix` by `compiler = bootstrapPacks.pkgs.gcc` which means that the compiler used to build everything is `packs` comes from `bootstrapPacks`, and is built with the preferences and compiler defined there.
`bootstrapPacks` in turn specifies a compiler of gcc with `extern` set, i.e., one from the host system.
This compiler is used to build any other bootstrap packages, which are then used to build the main compiler.
You could specify more extern packages in bootstrap to speed up bootstrapping.

You could also add additional bootstrap layers by setting the bootstrap compiler `resolver` to a different set.
You could also replace specific dependencies or packages from a different `packs` set to bootstrap or modify other packages.

# Flatiron Specific

The script `fi` can help with common tasks.
You can source `env` to setup a build environment.
