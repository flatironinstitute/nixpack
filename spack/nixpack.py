import os
import sys
import json

if not sys.executable: # why not?
    sys.executable = os.environ.pop('builder')

os.W_OK = 0 # hack hackity to disable writability checks (mainly for cache)

import spack.main # otherwise you get recursive import errors

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

spack.config.command_line_scopes = os.environ.pop('spackConfig').split()
cache = os.environ.pop('spackCache', None)
if cache:
    spack.config.set('config:misc_cache', cache, 'command_line')

spack.config.set('config:build_stage', [os.environ.pop('NIX_BUILD_TOP')], 'command_line')
cores = int(os.environ.pop('NIX_BUILD_CORES', 0))
if cores > 0:
    spack.config.set('config:build_jobs', cores, 'command_line')

nixLogFd = int(os.environ.pop('NIX_LOG_FD', -1))
nixLogFile = None
if nixLogFd >= 0:
    nixLogFile = os.fdopen(nixLogFd, 'w')

def nixLog(j):
    if nixLogFile:
        print("@nix", json.dumps(j), file=nixLogFile)

nixStore = os.environ.pop('NIX_STORE')

system = os.environ.pop('system')
target = os.environ.pop('target')
platform = os.environ.pop('platform')
archos = os.environ.pop('os')

nullCompiler = None

class NixSpec(spack.spec.Spec):
    # to re-use identical specs so id is reasonable
    specCache = dict()
    nixSpecFile = '.nixpack.spec';
    compilers = dict()

    @staticmethod
    def cacheKey(d):
        if isinstance(d, str):
            # in nix store
            return d
        else:
            # extern: name + prefix should be enough
            return f"{d['name']}:{d['out']}"

    def get(self, ref):
        try:
            return self.specCache[self.cacheKey(ref)]
        except KeyError:
            return NixSpec(ref)

    def __init__(self, ref, nixspec=None, concrete=False):
        self.specCache[self.cacheKey(ref)] = self

        if isinstance(ref, str):
            prefix = ref
            if nixspec is None:
                nixspec = os.path.join(prefix, self.nixSpecFile)
        else:
            prefix = ref['out']
            if nixspec is None:
                nixspec = ref['spec']
        if isinstance(nixspec, str):
            with open(nixspec, 'r') as sf:
                nixspec = json.load(sf)
        else:
            self._top = True

        super().__init__()
        self.nixspec = nixspec
        self.name = nixspec['name']
        self.namespace = nixspec['namespace']
        version = nixspec['version']
        self.versions = spack.version.VersionList([spack.version.Version(version)])
        self._set_architecture(target=target, platform=platform, os=archos)
        self.prefix = prefix
        extern = nixspec['extern']
        if extern:
            assert extern == prefix, f"{self.name} extern {extern} doesn't match prefix {prefix}"

        variants = nixspec['variants']
        if not extern:
            assert variants.keys() == self.package.variants.keys(), f"{self.name} has mismatching variants {variants.keys()} vs. {self.packages.variants.keys()}"
        for n, s in variants.items():
            if isinstance(s, bool):
                v = spack.variant.BoolValuedVariant(n, s)
            elif isinstance(s, list):
                v = spack.variant.MultiValuedVariant(n, s)
            elif isinstance(s, dict):
                v = spack.variant.MultiValuedVariant(n, [k for k,v in s.items() if v])
            else:
                v = spack.variant.SingleValuedVariant(n, s)
            self.variants[n] = v
        self.tests = nixspec['tests']
        self.paths = {n: p and os.path.join(prefix, p) for n, p in nixspec['paths'].items()}
        self.compiler = nullCompiler
        if not nixspec['extern'] and prefix.startswith(nixStore):
            self._nix_hash, nixname = prefix[len(nixStore):].lstrip('/').split('-', 1)

        for n, d in list(nixspec['depends'].items()):
            if not d:
                continue
            spec = self.get(d)
            dtype = nixspec['deptypes'][n]
            if n == 'compiler':
                self.compiler = spec.as_compiler
            else:
                self._add_dependency(spec, tuple(dtype))
                if not ('link' in dtype or 'run' in dtype):
                    # trim build dep references
                    del nixspec['depends'][n]

        for f in self.compiler_flags.valid_compiler_flags():
            self.compiler_flags[f] = []

        if nixspec['patches']:
            patches = self.package.patches.setdefault(spack.directives.make_when_spec(True), [])
            for i, p in enumerate(nixspec['patches']):
                patches.append(spack.patch.FilePatch(self.package, p, 1, '.', ordering_key = ('~nixpack', i)))
            spack.repo.path.patch_index.update_package(self.fullname)

        if concrete:
            conc = spack.concretize.Concretizer()
            conc.adjust_target(self)
            spack.spec.Spec.inject_patches_variant(self)
            self._mark_concrete()

    def copy(self, deps=True, **kwargs):
        # no!
        return self

    @property
    def as_compiler(self):
        try:
            return self._as_compiler
        except AttributeError:
            self._as_compiler = spack.spec.CompilerSpec(self.name, self.versions)
            name = str(self._as_compiler)
            assert name not in self.compilers
            self.compilers[name] = {'compiler': {
                    'spec': name,
                    'paths': self.paths,
                    'modules': [],
                    'operating_system': self.architecture.os,
                    'target': system.split('-', 1)[0],
                }}
            spack.config.set('compilers', list(self.compilers.values()), 'command_line')
            return self._as_compiler

    def dag_hash(self, length=None):
        h = getattr(self, '_nix_hash', None)
        if h:
            return h[:length]
        return super().dag_hash(length)

    def dag_hash_bit_prefix(self, bits):
        # nix and python use different base32 alphabets, so bypass nix for this one
        return spack.util.hash.base32_prefix_bits(super().dag_hash(), bits)

    def _installed_explicitly(self):
        return getattr(self, '_top', False)

nullCompiler = NixSpec('/null-compiler', {
        'name': 'gcc',
        'namespace': 'builtin',
        'version': '0',
        'extern': '/null-compiler',
        'variants': {},
        'tests': False,
        'paths': {
            'cc': None,
            'cxx': None,
            'f77': None,
            'fc': None,
        },
        'depends': {},
        'patches': []
    }).as_compiler
