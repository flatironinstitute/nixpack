#!/bin/env python3

import os
import sys
import numbers
from pprint import PrettyPrinter

os.environ['PATH'] = '/bin:/usr/bin'
os.W_OK = 0 # hack hackity to disable writability checks (mainly for cache)

import spack.main # because otherwise you get recursive import errors

spack.config.command_line_scopes = [os.environ['spackConfig']]
spack.config.set('config:misc_cache', os.environ['spackCache'], 'command_line')

class Nix:
    prec = 0
    def paren(self, obj, indent, out, nl=False):
        prec = obj.prec if isinstance(obj, Nix) else 0
        parens = prec > self.prec
        if parens:
            if nl:
                out.write('\n' + ' '*indent)
            out.write('(')
        printNix(obj, indent, out)
        if parens:
            out.write(')')

class Var(Nix, str):
    def print(self, indent, out):
        out.write(self)

class List(Nix):
    def __init__(self, items):
        self.items = items
    def print(self, indent, out):
        out.write('[')
        first = True
        indent += 2
        for x in self.items:
            if first:
                first = False
            else:
                out.write(' ')
            self.paren(x, indent, out, True)
        out.write(']')

class Attrs(Nix, dict):
    def print(self, indent, out):
        out.write('{')
        first = True
        pad = ' '*indent
        indent += 2
        for k, v in self.items():
            if first:
                out.write('\n' + pad)
                first = False
            out.write('  ')
            if not isinstance(k, str):
                raise TypeError(k)
            if k.isidentifier():
                out.write(k)
            else:
                printNix(k, indent, out)
            out.write(' = ')
            printNix(v, indent, out)
            out.write(';\n' + pad)
        out.write('}')

class Fun(Nix):
    prec = 16 # not actually listed?
    def __init__(self, var: str, expr):
        self.var = var
        self.expr = expr
    def print(self, indent, out):
        out.write(self.var)
        out.write(': ')
        self.paren(self.expr, indent, out)

class App(Nix):
    prec = 2
    def __init__(self, fun, *args):
        self.fun = fun
        self.args = args
    def print(self, indent, out):
        if isinstance(self.fun, str):
            out.write(self.fun)
        else:
            self.paren(self.fun, indent, out)
        for a in self.args:
            out.write(' ')
            self.paren(a, indent, out)

class And(Nix):
    prec = 12
    def __init__(self, *args):
        self.args = args
    def print(self, indent, out):
        first = True
        for a in self.args:
            if first:
                first = False
            else:
                out.write(' && ')
            self.paren(a, indent, out)

nixStrEsc = str.maketrans({'"': '\\"', '\\': '\\\\', '$': '\\$', '\n': '\\n', '\r': '\\r', '\t': '\\t'})
def printNix(x, indent=0, out=sys.stdout):
    if isinstance(x, Nix):
        x.print(indent, out)
    elif isinstance(x, str):
        out.write('"' + x.translate(nixStrEsc) + '"')
    elif type(x) is bool:
        out.write('true' if x else 'false')
    elif x is None:
        out.write('null')
    elif isinstance(x, int):
        out.write(repr(x))
    elif isinstance(x, float):
        # messy but rare (needed for nix parsing #5063)
        out.write('%.15e'%x)
    elif isinstance(x, (list, tuple)):
        List(x).print(indent, out)
    elif isinstance(x, dict):
        Attrs(x).print(indent, out)
    else:
        raise TypeError(x)


def variant(v):
    d = v.default
    if v.multi and v.values is not None:
        d = d.split(',')
        return {x: x in d for x in v.values}
    elif v.values:
        l = list(v.values)
        try:
            l.remove(d)
            l.insert(0, d)
        except ValueError:
            print(f"Warning: variant {v.name} default {v.default!r} not in {v.values!r}", file=sys.stderr)
        return l
    else:
        return d

def specPrefs(s):
    p = {}
    if s.versions != spack.spec._any_version:
        p['version'] = str(s.versions)
    if s.variants:
        p['variants'] = {n: v.value for n, v in s.variants.items()}
    d = s.dependencies()
    if d:
        p['depends'] = {x.name: specPrefs(x) for x in d}
    return p

def whenCondition(s, a):
    c = []
    if s.versions != spack.spec._any_version:
        c.append(App('args.versionMatches', str(s.versions)))
    if s.variants:
        for n, v in s.variants.items():
            c.append(App('args.variantMatches', n, v.value))
    if s.compiler or s._dependencies or s.architecture or s.compiler_flags:
        # TODO?
        print(f"Warning: unsupported condition spec: {s}", file=sys.stderr)
    if not c:
        return a
    return App('when', And(*c), a)

def depend(d):
    c = [whenCondition(w, specPrefs(s.spec)) for w, s in d.items()]
    if len(c) == 1:
        return c[0]
    return App('intersectPrefsList', List(c))

packs = dict()
for p in spack.repo.path.all_packages():
    print(f"Generating {p.name}...")
    vers = [(i.get('preferred',False), not (v.isdevelop() or i.get('deprecated',False)), v)
            for v, i in p.versions.items()]
    vers.sort(reverse = True)
    version = [str(v) for _, _, v in vers]
    variants = {n: variant(v) for n, v in p.variants.items()}
    depends = {n: depend(d) for n, d in p.dependencies.items()}
    packs[p.name] = App(Var('spackPackage'), Fun('args', {
        'name': p.name,
        'version': version,
        'variants': variants,
        'depends': depends
    }))
with open(os.environ['out'], 'w') as f:
    print("{ spackPackage, when, intersectPrefsList, ... } @ packs:", file=f)
    printNix(packs, out=f)
