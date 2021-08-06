import os
import sys

if not sys.executable: # why not?
    sys.executable = os.environ.pop('builder')

os.W_OK = 0 # hack hackity to disable writability checks (mainly for cache)

import spack.main # otherwise you get recursive import errors

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
    import json
    nixLogFile = os.fdopen(nixLogFd, 'w')

def nixLog(j):
    if nixLogFile:
        print("@nix", json.dumps(j), file=nixLogFile)

nixStore = os.environ.pop('NIX_STORE')

system = os.environ.pop('system')
target = os.environ.pop('target')
platform = os.environ.pop('platform')
archos = os.environ.pop('os')

nullCompiler = spack.spec.CompilerSpec('gcc', '0')

class NixSpec(spack.spec.Spec):
    # to re-use identical specs so id is reasonable
    specCache = dict()
    nixSpecFile = '.nixpack.spec';

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

    def __init__(self, ref, nixspec=None):
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

        super().__init__()
        self.nixspec = nixspec
        self.name = nixspec['name']
        self.namespace = nixspec['namespace']
        version = nixspec['version']
        self.versions = spack.version.VersionList([spack.version.Version(version)])
        self._set_architecture(target=target, platform=platform, os=archos)
        self._prefix = spack.util.prefix.Prefix(prefix)
        self.external_path = nixspec['extern']

        variants = nixspec['variants']
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
        self.paths = {n: os.path.join(prefix, p) for n, p in nixspec['paths'].items()}
        self.compiler = nullCompiler
        self._as_compiler = None
        # would be nice to use nix hash, but nix and python use different base32 alphabets
        #if not nixspec['extern'] and prefix.startswith(nixStore):
        #    self._hash, nixname = prefix[len(nixStore):].lstrip('/').split('-', 1)

        for n, d in list(nixspec['depends'].items()):
            if not d:
                continue
            spec = self.get(d)
            dtype = nixspec['deptypes'][n]
            if n == 'compiler':
                self.compiler_spec = spec
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

    @property
    def as_compiler(self):
        if not self._as_compiler:
            self._as_compiler = spack.spec.CompilerSpec(self.name, self.versions)
        return self._as_compiler

