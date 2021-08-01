#!/bin/env python3
from typing import Tuple

import os
import functools
import shutil
import json

#from pprint import pprint
#pprint(dict(os.environ))

import nixpack
import spack
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

nullCompiler = spack.spec.CompilerSpec('gcc', '0')
nixStore = os.environ.pop('NIX_STORE')

class NixSpec(spack.spec.Spec):
    # to re-use identical specs so id is reasonable
    specCache = dict()
    nixSpecFile = '.nixpack.spec';
    def __init__(self, spec, prefix):
        if isinstance(spec, str):
            self.specCache[spec] = self
            with open(spec, 'r') as sf:
                spec = json.load(sf)

        super().__init__(normal=True, concrete=True)
        self.name = spec['name']
        self.namespace = spec['namespace']
        version = spec['version']
        self.versions = spack.version.VersionList([spack.version.Version(version)])
        self._set_architecture(target=target, platform=platform, os=archos)
        self._prefix = spack.util.prefix.Prefix(prefix)
        self.external_path = spec['extern']

        variants = spec['variants']
        assert variants.keys() == self.package.variants.keys()
        for n, s in variants.items():
            v = self.package.variants[n]
            if isinstance(s, bool):
                v = spack.variant.BoolValuedVariant(n, s)
            elif isinstance(s, list):
                v = spack.variant.MultiValuedVariant(n, s)
            elif isinstance(s, dict):
                v = spack.variant.MultiValuedVariant(n, [k for k,v in s.items() if v])
            else:
                v = spack.variant.AbstractVariant(n, s)
            self.variants[n] = v
        for f in self.compiler_flags.valid_compiler_flags():
            self.compiler_flags[f] = []
        self.tests = spec['tests']
        self.paths = {n: os.path.join(self.prefix, p) for n, p in spec['paths'].items()}
        self.compiler = nullCompiler
        self._as_compiler = None
        # would be nice to use nix hash, but nix and python use different base32 alphabets
        #if not spec['extern'] and prefix.startswith(nixStore):
        #    self._hash, nixname = prefix[len(nixStore):].lstrip('/').split('-', 1)

        for n, d in spec['depends'].items():
            if isinstance(d, str):
                key = d
            else:
                # extern: name + prefix should be enough
                key = f"{d['name']}:{d['out']}"
            try:
                spec = self.specCache[key]
            except KeyError:
                if isinstance(d, str):
                    spec = NixSpec(os.path.join(d, self.nixSpecFile), d)
                else:
                    spec = NixSpec(d['spec'], d['out'])
                self.specCache[key] = spec
            if n == 'compiler':
                self.compiler_spec = spec
                self.compiler = spec.as_compiler
            else:
                dspec = self._evaluate_dependency_conditions(n)
                dspec.spec = spec
                self._add_dependency(dspec.spec, dspec.type)

    @property
    def as_compiler(self):
        if not self._as_compiler:
            self._as_compiler = spack.spec.CompilerSpec(self.name, self.versions)
        return self._as_compiler

os.environ.pop('name')
nixspec = os.environ.pop('specPath')
spec = NixSpec(nixspec, os.environ.pop('out'))
if spec.compiler != nullCompiler:
    spack.config.set('compilers', [{'compiler': {
        'spec': str(spec.compiler),
        'paths': spec.compiler_spec.paths,
        'modules': [],
        'operating_system': archos,
        'target': target,
    }}], 'command_line')
else:
    pass

opts = {
        'install_deps': False,
        'verbose': False,
        'tests': spec.tests,
    }

pkg = spec.package
print(spec.tree(cover='edges', format=spack.spec.default_format + ' {prefix}'))
spack.build_environment.setup_package(pkg, True)

# create and stash some metadata
mtdp = spack.store.layout.metadata_path(spec)
os.makedirs(mtdp, exist_ok=True)
shutil.copyfile(nixspec, os.path.join(spec.prefix, NixSpec.nixSpecFile))
with open(os.path.join(mtdp, "spec"), "w") as sf:
    print(spec, file=sf)

# log build phases to nix
def wrapPhase(p, f, *args):
    nixLog({'action': 'setPhase', 'phase': p})
    return f(*args)

for pn, pa in zip(pkg.phases, pkg._InstallPhase_phases):
    pf = getattr(pkg, pa)
    setattr(pkg, pa, functools.partial(wrapPhase, pn, pf))

# do the actual install
spack.installer.build_process(pkg, opts)
