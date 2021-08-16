#!/bin/env python3
import os
import functools
import shutil
import json

import nixpack
import spack

# disable post_install hooks (sbang, permissions)
def post_install(spec):
    pass
spack.hooks.post_install = post_install

nixpack.getVar('name')
nixspec = nixpack.getJson('spec')
spec = nixpack.NixSpec.get(nixspec, nixpack.getVar('out'))
spec.concretize()

pkg = spec.package
print(spec.tree(cover='edges', format=spack.spec.default_format + ' {/hash}'))

opts = {
        'install_deps': False,
        'verbose': False,
        'tests': spec.tests,
    }

setup = nixpack.getVar('setup', None)
if setup:
    exec(setup)

origenv = os.environ.copy()
# create and stash some metadata
spack.build_environment.setup_package(pkg, True, context='build')
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

# we do this even if not testing as it may create more things (e.g., perl "extensions")
os.environ.clear()
os.environ.update(origenv)
spack.build_environment.setup_package(pkg, True, context='test')
