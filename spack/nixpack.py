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

def linktree(src: str, dst: str):
    os.mkdir(dst)
    for srcentry in os.scandir(src):
        srcname = os.path.join(src, srcentry.name)
        dstname = os.path.join(dst, srcentry.name)
        srcobj = srcname
        if srcentry.is_dir():
            linktree(srcname, dstname)
        else:
            os.symlink(srcname, dstname)

import spack.main # otherwise you get recursive import errors
import spack.vendor.archspec.cpu
import spack.util.spack_yaml as syaml
import spack.llnl.util.tty

from spack.spec import _inject_patches_variant as inject_patches_variant

# monkeypatch store.layout for the few things we need
class NixLayout():
    metadata_dir = '.spack'
    hidden_file_paths = (metadata_dir,)
    hidden_file_regexes = (re.escape(metadata_dir),)
    def metadata_path(self, spec):
        return os.path.join(spec.prefix, self.metadata_dir)
    def build_packages_path(self, spec):
        return os.path.join(self.metadata_path(spec), 'repos')
class NixDatabase():
    root = '/var/empty'
    upstream_dbs = []
class NixStore():
    layout = NixLayout()
    db = NixDatabase()
    # this is used to find bin/sbang:
    unpadded_root = spack.paths.prefix
spack.store.STORE = NixStore()

spack.main.add_command_line_scopes(spack.config.CONFIG, getVar('spackConfig').split())
spack.config.CONFIG.remove_scope('system')
spack.config.CONFIG.remove_scope('user')
spack.config.CONFIG.push_scope(spack.config.InternalConfigScope("nixpack"))

spack.config.set('config:build_stage', [getVar('NIX_BUILD_TOP')], 'nixpack')
enableParallelBuilding = bool(getVar('enableParallelBuilding', True))
cores = 1
if enableParallelBuilding:
    cores = int(getVar('NIX_BUILD_CORES', 0))
if cores > 0:
    spack.config.set('config:build_jobs', cores, 'nixpack')

spack.paths.set_working_dir()
# add in dynamic overlay repos
repos = getVar('repos', '').split()

repoArgs = {}
if hasattr(spack.repo, "from_path"):
    repoArgs['cache'] = spack.caches.MISC_CACHE

def linkPkg(repo: spack.repo.Repo, path: str, name: str):
    try:
        os.symlink(path, repo.dirname_for_package_name(name))
        # clear cache:
        repo._fast_package_checker = None
    except FileExistsError:
        # just trust that it should be identical
        pass

repodir = os.path.join(os.environ['TMPDIR'], 'repos', 'spack_repo')
os.makedirs(repodir)

dynRepos = {}

def prepRepo(a: str):
    with open(os.path.join(a, spack.repo.repo_config_name), encoding="utf-8") as f:
        n = syaml.load(f)["repo"]["namespace"]
    d = os.path.join(repodir, n)
    if os.path.isdir(os.path.join(a, "packages")):
        # whole repo, symlink whole as-is
        os.symlink(a, d)
        dyn = False
    else:
        # skeleton repo, symlink files
        os.mkdir(d)
        for f in os.listdir(a):
            os.symlink(os.path.join(a, f), os.path.join(d, f))
        os.mkdir(os.path.join(d, "packages"))
        dyn = True
    r = spack.repo.Repo(d, **repoArgs)
    if dyn:
        dynRepos[n] = r
    return r

spack.repo.PATH = spack.repo.RepoPath(*map(prepRepo, repos))

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
        try:
            self.set_prefix(prefix)
        except AttributeError:
            self.prefix = prefix
        self.external_path = nixspec['extern']
        if self.namespace in dynRepos:
            linkPkg(dynRepos[self.namespace], nixspec['package'], self.name)
        if top:
            self._top = True
        elif self.external_path:
            assert self.external_path == prefix, f"{self.name} extern {nixspec['extern']} doesn't match prefix {prefix}"
        else:
            # add any dynamic packages
            repodir = os.path.join(prefix, '.spack', 'repos', 'spack_repo')
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
                    linkPkg(repo, os.path.join(pkgdir, p), p)

        depends = nixspec['depends'].copy()

        for n, d in sorted(depends.items()):
            dtype = nixspec['deptypes'].get(n) or ()
            try:
                dtype = spack.deptypes.canonicalize(dtype)
            except AttributeError:
                dtype = spack.dependency.canonical_deptype(dtype)
            if d:
                dep = self.get(d, top=False)
                cdep = None # any current dep on this package
                if hasattr(self, 'add_dependency_edge'):
                    try:
                        cdeps = self._dependencies.select(child=dep.name, depflag=dtype)
                    except TypeError:
                        cdeps = self._dependencies.select(child=dep.name, deptypes=dtype)
                    if len(cdeps) == 1:
                        # if multiple somehow, _add_dependency should catch it
                        cdep = cdeps[0]
                else:
                    cdep = self._dependencies.get(dep.name)
                if n != dep.name:
                    virtuals = (n,)
                else:
                    virtuals = ()
                if cdep:
                    assert cdep.spec == dep, f"{self.name}.{n}: conflicting dependencies on {dep.name}"
                    cdep.update_deptypes(dtype)
                    cdep.update_virtuals(virtuals)
                else:
                    try:
                        self._add_dependency(dep, depflag=dtype, virtuals=virtuals)
                    except TypeError:
                        self._add_dependency(dep, deptypes=dtype, virtuals=virtuals)
            try:
                lrdep = dtype & (spack.deptypes.LINK | spack.deptypes.RUN)
            except AttributeError:
                lrdep = 'link' in dtype or 'run' in dtype
            if not lrdep and n != "c":
                # trim build dep references (except compiler used in lmod hierachy)
                del nixspec['depends'][n]

        variants = nixspec['variants']
        if not self.external:
            package_class = spack.repo.PATH.get_pkg_class(self.fullname)
            if hasattr(package_class, "variant_names"):
                pkgVariants = set(package_class.variant_names())
            else:
                pkgVariants = package_class.variant.keys()
            assert variants.keys() == pkgVariants, f"{self.name} has mismatching variants {variants.keys()} vs. {pkgVariants}"
        for n, s in variants.items():
            if s is None:
                continue
            if isinstance(s, bool):
                v = spack.variant.BoolValuedVariant(n, s)
            elif isinstance(s, list):
                v = spack.variant.MultiValuedVariant(n, s)
            elif isinstance(s, dict):
                v = spack.variant.MultiValuedVariant(n, [k for k,v in s.items() if v])
            else:
                v = spack.variant.SingleValuedVariant(n, s)
            self.variants[n] = v
        for f in self.compiler_flags.valid_compiler_flags():
            self.compiler_flags[f] = []
        for n, s in nixspec['flags'].items():
            assert n in self.compiler_flags and type(s) is list, f"{self.name} has invalid compiler flag {n}"
            self.compiler_flags[n] = s
        self.tests = nixspec['tests']
        self.extra_attributes.update(nixspec['extraAttributes'])
        if self.external:
            # not really unique but shouldn't matter
            self._hash = spack.util.hash.b32_hash(self.external_path)
        else:
            self._nix_hash, nixname = key.split('-', 1)

        if top and not self.external and nixspec['patches']:
            patches = package_class.patches.setdefault(spack.spec.Spec(), [])
            for i, p in enumerate(nixspec['patches']):
                patches.append(spack.patch.FilePatch(package_class, p, 1, '.', ordering_key = ('~nixpack', i)))
            spack.repo.PATH.patch_index.update_package(self.fullname)

    def concretize(self):
        if self._concrete:
            return
        inject_patches_variant(self)
        self._mark_concrete()

    def copy(self, deps=True, **kwargs):
        # no!
        return self

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
