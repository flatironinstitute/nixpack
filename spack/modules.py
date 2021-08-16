#!/bin/env python3
import os
import json
import datetime

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

cls = spack.modules.module_types[modtype]

class ModSpec:
    default = False
    static = None

    @classmethod
    @property
    def nullWriter(self):
        try:
            return self._nullWriter
        except AttributeError:
            self._nullWriter = cls(nixpack.nullCompilerSpec, name)
            return self._nullWriter

    @classmethod
    @property
    def template(self):
        try:
            return self._template
        except AttributeError:
            env = spack.tengine.make_environment()
            self._template = env.get_template(self.nullWriter.default_template)

    def __init__(self, p):
        if isinstance(p, dict):
            self.default = p.get('default', False)
            self.static = p.get('static', None)
            if self.static:
                self.name = p['name']
            self.pkg = p.get('pkg', p)
        else:
            self.pkg = p
        if not self.static:
            self.spec = nixpack.NixSpec.get(self.pkg)

    @property
    def writer(self):
        try:
            return self._writer
        except AttributeError:
            self.spec.concretize()
            self._writer = cls(self.spec, name)
            return self._writer

    @property
    def filename(self):
        if self.static:
            layout = self.nullWriter.layout
            base, name = os.path.split(self.name)
            return os.path.join(layout.arch_dirname, base or 'Core', name) + "." + layout.extension
        else:
            return self.writer.layout.filename

    def format(self):
        if self.static:
            return self.name
        else:
            return self.spec.cformat(spack.spec.default_format + ' {/hash} {prefix}')

    def write(self, fn):
        dn = os.path.dirname(fn)
        if self.static:
            os.makedirs(dn, exist_ok=True)
            content = self.static
            if isinstance(content, dict):
                content.setdefault('spec', content)
                content['spec'].setdefault('target', nixpack.basetarget)
                content['spec'].setdefault('name', name)
                content['spec'].setdefault('short_spec', 'static module via nixpack')
                content.setdefault('timestamp', datetime.datetime.now())
                content = self.template.render(content)
            with open(fn, 'x') as f:
                f.write(content)
        else:
            self.writer.write()
        if self.default:
            bn = os.path.basename(fn)
            os.symlink(bn, os.path.join(dn, "default"))

specs = [ModSpec(p) for p in nixpack.getJson('pkgs')]

print(f"Generating {len(specs)} {modtype} modules in {root}...")
paths = set()
for s in specs:
    sn = w.spec.cformat(spack.spec.default_format + ' {/hash}')
    fn = s.filename
    print(f"    {os.path.relpath(fn, root)}: {s.format}")
    assert fn not in paths, f"Duplicate path: {fn}"
    s.write(fn)
    paths.add(fn)
