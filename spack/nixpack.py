import os
import sys
import json
import base64

# translate from nix to spack because...
b32trans = bytes.maketrans(b"0123456789abcdfghijklmnpqrsvwxyz", base64._b32alphabet.lower())

getVar = os.environ.pop

passAsFile = set(getVar('passAsFile', '').split())

def getJson(var: str):
    if var in passAsFile:
        with open(getVar(var+'Path'), 'r') as f:
            return json.load(f)
    else:
        return json.loads(getVar(var))

if not sys.executable: # why not?
    sys.executable = getVar('builder')

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
    # this is used to find bin/sbang:
    unpadded_root = spack.paths.prefix
spack.store.store = NixStore()

spack.config.command_line_scopes = getVar('spackConfig').split()
cache = getVar('spackCache', None)
if cache:
    spack.config.set('config:misc_cache', cache, 'command_line')

spack.config.set('config:build_stage', [getVar('NIX_BUILD_TOP')], 'command_line')
cores = int(getVar('NIX_BUILD_CORES', 0))
if cores > 0:
    spack.config.set('config:build_jobs', cores, 'command_line')

nixLogFd = int(getVar('NIX_LOG_FD', -1))
nixLogFile = None
if nixLogFd >= 0:
    nixLogFile = os.fdopen(nixLogFd, 'w')

def nixLog(j):
    if nixLogFile:
        print("@nix", json.dumps(j), file=nixLogFile)

nixStore = getVar('NIX_STORE')

system = getVar('system')
basetarget, baseplatform = system.split('-', 1)
target = getVar('target')
platform = getVar('platform')
archos = getVar('os')

nullCompiler = None

class NixSpec(spack.spec.Spec):
    # to re-use identical specs so id is reasonable
    specCache = dict()
    nixSpecFile = '.nixpack.spec';
    compilers = dict()

    @staticmethod
    def cacheKey(nixspec, prefix: str):
        if isinstance(prefix, str) and prefix.startswith(nixStore):
            # in nix store
            return prefix[len(nixStore):].lstrip('/')
        else:
            # extern: name + prefix should be enough
            return nixspec['name'] + "-" + nixspec['version'] + ":" + prefix

    @classmethod
    def get(self, arg, prefix: str=None, top: bool=True):
        if isinstance(arg, str):
            # path to existing nix store (containing nixSpecFile)
            nixspec = os.path.join(arg, self.nixSpecFile)
            if prefix is None:
                prefix = arg
        else:
            if 'spec' in arg:
                # inline dependency spec, containing spec and out
                nixspec = arg['spec']
                if prefix is None:
                    prefix = arg.get('out')
            else:
                # actual spec object
                nixspec = arg
            if prefix is None:
                prefix = nixspec['prefix']

        try:
            return self.specCache[self.cacheKey(nixspec, prefix)]
        except KeyError:
            if isinstance(nixspec, str):
                with open(nixspec, 'r') as sf:
                    nixspec = json.load(sf)
            return NixSpec(nixspec, prefix, top)

    def __init__(self, nixspec, prefix: str, top: bool):
        key = self.cacheKey(nixspec, prefix)
        self.specCache[key] = self

        super().__init__()
        self.nixspec = nixspec
        self.name = nixspec['name']
        self.namespace = nixspec['namespace']
        version = nixspec['version']
        self.versions = spack.version.VersionList([spack.version.Version(version)])
        self._set_architecture(target=target, platform=platform, os=archos)
        self.prefix = prefix
        self.external_path = nixspec['extern']
        if self.external_path:
            assert self.external_path == prefix, f"{self.name} extern {nixspec['extern']} doesn't match prefix {prefix}"
        if top:
            self._top = True

        variants = nixspec['variants']
        if not self.external:
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
        if self.external:
            # not really unique but shouldn't matter
            self._hash = spack.util.hash.b32_hash(self.external_path)
        else:
            self._nix_hash, nixname = key.split('-', 1)

        depends = nixspec['depends'].copy()
        compiler = depends.pop('compiler', None)
        self.compiler = self.get(compiler, top=False).as_compiler if compiler else nullCompiler

        for n, d in depends.items():
            dtype = nixspec['deptypes'][n] or ()
            if d:
                dep = self.get(d, top=False)
                try:
                    assert self._dependencies[dep.name].spec == dep, f"{self.name}.{n}: conflicting dependencies on {dep.name}"
                    self._dependencies[dep.name].update_deptypes(tuple(dtype))
                except KeyError:
                    self._add_dependency(dep, tuple(dtype))
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

    def concretize(self):
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
            if name not in self.compilers:
                # we may have duplicate specs, but we only keep the first (topmost)
                # as there is no way to have two compilers with the same spec
                # (and adding something to version messes up modules)
                self.compilers[name] = {'compiler': {
                        'spec': name,
                        'paths': self.paths,
                        'modules': [],
                        'operating_system': self.architecture.os,
                        'target': basetarget,
                    }}
                spack.config.set('compilers', list(self.compilers.values()), 'command_line')
            return self._as_compiler

    def dag_hash(self, length=None):
        try:
            return self._nix_hash[:length]
        except AttributeError:
            return super().dag_hash(length)

    def dag_hash_bit_prefix(self, bits):
        try:
            # nix and python use different base32 alphabets...
            h = self._nix_hash.translate(b32trans)
        except AttributeError:
            h = super().dag_hash()
        return spack.util.hash.base32_prefix_bits(h, bits)

    def _installed_explicitly(self):
        return getattr(self, '_top', False)

nullCompilerSpec = NixSpec({
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
    }, '/null-compiler', top=False)
nullCompiler = nullCompilerSpec.as_compiler
