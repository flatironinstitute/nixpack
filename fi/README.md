# Command-line

Builds should be run on worker1000 or pcn-1-01.

## Utility script

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

## Environmnent setup

You can source `env` to setup a build environment for running `nix` command-line tools (like `nix-build`).
