#!/bin/env python3
import os
import functools
import shutil
import json

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

os.environ.pop('name')
nixspec = os.environ.pop('specPath')
spec = nixpack.NixSpec(os.environ.pop('out'), nixspec)
if spec.compiler != nixpack.nullCompiler:
    spack.config.set('compilers', [{'compiler': {
        'spec': str(spec.compiler),
        'paths': spec.compiler_spec.paths,
        'modules': [],
        'operating_system': spec.compiler_spec.architecture.os,
        'target': nixpack.system.split('-', 1)[0],
    }}], 'command_line')
conc = spack.concretize.Concretizer()
conc.adjust_target(spec)
spack.spec.Spec.inject_patches_variant(spec)
spec._mark_concrete()

pkg = spec.package
print(spec.tree(cover='edges', format=spack.spec.default_format + ' {prefix}'))

opts = {
        'install_deps': False,
        'verbose': False,
        'tests': spec.tests,
    }

# create and stash some metadata
spack.build_environment.setup_package(pkg, True)
os.makedirs(pkg.metadata_dir, exist_ok=True)
with open(os.path.join(spec.prefix, nixpack.NixSpec.nixSpecFile), 'w') as sf:
    json.dump(spec.nixspec, sf)

# log build phases to nix
def wrapPhase(p, f, *args):
    nixpack.nixLog({'action': 'setPhase', 'phase': p})
    return f(*args)

for pn, pa in zip(pkg.phases, pkg._InstallPhase_phases):
    pf = getattr(pkg, pa)
    setattr(pkg, pa, functools.partial(wrapPhase, pn, pf))

# do the actual install
spack.installer.build_process(pkg, opts)

# cleanup spack logs (to avoid spurious references)
#shutil.rmtree(pkg.metadata_dir)
