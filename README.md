# nixpack = [nix](https://nixos.org/nix)+[spack](https://spack.io/)

A hybrid of the [nix package manager](https://github.com/NixOS/nix) and [spack](https://github.com/spack/spack) where nix (without nixpkgs) is used to solve and manage packages, using the package repository and builds from spack.

If you love nix's expressiveness and efficiency, but don't need nixpkgs purity (in the sense of independence from the host system), if you like the spack packages but are tired of managing roots and concretizations, this may be for you.

Nix on the outside, spack on the inside.

This is a terrible, horrible work in progress, and you probably shouldn't touch it yet unless you understand both systems well.
