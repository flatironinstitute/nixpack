# Flatiron Modules

This directory contains all the configuration for building the FI modules used on rusty and popeye.

## Package management

Most configuration goes in the [`default.nix`](default.nix) file.
There are a few important sections you may need to interact with.
Search for "----- *header*" to find them.

### global package preferences

This section is an alphabetical list of key-value pairs of package preferences that apply globally.
That is, all modules and all their dependencies used these settings.
For example, this makes the default hdf5 version 1.10.x and enables some features.
These can still be overridden for individual modules or specific dependencies.

```
hdf5 = {
  version = "1.10";
  variants = {
    hl = true;
    fortran = true;
    cxx = true;
  };
};
```

For example, if you get an error about "XXX dependency YYY: package YYY does not match dependency constraints ZZZ", you may have to add a global preference like:

```
YYY = {
   # for XXX
   ZZZ
};
```

### Core modules

The core modules are those built only with the default compiler and without MPI.
This includes mainly command-line tools or things without fortran libraries that the user may want to link against.
This is a simple list of packages in alphabetical order.
You can add simple packages names here, or `(PACKAGE.withPrefs { ... })` to override global preferences.
You can also add module settings with `{ pkg = PACKAGE; ... }`.

### compiler modules

These modules are build with all compilers (which is really just whatever versions of gcc we've enabled).
This should include libraries that may change between compilers, for example fortran or C++ libraries or other things that may impact performance or linking.
This is otherwise a list just like core modules.

#### compilers

The list of enabled compilers, each of which is used to build all packages in this section

#### MPI modules

These modules are built with all MPI libraries (crossed with all compilers).
This is also really just a list, but has a lot of conditionals as some things only build with some compilers or MPI combinations.

##### mpis

The list of all MPI libraries, used to build all packages in this section.

##### python+mpi modules

These modules are built with for all python versions and MPI libraries (crossed with all compilers).
It has both a list of python packages that get combined into a view (like python packages below), and a list of modules build with these pythons (though currently this only includes triqs, which is conditioned to only build for the default python and mpi).

#### python packages

These packages are all combined into a single view and exposed as a single module, so should really only contain python packages.
Otherwise it's just another list of packages.
These are built for all enabled python versions (crossed with all compilers).

##### python

The list of all python versions, used to build all packages in this section.

### nixpkgs modules

Modules built from nixpkgs.
This should only be for applications, as they are built purely from nixpkgs, including its compiler and libc.

### misc modules

Other pseudo-modules that don't correspond to packages.

## Command-line usage

Builds and other operations should be run on worker1000 or pcn-1-01.
To test a change, just run "fi/run build -j 1 --cores 8" (or whatever parallelism you prefer).
This will (if successful) produce a "result" directory with the modules.
You can unset MODULEPATH and source "result/setup.sh" in your shell to try out the newly built modules.

If some package fails to build, you can re-run with "-K" and then (as root) go look at the failed build in /dev/shm/nix-build-NAME (which you should manually clean up when done).

### Utility script

The script [`run`](run) can help with common tasks (some of which are more generally useful):
```
Usage: fi/run COMMAND

Commands:

  build        Build modules into result.  Takes the same arguments as
               nix-build (-jN, --cores M, -K, ...).
  spec [PKG]   Print the spec tree for a specific package or all modules,
               along with the total number of unique packages.
  gc           Cleanup any unreferenced nix stores (nix-store --gc).
  release      Publish a release profile for...
    modules    nixpack lmod modules (default)
    jupyter    jupyterhub server environment
    nix        nix build environment
  spack ...    Run a spack command in the nixpack environment (things like list
               and info work, but those managing packages will not)
```

### Environment setup

You can source `env` to setup a build environment for running `nix` command-line tools (like `nix-build`).
For example, to build a single package into `result`, run:
```
nix-build -A pkgs.packagename -j 1 --cores 8 fi
```

### Releases

To do a release:

1. `fi/run release` (or `fi/run release all` if enough has changed to affect jupyter, nix, lmod, etc., or whatever subset makes sense)
2. Release should now show up as new `modules` version, which you can load to test.
3. Update default symlink in /cm/shared/sw/lmod/modules/modules when ready.
4. Run `fi/run modules` to update cache (after any change to modules).
