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
spack.config.set(f'modules', config, 'command_line')

cls = spack.modules.module_types[modtype]

class FakeSpec(spack.spec.Spec):
    def __init__(self):
        super().__init__()
        self._set_architecture(target=nixpack.target, platform=nixpack.platform, os=nixpack.archos)
        self.name = 'dummy_static_module'
        self.compiler = nixpack.nullCompiler

    def concretize(self):
        self._mark_concrete()

    def _installed_explicitly(self):
        return True

    @property
    def prefix(self):
        # may be None
        return self._prefix
    
    @prefix.setter
    def prefix(self, value):
        self._prefix = spack.util.prefix.Prefix(value)

    def copy(self, deps=True, **kwargs):
        # no!
        return self

class ModSpec:
    default = False
    static = None

    nullWriter = cls(nixpack.nullCompilerSpec, name)
    template = spack.tengine.make_environment().get_template(nullWriter.default_template)

    def __init__(self, p):
        if isinstance(p, str) or 'extern' in p:
            self.pkg = p
            p = {}
        else:
            self.pkg = p.get('pkg', None)
        if self.pkg:
            self.spec = nixpack.NixSpec.get(self.pkg)
        else:
            self.spec = FakeSpec()

        self.default = p.get('default', False)
        self.static = p.get('static', None)
        self.path = p.get('path', None)
        name = p.get('name', None)
        if name:
            if isinstance(name, str):
                self.spec.name = name
            else:
                self.spec.name = name['name']
                self.spec.versions = spack.version.VersionList([spack.version.Version(name['version'])])

        prefix = p.get('prefix', None)
        if prefix:
            self.spec.prefix = prefix
            self.spec.external_path = prefix

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
        layout = self.writer.layout
        if self.path:
            base, name = os.path.split(self.path)
            return os.path.join(layout.arch_dirname, base or 'Core', name) + "." + layout.extension
        else:
            return layout.filename

    def __str__(self):
        return self.spec.cformat(spack.spec.default_format + ' {/hash} {prefix}')

    def write(self, fn):
        dn = os.path.dirname(fn)
        if self.static:
            os.makedirs(dn, exist_ok=True)
            content = self.static
            if isinstance(content, dict):
                content.setdefault('spec', content)
                content['spec'].setdefault('target', nixpack.basetarget)
                content['spec'].setdefault('name', self.spec.name)
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
    fn = s.filename
    print(f"    {os.path.relpath(fn, root)}: {s}")
    assert fn not in paths, f"Duplicate path: {fn}"
    s.write(fn)
    paths.add(fn)
