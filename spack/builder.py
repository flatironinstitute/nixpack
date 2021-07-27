#!/bin/env python3
from typing import Tuple

import os
print(os.environ)
import sys

if not sys.executable: # why not?
    sys.executable = os.environ['builder']

os.environ['PATH'] = '/bin:/usr/bin'

import spack.main # because otherwise you get recursive import errors

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

def post_install(spec):
    pass
spack.hooks.post_install = post_install

class NixSpec(spack.spec.Spec):
    def __init__(self, label, compiler):
        super().__init__(normal=True, concrete=True)
        def getenv(*args):
            v = [label]
            v.extend(args)
            return os.environ['_'.join(v)]

        self.name = getenv('name')
        self.namespace = getenv('namespace')
        version = getenv('version')
        self.versions = spack.version.VersionList([spack.version.Version(version)])
        self.compiler = compiler
        (target, platform) = os.environ['system'].split('-', 1)
        self._set_architecture(target=target, platform=platform, os=os.environ['os'])
        self._prefix = spack.util.prefix.Prefix(getenv())
        for n in getenv('variants').split():
            s = getenv('variant',n)
            if s in ('', '1'):
                v = spack.variant.BoolValuedVariant(n, not not s)
            else:
                v = spack.variant.AbstractVariant(n, s)
            self.variants[n] = v
        for f in self.compiler_flags.valid_compiler_flags():
            self.compiler_flags[f] = []

spack.config.command_line_scopes = [os.environ['spackConfig']]
spack.config.set('config:build_stage', [os.environ['PWD']], 'command_line')
cores = int(os.environ['NIX_BUILD_CORES'])
if cores > 0:
    spack.config.set('config:build_jobs', cores, 'command_line')
if os.getenv('compiler'):
    comp = NixSpec('compiler', None)
    compiler = spack.spec.CompilerSpec(comp.name, comp.versions)
    spack.config.set('compilers', [{'compiler': {
        'spec': str(compiler),
        'paths': {v: os.getenv('compiler_'+v) for v in ['cc','cxx','f77','fc']},
        'modules': [],
        'operating_system': comp.architecture.os,
        'target': str(comp.architecture.target)
    }}], 'command_line')
else:
    compiler = spack.spec.CompilerSpec("null@0")
spec = NixSpec('out', compiler)
for dep in os.environ['depends'].split():
    depspec = NixSpec(dep, compiler)
    print(depspec)

pkg = spec.package
spack.build_environment.setup_package(pkg, True)
os.makedirs(spack.store.layout.metadata_path(spec), exist_ok=True)
spack.installer.build_process(pkg, {'verbose': True})
