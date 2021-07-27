#!/bin/env python3
from typing import Tuple

import os
print(os.environ)

import spack.main # because otherwise you get recursive import errors

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
    def __init__(self, label):
        super().__init__(normal=True, concrete=True)
        def getenv(*args):
            v = [label]
            v.extend(args)
            return os.environ['_'.join(v)]

        self.name = getenv('name')
        version = getenv('version')
        self.versions = spack.version.VersionList([spack.version.Version(version)])
        (target, platform) = os.environ['system'].split('-', 1)
        self._set_architecture(target=target, platform=platform, os=os.environ['os'])
        self._prefix = getenv()
        for n in getenv('variants').split():
            s = getenv('variant',n)
            if s in ('', '1'):
                v = spack.variant.BoolValuedVariant(n, not not s)
            else:
                v = spack.variant.AbstractVariant(n, s)
            self.variants[n] = v
        # TODO: compiler, _dependents, namespace

def main():
    spack.config.command_line_scopes = [os.environ['spackConfig']]
    cores = int(os.environ['NIX_BUILD_CORES'])
    if cores > 0:
        spack.config.set('config:build_jobs', cores, 'command_line')
    spec = NixSpec('out')
    if os.environ['compiler']:
        compiler = NixSpec('compiler')
        spec.compiler = spack.spec.CompilerSpec(compiler.name, compiler.versions)
        spack.config.set('compilers', [{'compiler': {
            'spec': str(spec.compiler),
            'paths': {v: os.getenv('compiler_'+v) for v in ['cc','cxx','f77','fc']},
            'modules': [],
            'operating_system': compiler.architecture.os,
            'target': str(compiler.architecture.target)
        }}], 'command_line')
    else:
        spec.compiler = spack.spec.CompilerSpec("null@0")

    print(spec)
    print(spec.package)
    print(spec.package.compiler)

if __name__ == "__main__":
    main()
