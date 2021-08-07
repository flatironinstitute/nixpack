#!/bin/env python3
import os
import json

import nixpack
import spack

root = os.environ['out']
name = os.environ['name']
modtype = os.environ['modtype']

with open(os.environ['configPath'], 'r') as cf:
    modconf = json.load(cf)
config = { name : {
        'enable': [modtype],
        'roots': { modtype: root },
        modtype: modconf
    } }
spack.config.set(f'modules', config, 'command_line')

cls = spack.modules.module_types[modtype]

with open(os.environ['pkgsPath'], 'r') as pf:
    pkgs = json.load(pf)
writers = [cls(nixpack.NixSpec(p['prefix'], p, concrete=True), name) for p in pkgs]

print(f"Generating {len(writers)} {modtype} modules in {root}...")
spack.modules.common.generate_module_index(root, writers)
paths = set()
for w in writers:
    sn = w.spec.cformat(spack.spec.default_format + ' {/hash}')
    fn = w.layout.filename
    print(f"    {os.path.relpath(fn, root)}: {sn}")
    assert fn not in paths, f"Duplicate path: {fn}"
    w.write()
    paths.add(fn)
