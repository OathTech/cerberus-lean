#!/usr/bin/env python3
"""Auditor codec plants (item 3): the BASE (0457732e1) and HEAD (34b8e15a8) observations.py on the same
matrix of (origin, message, policy, status). Prints one row per case with both verdicts; the batch policy
must be IDENTICAL in every row; the ONLY immaculate/litmus differences must be the origin-set moves."""
import importlib.util, sys, pathlib
def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path); m = importlib.util.module_from_spec(spec); sys.modules[name] = m; spec.loader.exec_module(m); return m
BASE = load('obs_base', pathlib.Path('.tmp/audit/codec/observations_base.py'))
HEAD = load('obs_head', pathlib.Path('scripts/observations.py'))
def run(m, out, err, rc, pol):
    try:
        o = m.parse(out, err, rc, pol)
        return 'OK:' + ','.join(v.kind for v in o.verdicts) + (':' + o.verdicts[0].field('msg').decode()[:40] if o.verdicts and o.verdicts[0].kind == 'InternalError' else '')
    except m.ProtocolError as e:
        return 'ERR:' + str(e)
M = b'Ocaml_gcc_builtins.bswap64: Z.to_int64 overflow (ocaml_gcc_builtins.ml:30)'
FUEL = b'lem: fuel exhausted'
cases = [
 ('mangled LemLib origin, real msg',        b'PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: ' + M + b'\n', 134),
 ('OLD unmangled literal',                  b'PANIC at LemLib.failwithIImpl LemLib.lean:10:3: ' + M + b'\n', 134),
 ('stale seam origin CerbMem.casePtrval',   b'PANIC at CerbMem.casePtrval CerbMem:1385:4: case_ptrval\n', 134),
 ('stale seam origin CerbFloat.truncToInt', b'PANIC at CerbFloat.truncToInt CerbFloat:426:4: CerbFloat.truncToInt: nan/inf\n', 134),
 ('unknown origin',                         b'PANIC at Other.unreviewed Other:10:3: unrelated panic\n', 134),
 ('KEPT typeof_enum_impl origin',           b'PANIC at _private.CerberusImpl.0.CerberusImpl.typeof_enum_impl CerberusImpl:69:12: Ocaml_implementation.typeof_enum: tag was not registered\n', 134),
 ('CerbTags tripwire origin',               b'PANIC at CerbTags.tagDefsUnreachable CerbTags:34:2: CerbTags.tagDefsUnreachable: applied tagDefs () site survived reader lifting\n', 134),
 ('mangled origin + FUEL msg',              b'PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: ' + FUEL + b'\n', 134),
 ('stale origin + FUEL msg',                b'PANIC at CerbMem.casePtrval CerbMem:1385:4: ' + FUEL + b'\n', 134),
 ('forged: origin with trailing space',     b'PANIC at _private.LemLib.0.failwithIImpl  LemLib:168:2: ' + M + b'\n', 134),
 ('forged: newline inside origin',          b'PANIC at _private.LemLib.0.failwithIImpl\n LemLib:168:2: ' + M + b'\n', 134),
 ('forged: origin prefix-extended',         b'PANIC at _private.LemLib.0.failwithIImplX LemLib:168:2: ' + M + b'\n', 134),
 ('forged: origin with embedded space',     b'PANIC at _private.LemLib.0 failwithIImpl LemLib:168:2: ' + M + b'\n', 134),
 ('forged: CR inside origin',               b'PANIC at _private.LemLib.0.failwithIImpl\r LemLib:168:2: ' + M + b'\n', 134),
 ('mangled origin, wrong status 1',         b'PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: ' + M + b'\n', 1),
 ('mangled origin, stdout beside',          (b'X\n', b'PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: ' + M + b'\n'), 134),
 ('OCaml internal error (control)',         b'internal error: ' + M + b'\n', 125),
]
diffs_batch = 0
print(f"{'case':42s} {'policy':10s} {'BASE':60s} HEAD")
for name, err, rc in cases:
    out = b''
    if isinstance(err, tuple): out, err = err
    for pol in ('batch', 'immaculate', 'litmus'):
        b = run(BASE, out, err, rc, pol); h = run(HEAD, out, err, rc, pol)
        flag = '' if b == h else '   <== DIFFERS'
        if pol == 'batch' and b != h: diffs_batch += 1
        print(f'{name:42s} {pol:10s} {b[:60]:60s} {h[:60]}{flag}')
print(f'\nbatch-policy rows that differ base vs head: {diffs_batch}')
print('HEAD IMMACULATE_PANICS =', sorted(HEAD.IMMACULATE_PANICS)); print('BASE IMMACULATE_PANICS =', sorted(BASE.IMMACULATE_PANICS))
print('HEAD LEMLIB_FAILWITHI_ORIGIN =', HEAD.LEMLIB_FAILWITHI_ORIGIN)
