#!/bin/env python3
import os
import json

import nixpack
import spack

root = nixpack.getVar('out')
name = nixpack.getVar('name')
modtype = nixpack.getVar('modtype')

coreCompilers = [nixpack.NixSpec.get(p, top=False) for p in nixpack.getJson('coreCompilers')]
coreCompilers.append(nixpack.nullCompilerSpec)

modconf = nixpack.getJson('config')
modconf.setdefault('core_compilers', [])
modconf['core_compilers'].extend(str(comp.as_compiler) for comp in coreCompilers)
config = { name : {
        'enable': [modtype],
        'roots': { modtype: root },
        modtype: modconf
    } }
print(config)
spack.config.set(f'modules', config, 'command_line')

specs = [nixpack.NixSpec.get(p) for p in nixpack.getJson('pkgs')]
cls = spack.modules.module_types[modtype]
writers = []
for spec in specs:
    # do this as a second pass to avoid premature compiler caching
    spec.concretize()
    writers.append(cls(spec, name))

print(f"Generating {len(writers)} {modtype} modules in {root}...")
spack.modules.common.generate_module_index(root, writers)
paths = set()
for w in writers:
    sn = w.spec.cformat(spack.spec.default_format + ' {/hash}')
    fn = w.layout.filename
    print(f"    {os.path.relpath(fn, root)}: {sn} {w.spec.prefix}")
    assert fn not in paths, f"Duplicate path: {fn}"
    w.write()
    paths.add(fn)

static = nixpack.getJson('static')
if static:
    print(f"Adding {len(static)} static modules...")
    writer = cls(nixpack.nullCompilerSpec, name)
    layout = writer.layout
    env = spack.tengine.make_environment()
    template = env.get_template(writer.default_template)
    for name, content in static.items():
        base, name = os.path.split(name)
        if not base: base = 'Core'
        fn = os.path.join(layout.arch_dirname, base, name) + "." + layout.extension
        print(f"    {os.path.relpath(fn, root)}")
        assert fn not in paths, f"Duplicate path: {fn}"
        os.makedirs(os.path.dirname(fn), exist_ok=True)
        if isinstance(content, dict):
            content.setdefault('spec', content)
            content['spec'].setdefault('target', nixpack.basetarget)
            content['spec'].setdefault('name', name)
            content = template.render(content)
        with open(fn, 'x') as f:
            f.write(content)
        paths.add(fn)
