import os
import sys
import json
import base64
import re

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

def linktree(src, dst):
    os.mkdir(dst)
    for srcentry in os.scandir(src):
        srcname = os.path.join(src, srcentry.name)
        dstname = os.path.join(dst, srcentry.name)
        srcobj = srcname
        if srcentry.is_dir():
            linktree(srcname, dstname)
        else:
            os.symlink(srcname, dstname)

os.W_OK = 0 # hack hackity to disable writability checks (mainly for cache)

import spack.main # otherwise you get recursive import errors
import archspec.cpu
import llnl.util.tty

# spack backwards compatibility
try:
    import spack.target
except ImportError:
    spack.target = spack.architecture

# monkeypatch store.layout for the few things we need
class NixLayout():
    metadata_dir = '.spack'
    hidden_file_paths = (metadata_dir,)
    hidden_file_regexes = (re.escape(metadata_dir),)
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
spack.config.config.remove_scope('system')
spack.config.config.remove_scope('user')

spack.config.set('config:build_stage', [getVar('NIX_BUILD_TOP')], 'command_line')
cores = int(getVar('NIX_BUILD_CORES', 0))
if cores > 0:
    spack.config.set('config:build_jobs', cores, 'command_line')

# add in dynamic overlay repos
repos = getVar('repos', '').split()
dynRepos = {}
for i, r in enumerate(repos):
    if os.path.isfile(r):
        d = os.path.join(os.environ['TMPDIR'], 'repos', str(i))
        pd = os.path.join(d, 'packages')
        os.makedirs(pd)
        os.symlink(r, os.path.join(d, 'repo.yaml'))
        repo = spack.repo.Repo(d)
        repos[i] = repo
        dynRepos[repo.namespace] = repo
repoPath = spack.repo.RepoPath(*repos)
spack.repo.path.put_first(repoPath)

cache = getVar('spackCache', None)
if cache:
    if dynRepos:
        # copy repo cache so we can add more to it
        tmpcache = os.path.join(os.environ['TMPDIR'], 'spack-cache')
        linktree(cache, tmpcache)
        cache = tmpcache
    spack.config.set('config:misc_cache', cache, 'command_line')

nixLogFd = int(getVar('NIX_LOG_FD', -1))
nixLogFile = None
if nixLogFd >= 0:
    nixLogFile = os.fdopen(nixLogFd, 'w')

def nixLog(j):
    if nixLogFile:
        print("@nix", json.dumps(j), file=nixLogFile)

nixStore = getVar('NIX_STORE')

system = getVar('system')
basetarget, platform = system.split('-', 1)
archos = getVar('os')

nullCompiler = None
compilerNameMap = {
        'llvm': 'clang',
        'intel-oneapi-compilers': 'oneapi'
    }

class CompilerEnvironment(spack.util.environment.EnvironmentModifications):
    _path_keys = {'CC', 'CXX', 'F77', 'FC'}
    _class_keys = {
        spack.util.environment.SetEnv: 'set',
        spack.util.environment.PushEnv: 'push',
        spack.util.environment.UnsetEnv: 'unset',
        spack.util.environment.PrependPath: 'prepend_path',
        spack.util.environment.AppendPath: 'append_path',
        spack.util.environment.RemovePath: 'remove_path',
    }

    def config(self):
        """
        Try to convert the set of environment modifications to json configuration.
        This is not at all perfect, and in particular loses order, but should
        be good enough for most compilers.
        """
        paths = {k.lower(): None for k in self._path_keys}
        environment = {}
        import spack.util.environment as env
        for m in self:
            try:
                t = self._class_keys[type(m)]
            except KeyError:
                continue
            if m.name in self._path_keys:
                paths[m.name.lower()] = str(m.value) if t == 'set' else None
            elif t == 'unset':
                environment.setdefault(t, []).append(m.name)
            elif t == 'remove_path':
                # will loose multiples (but largely unused)
                environment.setdefault(t, {})[m.name] = str(m.value)
            else:
                m.execute(environment.setdefault(t, {}))
        return {'paths': paths, 'environment': environment}

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
        self._set_architecture(target=nixspec.get('target', basetarget), platform=platform, os=archos)
        self.prefix = prefix
        self.external_path = nixspec['extern']
        if self.external_path:
            assert self.external_path == prefix, f"{self.name} extern {nixspec['extern']} doesn't match prefix {prefix}"
        else:
            # add any dynamic packages
            repodir = os.path.join(prefix, '.spack', 'repos')
            try:
                rl = os.listdir(repodir)
            except FileNotFoundError:
                rl = []
            for r in rl:
                try:
                    repo = dynRepos[r]
                except KeyError:
                    continue
                pkgdir = os.path.join(repodir, r, 'packages')
                for p in os.listdir(pkgdir):
                    try:
                        os.symlink(os.path.join(pkgdir, p), repo.dirname_for_package_name(p))
                    except FileExistsError:
                        # just trust that it should be identical
                        pass
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
            dtype = nixspec['deptypes'].get(n) or ()
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

    def supports_target(self, target):
        try:
            target.optimization_flags(self.compiler)
            return True
        except archspec.cpu.UnsupportedMicroarchitecture:
            return False

    def adjust_target(self):
        """replicate spack.concretize.Concretizer.adjust_target (which has too many limitations)"""
        target = self.architecture.target
        if self.supports_target(target):
            return
        for ancestor in target.microarchitecture.ancestors:
            candidate = spack.target.Target(ancestor)
            if self.supports_target(candidate):
                print(f"Downgrading target {target} -> {candidate} for {self.compiler}")
                self.architecture.target = candidate
                self.nixspec['target'] = str(candidate)
                return

    def concretize(self):
        if self._concrete:
            return
        if self.compiler:
            self.adjust_target()
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
            pass
        name = compilerNameMap.get(self.name, self.name)
        self._as_compiler = spack.spec.CompilerSpec(name, self.versions)
        name = str(self._as_compiler)
        if name not in self.compilers:
            # we may have duplicate specs, but we only keep the first (topmost)
            # as there is no way to have two compilers with the same spec
            # (and adding something to version messes up modules)
            config = {
                    'spec': name,
                    'modules': [],
                    'operating_system': self.architecture.os,
                    'target': basetarget,
                }
            env = CompilerEnvironment()
            self.concretize()
            self.package.setup_run_environment(env)
            config.update(env.config())
            config['paths'].update(self.paths)
            self.compilers[name] = {'compiler': config}
            spack.config.set('compilers', list(self.compilers.values()), 'command_line')
            # clear compilers cache since we changed config:
            spack.compilers._cache_config_file = None
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
