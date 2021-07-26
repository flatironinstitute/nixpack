#!/bin/env python3
from typing import Tuple

import os
print(os.environ)

import spack.spec

def parseDrvName(s: str) -> Tuple[str, str]:
    """https://github.com/NixOS/nix/blob/master/src/libstore/names.cc#L27"""
    i = 0
    try:
        while True:
            d = s.index('-', i)
            i = d+1
            if not s[i].isalpha():
                return (s[:d], s[i:])
    except IndexError:
        return (s, None)
    except ValueError:
        return (s, None)

class NixSpec(spack.spec.Spec):
    def __init__(self, name, prefix):
        super().__init__(normal=True, concrete=True)
        (self.name, version) = parseDrvName(name)
        self.versions = spack.version.VersionList([spack.version.Version(version)])
        (target, platform) = os.environ['system'].split('-', 1)
        self._set_architecture(target=target, platform=platform, os=os.environ['os'])
        self._prefix = prefix
        # TODO: variants, compiler, _dependents, namespace

def main():
    spec = NixSpec(os.environ['name'], os.environ['out'])
    print(spec)
    print(spec.package)

if __name__ == "__main__":
    main()
