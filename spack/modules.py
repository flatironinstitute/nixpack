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

print("specs")
specs = [nixpack.NixSpec(p['prefix'], p, concrete=True) for p in pkgs]
print("writers")
writers = [cls(s, name) for s in specs]

print("index")
spack.modules.common.generate_module_index(root, writers)
for x in writers:
    print(x.layout.filename)
    x.write()
