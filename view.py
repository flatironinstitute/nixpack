#!/bin/env python3

import os
import sys
import stat
import errno

srcPaths = os.environ['src'].split()
dstPath = os.environ['out']
shBang = not not os.environ['shbang']
ignorePaths = set(os.environ['ignore'].split())

class Path:
    def __init__(self, dir, ent='', mkdir=False):
        self.dir = dir
        self.ent = ent
        if isinstance(dir, Path):
            path = dir.path
            self.relpath = os.path.join(dir.relpath, self.sub)
        else:
            path = dir
            self.relpath = self.sub
        self.path = os.path.join(path, self.sub)
        self.fd = None

        if mkdir:
            self.mkdir()

    def __str__(self):
        return self.path

    @property
    def root(self):
        if isinstance(self.dir, Path):
            return self.dir.root
        return self.dir

    @property
    def dirfd(self):
        if isinstance(self.dir, Path):
            return self.dir.fd
        return None

    @property
    def sub(self):
        if isinstance(self.ent, os.DirEntry):
            return self.ent.name
        return self.ent

    def dirop(self, fun, *args, **kwargs):
        if self.dirfd is not None:
            return fun(self.sub, *args, dir_fd=self.dirfd, **kwargs)
        else:
            return fun(self.path, *args, **kwargs)

    def ignore(self):
        return self.relpath in ignorePaths

    def stat(self, follow=False):
        try:
            if isinstance(self.ent, os.DirEntry):
                return self.ent.stat(follow_symlinks=follow)
            else:
                return self.dirop(os.stat, follow_symlinks=follow)
        except OSError as e:
            if e.errno == errno.ENOENT:
                return None
            raise

    def readlink(self):
        return self.dirop(os.readlink)

    def symlink(self, target):
        if isinstance(target, Path):
            target = target.path
        if self.dirfd is not None:
            return os.symlink(target, self.sub, dir_fd=self.dirfd)
        else:
            return os.symlink(target, self.path)

    # dir ops
    def mkdir(self):
        try:
            self.dirop(os.mkdir)
            return True
        except OSError as e:
            if e.errno == errno.EEXIST:
                return False
            raise

    def __enter__(self):
        self.fd = self.dirop(os.open, os.O_RDONLY|os.O_DIRECTORY|os.O_NOFOLLOW)
        return self

    def __exit__(self, *args):
        os.close(self.fd)
        self.fd = None

    def scandir(self):
        if self.fd is not None:
            try:
                return os.scandir(self.fd)
            except TypeError:
                pass
        return os.scandir(self.path)

def isdir(s):
    return stat.S_ISDIR(s.st_mode)

def islnk(s):
    return stat.S_ISLNK(s.st_mode)

def newpath(path):
    if not os.path.isabs(path):
        return path
    for sp in srcPaths:
        if os.path.startswith(sp):
            return os.path.join(dstPath, os.path.relpath(path, sp))

def linkdir(sdir, ddir):
    for scanent in sdir.scandir():
        sent = Path(sdir, scanent)
        if sent.ignore():
            continue
        dent = Path(ddir, scanent.name)
        sstat = sent.stat()
        if isdir(sstat):
            dent.mkdir()
            with sent, dent:
                linkdir(sent, dent)
        elif islnk(sstat):
            targ = sent.readlink()
            dent.symlink(newpath(targ))
        else:
            dent.symlink(sent)

with Path(dstPath, mkdir=True) as ddir:
    for src in srcPaths:
        with Path(src) as sdir:
            linkdir(sdir, ddir)
