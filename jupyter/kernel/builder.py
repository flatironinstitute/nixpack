#!/bin/env python3
import os
import json
import glob

kdir = os.path.join('share', 'jupyter', 'kernels')
kspec = 'kernel.json'
dstdir = os.path.join(os.environ['out'], kdir)
srcdir = os.path.join(os.environ['kernelSrc'], kdir)
pkg = os.environ['pkg']
include = os.environ['include'].split()
pfx = os.environ['prefix']
note = os.environ['note']
envupd = json.loads(os.environ['env'])

path = []
pbin = os.path.join(pkg, 'bin')
if os.path.isdir(pbin):
    path.append(pbin)
pyth = []
for p in include:
    pbin = os.path.join(p, 'bin')
    if os.path.isdir(pbin):
        path.append(pbin)
    pyth.extend(glob.glob(os.path.join(p, 'lib', 'python*', 'site-packages')))
path.append('/usr/bin')

baseenv = {
    'PATH': ':'.join(path),
    'PYTHONHOME': pkg,
    'PYTHONNOUSERSITE': None,
    'PYTHONPATH': ':'.join(pyth)
}

baseenv.update(envupd)

os.makedirs(dstdir)

for name in os.listdir(srcdir):
    src = os.path.join(srcdir, name)
    dst = os.path.join(dstdir, f'{pfx}-{name}')
    os.mkdir(dst)
    for p in os.listdir(src):
        if p != kspec:
            os.symlink(os.path.join(src, p), os.path.join(dst, p))
    with open(os.path.join(src, kspec), 'r') as f:
        spec = json.load(f)
    newbin = os.path.join(pkg, 'bin', os.path.basename(spec['argv'][0]))
    if os.path.exists(newbin):
        spec['argv'][0] = newbin
    if note:
        spec['display_name'] += ' (' + note + ')'
    env = spec.get('env', {})
    env.update(baseenv)
    spec['env'] = {n: v for n, v in env.items() if v is not None}
    with open(os.path.join(dst, kspec), 'w') as f:
        json.dump(spec, f)
