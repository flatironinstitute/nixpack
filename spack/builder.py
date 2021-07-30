#!/bin/env python3
from typing import Tuple

import os
import sys
import functools

if not sys.executable: # why not?
    sys.executable = os.environ.pop('builder')

os.environ['PATH'] = '/bin:/usr/bin'
os.W_OK = 0 # hack hackity to disable writability checks (mainly for cache)

import spack.main # otherwise you get recursive import errors
import llnl.util.lang

# monkeypatch store.layout for the few things we need
class NixLayout():
    metadata_dir = '.spack'
    hidden_file_paths = (metadata_dir,)
    def metadata_path(self, spec):
        return os.path.join(spec.prefix, self.metadata_dir)
    def build_packages_path(self, spec):
        return os.path.join(self.metadata_path(spec), 'repos')
class NixStore():
    layout = NixLayout()
spack.store.store = NixStore()

# disable post_install hooks (sbang, permissions)
def post_install(spec):
    pass
spack.hooks.post_install = post_install

spack.config.command_line_scopes = [os.environ.pop('spackConfig')]
spack.config.set('config:misc_cache', os.environ.pop('spackCache'), 'command_line')
spack.config.set('config:build_stage', [os.environ.pop('NIX_BUILD_TOP')], 'command_line')
cores = int(os.environ.pop('NIX_BUILD_CORES', 0))
if cores > 0:
    spack.config.set('config:build_jobs', cores, 'command_line')

nixLogFd = int(os.environ.pop('NIX_LOG_FD', -1))
nixLogFile = None
if nixLogFd >= 0:
    import json
    nixLogFile = os.fdopen(nixLogFd, 'w')

def nixLog(j):
    if nixLogFile:
        print("@nix", json.dumps(j), file=nixLogFile)

system = os.environ.pop('system')
(target, platform) = system.split('-', 1)
archos = os.environ.pop('os')

class NixSpec(spack.spec.Spec):
    def __init__(self, label, compiler):
        super().__init__(normal=True, concrete=True)
        def getenv(*args):
            v = [label]
            v.extend(args)
            return os.environ.pop('_'.join(v))

        self.name = getenv('name')
        self.namespace = getenv('namespace')
        version = getenv('version')
        self.versions = spack.version.VersionList([spack.version.Version(version)])
        self.compiler = compiler
        self._set_architecture(target=target, platform=platform, os=archos)
        self._prefix = spack.util.prefix.Prefix(getenv())
        assert set(getenv('variants').split()) == self.package.variants.keys()
        for n, v in self.package.variants.items():
            s = getenv('variant',n)
            if s in ('', '1'):
                v = spack.variant.BoolValuedVariant(n, not not s)
            elif v.multi:
                v = spack.variant.MultiValuedVariant(n, s.split())
            else:
                v = spack.variant.AbstractVariant(n, s)
            self.variants[n] = v
        for f in self.compiler_flags.valid_compiler_flags():
            self.compiler_flags[f] = []

os.environ.pop('name')
depends = os.environ.pop('depends').split()
if 'compiler' in depends:
    comp = NixSpec('compiler', None)
    compiler = spack.spec.CompilerSpec(comp.name, comp.versions)
    spack.config.set('compilers', [{'compiler': {
        'spec': str(compiler),
        'paths': {v: os.environ.pop('compiler_'+v, None) for v in ['cc','cxx','f77','fc']},
        'modules': [],
        'operating_system': comp.architecture.os,
        'target': str(comp.architecture.target)
    }}], 'command_line')
else:
    compiler = spack.spec.CompilerSpec("null@0")
spec = NixSpec('out', compiler)
for dep in depends:
    if dep == 'compiler': continue
    dspec = spec._evaluate_dependency_conditions(dep)
    dspec.spec = NixSpec(dep, compiler)
    spec._add_dependency(dspec.spec, dspec.type)

def wrapPhase(p, f, *args):
    nixLog({'action': 'setPhase', 'phase': p})
    return f(*args)

pkg = spec.package
spack.build_environment.setup_package(pkg, True)
os.makedirs(spack.store.layout.metadata_path(spec), exist_ok=True)
for pn, pa in zip(pkg.phases, pkg._InstallPhase_phases):
    pf = getattr(pkg, pa)
    setattr(pkg, pa, functools.partial(wrapPhase, pn, pf))
spack.installer.build_process(pkg, {'verbose': True})
