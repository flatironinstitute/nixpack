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
    def paren(self, obj, indent, out):
        prec = obj.prec if isinstance(obj, Nix) else 0
        parens = prec >= self.prec
        if parens:
            out.write('(')
        printNix(obj, indent, out)
        if parens:
            out.write(')')

class Var(Nix, str):
    def print(self, indent, out):
        out.write(self)

class List(Nix):
    prec = 15
    def __init__(self, items):
        self.items = items
    def print(self, indent, out):
        out.write('[')
        first = True
        for x in self.items:
            if first:
                first = False
            else:
                out.write(' ')
            self.paren(x, indent, out)
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
    prec = 15 # not actually listed?
    def __init__(self, var: str, expr):
        self.var = var
        self.expr = expr
    def print(self, indent, out):
        out.write(self.var)
        out.write(': ')
        self.paren(self.expr, indent, out)

class App(Nix):
    prec = 2
    def __init__(self, fun, arg):
        self.fun = fun
        self.arg = arg
    def print(self, indent, out):
        self.paren(self.fun, indent, out)
        out.write(' ')
        self.paren(self.arg, indent, out)

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
    elif isinstance(x, numbers.Real):
        out.write(repr(x))
    elif isinstance(x, (list, tuple)):
        List(x).print(indent, out)
    elif isinstance(x, dict):
        Attrs(x).print(indent, out)
    else:
        raise TypeError(x)


def variant(v):
    d = v.default
    if v.multi:
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

def depend(d):
    # FIXME
    return {str(w): specPrefs(s.spec) for w, s in d.items()}

print("{ spackPackage, ... } @ packs:")
packs = dict()
for p in spack.repo.path.all_packages():
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
    if p.name.startswith('b'): break
printNix(packs)
