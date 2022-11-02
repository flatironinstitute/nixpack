#!/bin/env python3
import os
import functools
import shutil
import json

import nixpack
import spack

# disable pre_ and post_install hooks (sbang, permissions, licensing)
def noop_hook(spec):
    pass
spack.hooks.pre_install = noop_hook
spack.hooks.post_install = noop_hook

nixpack.getVar('name')
nixspec = nixpack.getJson('spec')

# add any dynamic packages
repoPkgs = nixpack.getVar('repoPkgs', '').split(' ')
for i, r in enumerate(nixpack.repoPath.repos):
        try:
            p = repoPkgs[i]
        except IndexError:
            continue
        if p:
            os.symlink(p, r.dirname_for_package_name(nixspec['name']))

spec = nixpack.NixSpec.get(nixspec, nixpack.getVar('out'))
spec.concretize()

pkg = spec.package
pkg.run_tests = spec.tests
print(spec.tree(cover='edges', format=spack.spec.default_format + ' {/hash}', show_types=True))

opts = {
        'install_deps': False,
        'verbose': not not nixpack.getVar('verbose'),
        'tests': spec.tests,
    }

# package-specific fixes
os.environ['CCACHE_DISABLE'] = '1'
if 'go' in spec._dependencies:
    # move go cache to tmp
    os.environ['GOCACHE'] = os.path.join(os.environ['TMPDIR'], 'go-cache')

setup = nixpack.getVar('setup', None)
post = nixpack.getVar('post', None)
if setup:
    exec(setup)

origenv = os.environ.copy()
# create and stash some metadata
spack.build_environment.setup_package(pkg, True, context='build')
os.makedirs(pkg.metadata_dir, exist_ok=True)

# log build phases to nix
def wrapPhase(p, f, *args):
    nixpack.nixLog({'action': 'setPhase', 'phase': p})
    return f(*args)

for pn, pa in zip(pkg.phases, pkg._InstallPhase_phases):
    pf = getattr(pkg, pa)
    setattr(pkg, pa, functools.partial(wrapPhase, pn, pf))

# make sure cache is group-writable (should be configurable, ideally in spack)
os.umask(0o002)
# do the actual install
spack.installer.build_process(pkg, opts)

# we do this even if not testing as it may create more things (e.g., perl "extensions")
os.environ.clear()
os.environ.update(origenv)
spack.build_environment.setup_package(pkg, True, context='test')

with open(os.path.join(spec.prefix, nixpack.NixSpec.nixSpecFile), 'w') as sf:
    json.dump(spec.nixspec, sf)

if post:
    exec(post)
