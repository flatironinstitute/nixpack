#!/bin/env python3
from typing import TYPE_CHECKING, Union, Optional, Type, List, Any
if not TYPE_CHECKING:
    # hack for __future__.annotatinons (python<3.7)
    Path = Any
    Inode = Any

import os
import sys
import stat
import errno
import fnmatch

srcPaths = os.environb[b'src'].split()
dstPath = os.environb[b'out']

def getOpt(opt: bytes):
    v = os.environb[opt]
    if v == '1':
        return lambda x: True
    l = [ fnmatch._compile_pattern(x) for x in v.split() ]
    return lambda x: any(m(x) is not None for m in l)
opts = {o: getOpt(o) for o in 
        # in order of precedece:
        [ b'ignore' # paths not to link
        , b'shbang' # paths to translate #!
        , b'wrap' # paths to wrap executables
        , b'copy' # paths to copy
        ] }

maxSrcLen = max(len(p) for p in srcPaths)

def isdir(s):
    return stat.S_ISDIR(s.st_mode)

def islnk(s):
    return stat.S_ISLNK(s.st_mode)

class Path:
    def __init__(self, dir: Union[Path, bytes], ent: Union[os.DirEntry,bytes]=b''):
        self.dir = dir
        self.ent = ent
        if isinstance(dir, Path):
            path = dir.path
            self.relpath: bytes = os.path.join(dir.relpath, self.name) if ent else dir.relpath
        else:
            path = dir
            self.relpath = self.name
        self.path: bytes = os.path.join(path, self.name) if ent else path
        self.fd: Optional[int] = None

    def __str__(self) -> str:
        return self.path.decode('ISO-8859-1')

    @property
    def root(self) -> bytes:
        if isinstance(self.dir, Path):
            return self.dir.root
        return self.dir

    @property
    def dirfd(self) -> Optional[int]:
        if isinstance(self.dir, Path):
            return self.dir.fd
        return None

    @property
    def name(self) -> bytes:
        if isinstance(self.ent, os.DirEntry):
            return self.ent.name
        return self.ent

    def sub(self, ent: Union[os.DirEntry,bytes]):
        return Path(self, ent)

    def dirop(self, fun, *args, **kwargs):
        if self.dirfd is not None:
            return fun(self.name, *args, dir_fd=self.dirfd, **kwargs)
        else:
            return fun(self.path, *args, **kwargs)

    def opt(self, opt: bytes) -> bool:
        return opts[opt](self.relpath)

    def _dostat(self):
        if self.fd is not None:
            return os.fstat(self.fd)
        try:
            if isinstance(self.ent, os.DirEntry):
                return self.ent.stat(follow_symlinks=False)
            else:
                return self.dirop(os.lstat)
        except OSError as e:
            if e.errno == errno.ENOENT:
                return None
            raise

    def stat(self):
        try:
            return self._stat
        except AttributeError:
            self._stat = self._dostat()
            return self._stat

    def isdir(self):
        if isinstance(self.ent, os.DirEntry):
            return self.ent.is_dir(follow_symlinks=False)
        else:
            return isdir(self.stat())

    def islnk(self):
        if isinstance(self.ent, os.DirEntry):
            return self.ent.is_symlink()
        else:
            return islnk(self.stat())

    def isexe(self):
        return self.stat().st_mode & 0o111

    def readlink(self):
        return self.dirop(os.readlink)

    def symlink(self, target: Union[bytes,Path]):
        if isinstance(target, Path):
            target = target.path
        if self.dirfd is not None:
            return os.symlink(target, self.name, dir_fd=self.dirfd)
        else:
            return os.symlink(target, self.path)

    def open(self):
        self.mode = os.O_RDONLY|os.O_NOFOLLOW;
        return self

    def opendir(self):
        self.mode = os.O_RDONLY|os.O_NOFOLLOW|os.O_DIRECTORY;
        return self

    def create(self, perm):
        self.mode = os.O_WRONLY|os.O_CREAT|os.O_EXCL|os.O_NOFOLLOW
        if isinstance(perm, Path):
            perm = perm.stat().st_mode
        self.perm = perm
        return self

    def mkdir(self):
        try:
            self.dirop(os.mkdir)
        except OSError as e:
            if e.errno != errno.EEXIST:
                raise
        self.mode = os.O_RDONLY|os.O_NOFOLLOW|os.O_DIRECTORY|os.O_PATH;
        return self

    def __enter__(self):
        self.fd = self.dirop(os.open, self.mode, getattr(self, 'perm', 0o777))
        self.mode = None
        return self

    def __exit__(self, *args):
        os.close(self.fd)
        self.fd = None

    def read(self, len: int):
        assert self.fd is not None
        return os.read(self.fd, len)

    def write(self, data: bytes):
        assert self.fd is not None
        l = 0
        while l < len(data):
            l += os.write(self.fd, data[l:])

    def readInterp(self) -> Optional[bytes]:
        hb = self.read(maxSrcLen+4)
        if hb[0:2] != b'#!':
            return None
        return hb[2:].lstrip()

    def copyfile(self, src):
        z = self.stat().st_size
        while os.sendfile(self.fd, src.fd, None, z) > 0:
            pass

    def _scandir(self):
        if self.fd is not None:
            try:
                return os.scandir(self.fd)
            except TypeError:
                pass
        return os.scandir(self.path)

    def scandir(self):
        return map(self.sub, self._scandir())

def newpath(path):
    if not os.path.isabs(path):
        return path
    for sp in srcPaths:
        if path.startswith(sp):
            return os.path.join(dstPath, os.path.relpath(path, sp))

class Conflict(Exception):
    def __init__(self, path: Path, *nodes: Inode):
        self.path = path.relpath
        self.srcs = [srcPaths[n.src] for n in nodes if n.src is not None]

    def __str__(self):
        return f'Conflict({self.path}, {self.srcs})'

#TODO: walk each instead, looking for things we need to do
class Inode:
    def __init__(self, node: Inode, src: int, path: Path):
        self.src: Optional[int] = src # index into srcPaths
        if node is not None:
            if self != node:
                raise Conflict(path, self, node)
            if self.src != node.src:
                self.src = None # set?

    @property
    def needed(self):
        return self.src == None

    def __eq__(self, other) -> bool:
        return type(self) == type(other)

    def srcpath(self, path: Path) -> Path:
        assert self.src is not None
        return Path(srcPaths[self.src], path.relpath)

    def create(self, dst: Path) -> None:
        dst.symlink(self.srcpath(dst))

class Symlink(Inode):
    def __init__(self, node: Inode, src: int, path: Path):
        targ = path.readlink()
        self.targ = newpath(targ)
        super().__init__(node, src, path)

    @property
    def needed(self):
        # for recursion -- don't bother creating directories just for symlinks
        return False

    def __eq__(self, other) -> bool:
        return super().__eq__(other) and self.targ == other.targ

    def __repr__(self):
        return f'Symlink({self.src}, {self.targ!r})'

    def create(self, dst: Path):
        dst.symlink(self.targ)

class File(Inode):
    shbang = False
    wrap = False
    copy = False

    def __init__(self, node: Inode, src: int, path: Path):
        super().__init__(node, src, path)
        if path.isexe():
            if path.opt(b'shbang'):
                with path.open():
                    interp = path.readInterp()
                    if interp and any(interp.startswith(p) for p in srcPaths):
                        self.shbang = True
                        return
            if path.opt(b'wrap'):
                self.wrap = True
        if path.opt(b'copy'):
            self.copy = True

    @property
    def needed(self):
        return self.shbang or self.wrap or self.copy

    def __eq__(self, other) -> bool:
        return super().__eq__(other) and False

    def __repr__(self):
        return f'File({self.src}{", needed" if self.needed else ""})'

    def create(self, dst: Path):
        src = self.srcpath(dst)
        if self.shbang:
            with src.open():
                interp = src.readInterp()
                assert interp
                new = newpath(interp)
                with dst.create(src):
                    dst.write(b'#!'+new)
                    dst.copyfile(src)
        elif self.wrap:
            with dst.create(src):
                dst.write(b'#!/bin/sh\nexec -a '+dst.path+b' '+src.path+b' "$@"\n')
        elif self.copy:
            with src.open():
                with dst.create(src):
                    dst.copyfile(src)
        else:
            dst.symlink(src)

class Dir(Inode):
    def __init__(self, node: Inode, src: int, path: Path):
        super().__init__(node, src, path)
        self.dir = node.dir if node else dict()
        with path.opendir():
            for ent in path.scandir():
                n = scan(self.dir.get(ent.name), src, ent)
                if n:
                    self.dir[ent.name] = n

    def __repr__(self):
        return f'Dir({self.src}, {self.dir!r})'

    def create(self, dst: Path):
        if self.needed:
            with dst.mkdir():
                for n, f in self.dir.items():
                    f.create(dst.sub(n))
        else:
            super().create(dst)
    
def scan(node, src: int, path: Path):
    if path.opt(b'ignore'):
        return node
    if path.isdir():
        cls: Type[Inode] = Dir
    elif path.islnk():
        cls = Symlink
    else:
        cls = File
    return cls(node, src, path)

top = None
for i, src in enumerate(srcPaths):
    top = scan(top, i, Path(src))

top.create(Path(dstPath))
