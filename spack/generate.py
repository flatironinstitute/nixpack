#!/bin/env python3

import os
import sys
from collections import defaultdict

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

class Expr(Nix, str):
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

class Eq(Nix):
    prec = 11
    def __init__(self, a, b):
        self.a = a
        self.b = b
    def print(self, indent, out):
        self.paren(self.a, indent, out)
        out.write(' == ')
        self.paren(self.b, indent, out)

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
    elif isinstance(x, (list, tuple, set)):
        List(x).print(indent, out)
    elif isinstance(x, dict):
        Attrs(x).print(indent, out)
    else:
        raise TypeError(x)


def variant(p, v):
    d = str(v.default)
    if v.multi and v.values is not None:
        d = d.split(',')
        return {x: x in d for x in v.values}
    elif v.values == (True, False):
        return d.upper() == 'TRUE'
    elif v.values:
        l = list(v.values)
        try:
            l.remove(d)
            l.insert(0, d)
        except ValueError:
            print(f"{p.name}: variant {v.name} default {v.default!r} not in {v.values!r}", file=sys.stderr)
        return l
    else:
        return d

def unlist(l):
    if isinstance(l, (list, tuple)) and len(l) == 1:
        return l[0]
    return l

def specPrefs(s):
    p = {}
    if s.versions != spack.spec._any_version:
        p['version'] = str(s.versions)
    if s.variants:
        p['variants'] = {n: unlist(v.value) for n, v in s.variants.items()}
    d = s.dependencies()
    if d:
        p['depends'] = {x.name: specPrefs(x) for x in d}
    return p

def depPrefs(d):
    p = specPrefs(d.spec)
    p['type'] = d.type
    return p

def conditions(p, s):
    c = []
    def addConditions(a, s):
        if s.versions != spack.spec._any_version:
            c.append(App(a+'.versionMatches', str(s.versions)))
        if s.variants:
            for n, v in s.variants.items():
                c.append(App(a+'.variantMatches', n, unlist(v.value)))
        if s.compiler:
            if s.compiler.name:
                c.append(Eq(Expr(a+'.depends.compiler._name'), s.compiler.name))
            if s.compiler.versions != spack.spec._any_version:
                c.append(App(a+'.depends.compiler.versionMatches', str(s.compiler.versions)))
        for d in s.dependencies():
            addConditions(a+'.depends.'+d.name+'.spec', d)
        if s.architecture:
            if s.architecture.os:
                c.append(Eq(Expr('os'), s.architecture.os))
            if s.architecture.platform:
                c.append(Eq(Expr('platform'), s.architecture.platform))
            if s.architecture.target:
                # this isn't actually correct due to fancy targets but good enough for this
                c.append(Eq(Expr('target'), str(s.architecture.target).rstrip(':')))
    addConditions('spec', s)
    return c

def whenCondition(p, s, a):
    c = conditions(p, s)
    if not c:
        return a
    return App('when', And(*c), a)

def depend(p, d):
    c = [whenCondition(p, w, depPrefs(s)) for w, s in d.items()]
    if len(c) == 1:
        return c[0]
    return App('prefsIntersection', List(c))

def provide(p, wv):
    c = [whenCondition(p, w, str(v)) for w, v in wv]
    if len(c) == 1:
        return c[0]
    return App('versionsUnion', List(c))

packs = dict()
virtuals = defaultdict(set)
namespaces = ' '.join(r.namespace for r in spack.repo.path.repos)
print(f"Generating package repo for {namespaces}...")
for p in spack.repo.path.all_packages():
    desc = dict()
    desc['namespace'] = p.namespace;
    vers = [(i.get('preferred',False), not (v.isdevelop() or i.get('deprecated',False)), v)
            for v, i in p.versions.items()]
    vers.sort(reverse = True)
    desc['version'] = [str(v) for _, _, v in vers]
    if p.variants:
        desc['variants'] = {n: variant(p, v) for n, v in p.variants.items()}
    if p.dependencies:
        desc['depends'] = {n: depend(p, d) for n, d in p.dependencies.items()}
    if p.provided:
        provides = defaultdict(list)
        for v, cs in p.provided.items():
            provides[v.name].extend((c, v.versions) for c in cs)
            virtuals[v.name].add(p.name)
        desc['provides'] = {v: provide(p, c) for v, c in provides.items()}
    packs[p.name] = Fun('spec', desc)
n = len(packs)
print(f"Generated {n} packages")
for v, p in virtuals.items():
    assert v not in packs
    packs[v] = List(p)
print(f"Generated {len(packs)-n} virtuals")

with open(os.environ['out'], 'w') as f:
    print("spackLib: with spackLib;", file=f)
    printNix(packs, out=f)
