#!/bin/env python3

import os
import sys
import re
from collections import defaultdict

import nixpack
import spack
try:
    from spack.version import any_version
except ImportError:
    any_version = spack.spec._any_version

identPat = re.compile("[a-zA-Z_][a-zA-Z0-9'_-]*")
reserved = {'if','then','else','derivation','let','rec','in','inherit','import','with'}

def isident(s: str):
    return identPat.fullmatch(s) and s not in reserved

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

class Expr(Nix):
    def __init__(self, s, prec=0):
        self.str = s
        self.prec = prec
    def print(self, indent, out):
        out.write(self.str)

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

class Attr(Nix):
    def __init__(self, key, val):
        if not isinstance(key, str):
            raise TypeError(self.key)
        self.key = key
        self.val = val
    def print(self, indent, out):
        out.write(' '*indent)
        if isident(self.key):
            out.write(self.key)
        else:
            printNix(self.key, indent, out)
        out.write(' = ')
        printNix(self.val, indent, out)
        out.write(';\n')

class AttrSet(Nix, dict):
    def print(self, indent, out):
        out.write('{')
        first = True
        for k, v in sorted(self.items()):
            if first:
                out.write('\n')
                first = False
            Attr(k, v).print(indent+2, out)
        if not first:
            out.write(' '*indent)
        out.write('}')

class Select(Nix):
    prec = 1
    def __init__(self, val, *attr: str):
        self.val = val
        self.attr = attr
    def print(self, indent, out):
        if isinstance(self.val, str):
            out.write(self.val)
        else:
            self.paren(self.val, indent, out)
        for a in self.attr:
            out.write('.')
            if isident(a):
                out.write(a)
            else:
                self.paren(a, indent, out)

class SelectOr(Select):
    prec = 1
    def __init__(self, val, attr: str, ore):
        super().__init__(val, attr)
        self.ore = ore
    def print(self, indent, out):
        super().print(indent, out)
        out.write(' or ')
        self.paren(self.ore, indent, out)

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

class Or(Nix):
    prec = 13
    def __init__(self, *args):
        self.args = args
    def print(self, indent, out):
        first = True
        for a in self.args:
            if first:
                first = False
            else:
                out.write(' || ')
            self.paren(a, indent, out)
        if first:
            out.write('false')

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
        if first:
            out.write('true')

class Eq(Nix):
    prec = 11
    def __init__(self, a, b):
        self.a = a
        self.b = b
    def print(self, indent, out):
        self.paren(self.a, indent, out)
        out.write(' == ')
        self.paren(self.b, indent, out)

class Ne(Nix):
    prec = 11
    def __init__(self, a, b):
        self.a = a
        self.b = b
    def print(self, indent, out):
        self.paren(self.a, indent, out)
        out.write(' != ')
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
    elif isinstance(x, (list, tuple)):
        List(x).print(indent, out)
    elif isinstance(x, set):
        List(sorted(x)).print(indent, out)
    elif isinstance(x, dict):
        AttrSet(x).print(indent, out)
    else:
        raise TypeError(type(x))

def unlist(l):
    if isinstance(l, (list, tuple)) and len(l) == 1:
        return l[0]
    return l

def specPrefs(s):
    p = {}
    if s.versions != any_version:
        p['version'] = str(s.versions)
    if s.variants:
        p['variants'] = {n: unlist(v.value) for n, v in s.variants.items()}
    d = s.dependencies()
    if d:
        p['depends'] = {x.name: specPrefs(x) for x in d}
    return p

def depPrefs(d):
    p = specPrefs(d.spec)
    try:
        p['deptype'] = spack.deptypes.flag_to_tuple(d.depflag)
    except AttributeError:
        p['deptype'] = d.type
    if d.patches:
        print(f"{d} has unsupported dependency patches", file=sys.stderr)
    return p

def conditions(c, p, s, dep=None):
    def addConditions(a, s):
        deps = Select(a,'depends')
        if s.versions != any_version:
            c.append(App("versionMatches", Select(a,'version'), str(s.versions)))
        if s.variants:
            for n, v in sorted(s.variants.items()):
                c.append(App("variantMatches", Select(a,'variants',n), unlist(v.value)))
        if s.compiler:
            notExtern = Eq(Select(a,'extern'), None)
            if s.compiler.name:
                c.append(And(notExtern, Eq(Select(deps,'compiler','spec','name'), s.compiler.name)))
            if s.compiler.versions != any_version:
                c.append(And(notExtern, App("versionMatches", Select(deps,'compiler','spec','version'), str(s.compiler.versions))))
        for d in s.dependencies():
            if dep and d.name == dep.spec.name:
                print(f"{dep}: skipping recursive dependency conditional {d}", file=sys.stderr)
                continue
            c.append(Ne(SelectOr(deps,d.name,None),None))
            addConditions(Select(deps,d.name,'spec'), d)
        if s.architecture:
            if s.architecture.os:
                c.append(Eq(Expr('os'), s.architecture.os))
            if s.architecture.platform:
                c.append(Eq(Expr('platform'), s.architecture.platform))
            if s.architecture.target:
                # this isn't actually correct due to fancy targets but good enough for this
                c.append(Eq(Expr('target'), str(s.architecture.target).rstrip(':')))
    if s.name is not None and s.name != p.name:
        # spack sometimes interprets this to mean p provides a virtual of s.name, and sometimes to refer to the named package anywhere in the dep tree
        print(f"{p.name}: ignoring unsupported named condition {s}")
        c.append(False)
    addConditions('spec', s)

def whenCondition(p, s, a, dep=None):
    c = []
    conditions(c, p, s, dep)
    if not c:
        return a
    return App('when', And(*c), a)

try:
    VariantValue = spack.variant.Value
except AttributeError:
    VariantValue = None

def variant1(p, v):
    def value(x):
        if VariantValue and isinstance(x, VariantValue):
            print(f"{p.name} variant {v.name}: ignoring unsupported conditional on value {x}", file=sys.stderr)
            return x.value
        return x

    d = str(v.default)
    if v.multi and v.values is not None:
        d = d.split(',')
        return {x: x in d for x in map(value, v.values)}
    elif v.values == (True, False):
        return d.upper() == 'TRUE'
    elif v.values:
        l = list(map(value, v.values))
        try:
            l.remove(d)
            l.insert(0, d)
        except ValueError:
            print(f"{p.name}: variant {v.name} default {v.default!r} not in {v.values!r}", file=sys.stderr)
        return l
    else:
        return d

def variant(p, v):
    if type(v) is tuple:
        a = variant1(p, v[0])
        l = []
        for w in v[1]:
            c = []
            conditions(c, p, w)
            if not c:
                return a
            l.append(And(*c))
        return App('when', Or(*l), a)
    else:
        return variant1(p, v)

def depend(p, d):
    c = [whenCondition(p, w, depPrefs(s), s) for w, s in sorted(d.items())]
    if len(c) == 1:
        return c[0]
    return List(c)

def provide(p, wv):
    c = [whenCondition(p, w, str(v)) for w, v in wv]
    if len(c) == 1:
        return c[0]
    return List(c)

def conflict(p, c, w, m):
    l = []
    conditions(l, p, spack.spec.Spec(c))
    conditions(l, p, w)
    return App('when', And(*l), str(c) + (' ' + m if m else ''))

namespaces = ', '.join(r.namespace for r in spack.repo.PATH.repos)
print(f"Generating package repo for {namespaces}...")
f = open(os.environ['out'], 'w')
print("spackLib: with spackLib; {", file=f)
def output(k, v):
    printNix(Attr(k, v), out=f)

virtuals = defaultdict(set)
n = 0
for p in spack.repo.PATH.all_package_classes():
    desc = dict()
    desc['namespace'] = p.namespace;
    vers = [(i.get('preferred',False), not (v.isdevelop() or i.get('deprecated',False)), v)
            for v, i in p.versions.items()]
    vers.sort(reverse = True)
    desc['version'] = [str(v) for _, _, v in vers]
    if p.variants:
        desc['variants'] = {n: variant(p, entry) for n, entry in p.variants.items()}
    if p.dependencies:
        desc['depends'] = {n: depend(p, d) for n, d in p.dependencies.items()}
    if p.conflicts:
        desc['conflicts'] = [conflict(p, c, w, m) for c, wm in sorted(p.conflicts.items()) for w, m in wm]
    if p.provided:
        provides = defaultdict(list)
        for v, cs in sorted(p.provided.items()):
            provides[v.name].extend((c, v.versions) for c in sorted(cs))
            virtuals[v.name].add(p.name)
        desc['provides'] = {v: provide(p, c) for v, c in provides.items()}
    if getattr(p, 'family', None) == 'compiler':
        desc.setdefault('provides', {}).setdefault('compiler', ':')
    output(p.name, Fun('spec', desc))
    n += 1
print(f"Generated {n} packages")

# use spack config for provider ordering
prefs = spack.config.get("packages:all:providers", {})
for v, providers in sorted(virtuals.items()):
    prov = []
    for p in prefs.get(v, []):
        n = spack.spec.Spec(p).name
        try:
            providers.remove(n)
        except KeyError:
            continue
        prov.append(n)
    prov.extend(sorted(providers))
    output(v, prov)
print(f"Generated {len(virtuals)} virtuals")

print("}", file=f)
f.close()
