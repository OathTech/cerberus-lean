#!/usr/bin/env python3
"""generate.py -- the generator of the fourteen GENERATED witness programs of tests/macro_type_ranks/
(limits_header_1..4, limits_direct_1, limits_pairs_1, kept_limits_wchar, kept_limits_wint, kept_limits_pairs_1..2,
kept_wchar_obj_std_200000005, kept_wchar_obj_std_2147483647, kept_wchar_obj_macro, kept_wchar_self).

What it does (record lean_frontend/docs/2026-11-14_wchar-rank-record.md, sections 3 and 4; committed on the
pre-merge review's F5, 2026-11-14: generated text without its generator cannot be maintained):

1. ENUMERATE one-expression probes over every limit macro the shipped <limits.h>/<stdint.h> define (read from
   runtime/libc/include; the 36 distinct expansions), the 36 direct __cerbvar_* limit spellings, and wchar_t
   objects: each compared with 0, promoted, converted, against int/unsigned/long/unsigned long (0, 1, -1), against
   each other; a wchar_t object against every integer type. 54,329 rows; their order is the order of the programs'
   lines.
2. MEASURE the rows a program can select, each as its own program (`--nolibc --exec --batch`), on three referees:
   this tree's oracle, an un-forked (pristine) Cerberus, and gcc (`-std=c11 -w -O0`; a second build with
   -fsanitize=undefined plus gcc's own -Woverflow diagnostics marks the rows whose gcc run is undefined).
3. SELECT and EMIT:
   KEPT programs (kept_*): every row with a wchar_t / wint_t operand, of the kinds the program's title names, where
     this tree's oracle prints a value, pristine prints the same value, and gcc's run is not undefined. Their pins
     are pristine's lines (expected.txt = pristine.txt); gcc's line stands beside in kept.txt.
   gcc programs (limits_*): every row WITHOUT such an operand, of the kinds the title names, where this tree's
     oracle prints a value and gcc prints the same value. Their pins are gcc's lines.

The selection is a MEASUREMENT: when upstream settles wchar_t's range (upstream-tray report 62), at a merge-base
bump, or when the shipped headers change, re-run this, read the diff of the emitted programs, and re-derive the pin
lines of the programs that moved (expected.txt, pristine.txt, kept.txt; d14.txt is a historical record and is not
re-derived). The pin lines themselves are not written by this script: they are each engine's own line for the
emitted program.

Usage (from anywhere; the tree must be built):
  generate.py --pristine-bin <un-forked cerberus driver> --pristine-runtime <its runtime prefix> --check
      re-measure and compare the fourteen emitted programs with the committed ones, byte for byte (exit 1 on any
      difference, with the list)
  generate.py --pristine-bin ... --pristine-runtime ... --emit <dir>
      write the fourteen programs into <dir>
Options: --oracle-bin / --oracle-runtime (default: this tree's _build), --jobs N (default 6), --work <dir> (scratch;
default <tree>/.tmp/macro_type_rank_gen, removed on success unless --keep-work).
Cost, measured 2026-11-14: 17,652 single-expression runs per Cerberus referee and 558 gcc programs built twice;
3 min 22 s at --jobs 6.
"""
import argparse, json, os, re, shutil, subprocess, sys
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
INC = os.path.join(ROOT, 'runtime/libc/include')
GENERATED = ['kept_limits_wchar', 'kept_limits_wint', 'kept_limits_pairs_1', 'kept_limits_pairs_2',
             'kept_wchar_obj_std_200000005', 'kept_wchar_obj_std_2147483647', 'kept_wchar_obj_macro', 'kept_wchar_self',
             'limits_header_1', 'limits_header_2', 'limits_header_3', 'limits_header_4', 'limits_direct_1', 'limits_pairs_1']

# ---------------------------------------------------------------------------------------------------------------
# 1. the rows
# ---------------------------------------------------------------------------------------------------------------
def defines(h):
    d = {}
    txt = open(os.path.join(INC, h)).read()
    if h == 'stdint.h':  # the FIXED_STDINT branch is the live one; read only it and the common tail
        a = txt.index('#ifdef FIXED_STDINT'); b = txt.index('#else', a); c = txt.index('#endif', b)
        txt = txt[a:b] + txt[c:]
    for m in re.finditer(r'^#define\s+(\w+)\s+(\S+)\s*$', txt, re.M):
        d[m.group(1)] = m.group(2)
    return d

D = {}
for _h in ('limits.h', 'stdint.h', 'stddef.h', 'wchar.h'):
    D.update(defines(_h))

def resolve(n):
    seen = set()
    while n in D and n not in seen:
        seen.add(n); n = D[n]
    return n

LIMIT = sorted(n for n in D if re.search(r'_(MIN|MAX)$', n) or n == 'CHAR_BIT')
LIMIT = [n for n in LIMIT if n not in ('IOV_MAX', 'NAME_MAX')] + ['IOV_MAX', 'NAME_MAX']
canon = {}   # header macro -> the first header macro (in LIMIT's order) with the same expansion
_byexp = {}
for _n in LIMIT:
    _e = resolve(_n)
    if _e in _byexp and not re.fullmatch(r'\d+', _e): canon[_n] = _byexp[_e]
    else:
        _byexp.setdefault(_e, _n); canon[_n] = _n
HEADER_CANON = [n for n in LIMIT if canon[n] == n]
# the shipped header's own (FIXED_STDINT) definitions of the exact-width limits: gcc is given these, because glibc
# types int64_t as long where the shipped <stdint.h> says long long
FIXED = [n for n in LIMIT if n in D and not D[n].startswith('__cerbvar_') and not D[n].isdigit()]
# direct __cerbvar_* spellings of the non-FIXED branch (unreachable through the shipped headers), and what gcc is
# given for them: the implementation's alias type and its <limits.h> limit
WIDTHS = {8: ('signed char', 'unsigned char', 'SCHAR_MIN', 'SCHAR_MAX', 'UCHAR_MAX'), 16: ('short', 'unsigned short', 'SHRT_MIN', 'SHRT_MAX', 'USHRT_MAX'),
          32: ('int', 'unsigned', 'INT_MIN', 'INT_MAX', 'UINT_MAX'), 64: ('long', 'unsigned long', 'LONG_MIN', 'LONG_MAX', 'ULONG_MAX')}
DIRECT = []; GCCDEF = []
for _fam in ('INT%d', 'INT_LEAST%d', 'INT_FAST%d'):
    for _w, (_st, _ut, _mn, _mx, _umx) in WIDTHS.items():
        _f = _fam % _w
        for _nm, _ty, _val in ((_f + '_MIN', _st, _mn), (_f + '_MAX', _st, _mx), ('U' + _f + '_MAX', _ut, _umx)):
            DIRECT.append('__cerbvar_' + _nm); GCCDEF.append('#define __cerbvar_%s ((%s)%s)' % (_nm, _ty, _val))
DIRECT_SET = set(DIRECT)
POSIX_DEFS = '#ifndef IOV_MAX\n#define IOV_MAX 1024\n#endif\n#ifndef NAME_MAX\n#define NAME_MAX 1024\n#endif\n'
TC_DEF = '#define TC(e) _Generic((e), _Bool:1, char:2, signed char:3, unsigned char:4, short:5, unsigned short:6, int:7, unsigned:8, long:9, unsigned long:10, long long:11, unsigned long long:12, default:99)\n'
ENUM_DEFS = 'enum EU { EU0 = 0, EU3 = 3, EUBIG = 700000005 };\nenum ES { ESNEG = -1, ES3 = 3, ESBIG = 700000005 };\n'
# the header of the single-expression measurement programs
HDR = '#include <stdio.h>\n#include <limits.h>\n#include <stdint.h>\n#include <stddef.h>\n#include <wchar.h>\n#ifndef __cerb__\n' + POSIX_DEFS + \
      ''.join('#undef %s\n#define %s %s\n' % (n, n, D[n]) for n in FIXED) + '\n'.join(GCCDEF) + '\n#endif\n' + TC_DEF + ENUM_DEFS
NHDR = HDR.count('\n')

rows = []; groups = {}
def row(group, kind, macros, expr, decl=''):
    rid = len(rows)
    rows.append(dict(id=rid, group=group, kind=kind, macros=macros, expr=expr, decl=decl))
    groups.setdefault(group, []).append(rid)

CASTS = ['_Bool', 'signed char', 'unsigned char', 'short', 'unsigned short', 'int', 'unsigned', 'long', 'unsigned long', 'long long', 'unsigned long long']
def single(M, g, ms):
    for e in ('%s > 0', '%s < 0', '%s == 0', '%s != 0', '%s >= 0', '%s <= 0', '0 < %s', '0 > %s', '0 == %s'):
        row(g, 'cmp0', ms, e % M)
    for e in ('+%s', '-%s', '~%s', '!%s', '(+%s) > 0', 'sizeof(%s)', 'sizeof(+%s)', 'TC(%s)', 'TC(+%s)', 'TC(-%s)', 'TC(~%s)'):
        row(g, 'promoted', ms, e % M)
    for t in CASTS:
        row(g, 'converted', ms, '(%s)%s' % (t, M))
    row(g, 'converted', ms, '(long long)%s > 0' % M); row(g, 'converted', ms, '(long long)%s < 0' % M)
    for t in ('int', 'unsigned', 'long', 'unsigned long'):
        row(g, 'converted', ms, 'x', '%s x = %s;' % (t, M))
    for e in ('%s + 1', '%s - 1', '%s - 1 > 0', '%s + 1 > 0', '%s + 1u', '%s - 1u', '%s + 1l', '%s - 1ul'):
        row(g, 'uac-lit', ms, e % M)

PART = ['int', 'unsigned', 'long', 'unsigned long']
def uac(M, g0, ms):
    for P in PART:
        for v in (0, 1, -1):
            g = '%s__%s_%s' % (g0, P.replace(' ', '_'), str(v).replace('-', 'm'))
            d = '%s p = %d;' % (P, v)
            es = ['M < p', 'M > p', 'M == p', 'M != p', 'M <= p', 'M >= p', 'p < M', 'p > M', 'p == M', 'p <= M', 'M + p', 'p + M', 'M - p', 'p - M', 'M * p', 'p * M',
                  'M & p', 'M | p', 'M ^ p', 'p & M', 'p | M', '1 ? M : p', '1 ? p : M', '0 ? M : p', 'TC(M + p)', 'TC(p + M)', 'TC(1 ? M : p)', 'sizeof(M + p)']
            if v != 0 and not (v == -1 and 'unsigned' not in P): es += ['M / p', 'M % p']
            for e in es:
                row(g, 'uac', ms, re.sub(r'\bM\b', M, e), d)
            for op in ('+=', '-=', '&=', '|='):
                row(g, 'uac', ms, 't', '%s %s t = p; t %s %s;' % (d, P, op, M))

def pair(A, B, g, ms):
    for e in ('A < B', 'A > B', 'A == B', 'A != B', 'A <= B', 'A >= B', 'B < A', '1 ? A : B', '1 ? B : A', 'A & B', 'A | B', 'A ^ B', 'B ^ A', 'A + B', 'A - B', 'B - A', 'TC(1 ? A : B)', 'TC(A + B)', 'sizeof(A + B)'):
        row(g, 'pair', ms, e.replace('A', '\x01').replace('B', B).replace('\x01', A))

for _M in HEADER_CANON + DIRECT:
    single(_M, 'single__' + _M, [_M]); uac(_M, 'uac__' + _M, [_M])
for _i, _A in enumerate(HEADER_CANON):
    for _B in HEADER_CANON[_i:]:
        pair(_A, _B, 'pair__%s__%s' % (_A, _B), [_A, _B])
# typed objects: wchar_t against every standard partner, itself, and the other macro types
STD = ['_Bool', 'char', 'signed char', 'unsigned char', 'short', 'unsigned short', 'int', 'unsigned', 'long', 'unsigned long', 'long long', 'unsigned long long', 'enum EU', 'enum ES']
MACT = ['size_t', 'ptrdiff_t', 'intptr_t', 'uintptr_t', 'intmax_t', 'uintmax_t', 'wchar_t']
for _wv in (0, 5, 200000005, 2147483647):
    _Wd = 'wchar_t w = %d;' % _wv
    for _P in STD + MACT:
        _vals = (0, 3) if _P == '_Bool' else ((0, 3, -3) if _P != 'enum EU' else (0, 3))
        for _v in _vals:
            _g = 'wobj__%d__%s_%s' % (_wv, _P.replace(' ', '_'), str(_v).replace('-', 'm'))
            _d = '%s %s p = %d;' % (_Wd, _P, _v)
            _es = ['w < p', 'w > p', 'w == p', 'w != p', 'w <= p', 'w >= p', 'p < w', 'p > w', 'p == w', 'w + p', 'p + w', 'w - p', 'p - w', 'w * p', 'p * w', 'w & p', 'w | p', 'w ^ p', 'p & w',
                   '1 ? w : p', '1 ? p : w', 'TC(w + p)', 'TC(p + w)', 'TC(1 ? w : p)', 'sizeof(w + p)']
            if _v != 0: _es += ['w / p', 'w % p']
            if _wv != 0: _es += ['p / w', 'p % w']
            for _e in _es: row(_g, 'wobj', ['wchar_t', _P], _e, _d)
            for _op in ('+=', '-=', '*=', '&=', '|=', '^='):
                row(_g, 'wobj', ['wchar_t', _P], 't', '%s %s t = p; t %s w;' % (_d, _P, _op))
                row(_g, 'wobj', ['wchar_t', _P], 't', '%s wchar_t t = w; t %s p;' % (_d, _op))
    _g = 'wself__%d' % _wv
    for _e in ('+w', '-w', '~w', '!w', 'w > 0', 'w < 0', 'w == 0', '(+w) > 0', 'sizeof(w)', 'sizeof(+w)', 'TC(w)', 'TC(+w)', 'TC(-w)', 'TC(~w)', 'w << 1', 'w >> 1', '1 << w', 'w + 1', 'w - 1', 'w - 1 < 0', 'w + 1 > 0',
               'w - 10 < 0', 'w + 1u', 'w - 6l', 'w++', '--w', 'w && 1', 'w ? 2 : 3') + tuple('(%s)w' % t for t in CASTS):
        row(_g, 'wself', ['wchar_t'], _e, _Wd)
for _e in ("L'a'", "L'a' + 1", "L'a' > 0", "L'a' - 200 < 0", "TC(L'a')", "sizeof(L'a')", "(wchar_t)-1 < 0", "(wchar_t)-1", "(wchar_t)-1 > 0", "(wchar_t)3000000000u", "(wchar_t)5 - 6 < 0", "(wchar_t)5 - 6", "(wchar_t)1 << 31",
           "(wchar_t)2147483647 + 1", "(wchar_t)2147483647 + 1 > 0", "(wchar_t)5 * -1", "(wchar_t)5 / -1", "(wchar_t)5 < -1", "(wchar_t)5 < -1l", "(wchar_t)5 < 4294967295u", "-(wchar_t)5 < 0", "~(wchar_t)5 < 0", "TC((wchar_t)5 + 1)",
           "TC((wchar_t)5 + 1l)", "TC((wchar_t)5 + 1u)", "TC(+(wchar_t)5)", "TC(1 ? (wchar_t)5 : (short)1)", "sizeof((wchar_t)5 + (short)1)", "L\"ab\"[0]", "L\"ab\"[0] + 1 > 0", "sizeof(L\"ab\")"):
    row('wmisc', 'wmisc', ['wchar_t'], _e)
for _d, _e in (('wchar_t w = -1;', 'w < 0'), ('wchar_t w = -1;', 'w'), ('wchar_t w = 100000;', '(w - 200000) < 0'), ('wchar_t w = 100000;', 'w - 200000'), ("wchar_t w = L'\\377';", 'w == 255'),
               ('wchar_t a[3] = {1, 2, 3};', 'a[1] + a[2]'), ('wchar_t w = 7; wchar_t *q = &w;', '*q * 2'), ('wchar_t w = 7; int i = 9;', 'i > w ? i : w'), ('wchar_t w = 7; long l = 8589934592;', 'w + l'),
               ('wchar_t w = 7; long l = 8589934592;', 'l + w'), ('wchar_t w = 7; long l = 8589934592;', 'w < l'), ('wchar_t w = 7; unsigned long l = 8589934592;', 'w + l'), ('wchar_t w = 7; long long l = 8589934592;', 'w + l'),
               ('wchar_t w = 7; long long l = 8589934592;', 'l - w'), ('wchar_t w = 7; unsigned long long l = 8589934592;', 'l * w'), ('wchar_t w = 7; int i = -9;', 'w + i'), ('wchar_t w = 7; int i = -9;', 'w + i < 0'),
               ('wchar_t w = 7; int i = -9;', 'w > i'), ('wchar_t w = 7; unsigned i = 9;', 'w - i'), ('wchar_t w = 7; unsigned i = 9;', 'w - i > 0'), ('wchar_t w = 7; short i = -9;', 'w > i'), ('wchar_t w = 7; signed char i = -9;', 'w * i')):
    row('wmisc', 'wmisc', ['wchar_t'], _e, _d)

# ---------------------------------------------------------------------------------------------------------------
# 3 (stated first: what a program may select decides what is measured). The selection rules
# ---------------------------------------------------------------------------------------------------------------
WNAMES = {'WCHAR_MAX', 'WCHAR_MIN', 'WINT_MAX', 'WINT_MIN', 'wchar_t'}
SINGLE_KINDS = ('cmp0', 'promoted', 'converted', 'uac-lit')
RANKED = {'INTPTR_MIN', 'INTPTR_MAX', 'UINTPTR_MAX', 'INTMAX_MIN', 'INTMAX_MAX', 'UINTMAX_MAX', 'PTRDIFF_MIN', 'PTRDIFF_MAX', 'SIZE_MAX'}
OBJ_VALUES = (200000005, 2147483647)
def isw(r): return any(m in WNAMES for m in r['macros'])
def obj_group(r): return r['group'].startswith(tuple('wobj__%d__' % v for v in OBJ_VALUES))

KEPT_T = 'KEPT (upstream\'s behaviour for wchar_t / wint_t, pinned to pristine c3ff8c53f\'s line; gcc 13\'s line beside in kept.txt): '
GCC_T = 'gcc 13\'s line on both engines: '
LIMIT_KINDS = SINGLE_KINDS + ('uac',)
# (name stem, chunk size or None, class, predicate on a row, title); a chunked stem emits <stem>_1, <stem>_2, ...
PROGRAMS = [
    ('kept_limits_wchar', None, 'kept', lambda r: r['kind'] in LIMIT_KINDS and r['macros'][0].startswith('WCHAR'),
     KEPT_T + 'WCHAR_MIN and WCHAR_MAX compared with 0, promoted, converted, and against int, unsigned, long, unsigned long (0, 1, -1)'),
    ('kept_limits_wint', None, 'kept', lambda r: r['kind'] in LIMIT_KINDS and r['macros'][0].startswith('WINT'),
     KEPT_T + 'WINT_MIN and WINT_MAX compared with 0, promoted, converted, and against int, unsigned, long, unsigned long (0, 1, -1)'),
    ('kept_limits_pairs', 1300, 'kept', lambda r: r['kind'] == 'pair',
     KEPT_T + 'the WCHAR_* and WINT_* limit macros against every limit macro of the shipped headers'),
] + [
    ('kept_wchar_obj_std_%d' % wv, None, 'kept', (lambda wv: lambda r: r['kind'] == 'wobj' and r['group'].startswith('wobj__%d__' % wv) and r['macros'][1] not in MACT)(wv),
     KEPT_T + 'a wchar_t object (%d) against every standard partner type and both enums, both orders, every operator and op=' % wv) for wv in OBJ_VALUES
] + [
    ('kept_wchar_obj_macro', None, 'kept', lambda r: r['kind'] == 'wobj' and obj_group(r) and r['macros'][1] in MACT,
     KEPT_T + 'a wchar_t object (200000005, 2147483647) against the other macro integer types and itself, both orders, every operator and op='),
    ('kept_wchar_self', None, 'kept', lambda r: r['kind'] in ('wself', 'wmisc'),
     KEPT_T + 'wchar_t objects, casts and wide character constants on their own: promotion, unary operators, shifts, conversions'),
    ('limits_header', 1600, 'gcc', lambda r: (r['kind'] in SINGLE_KINDS or (r['kind'] == 'uac' and r['group'].endswith('_m1'))) and r['macros'][0] not in DIRECT_SET,
     GCC_T + 'the limit macros of the shipped <limits.h>/<stdint.h> other than WCHAR_*/WINT_*: compared with 0, promoted, converted, and against int, unsigned, long, unsigned long at -1'),
    ('limits_direct', 1600, 'gcc', lambda r: r['kind'] in SINGLE_KINDS and r['macros'][0] in DIRECT_SET,
     GCC_T + 'the direct __cerbvar_* limit spellings of the exact-width, least and fast families (the non-FIXED_STDINT branch of <stdint.h>): compared with 0, promoted, converted'),
    ('limits_pairs', 1600, 'gcc', lambda r: r['kind'] == 'pair' and all(m in RANKED for m in r['macros']),
     GCC_T + 'the limit macros of the macro integer types that carry their implementation rank (INTPTR_*, UINTPTR_MAX, INTMAX_*, UINTMAX_MAX, PTRDIFF_*, SIZE_MAX) against each other'),
]
def candidate(r):
    w = isw(r)
    return any((cls == 'kept') == w and pred(r) for _, _, cls, pred, _ in PROGRAMS)

# ---------------------------------------------------------------------------------------------------------------
# 2. the measurement
# ---------------------------------------------------------------------------------------------------------------
ENV = dict(os.environ, NO_COLOR='1', TERM='dumb')
def body(r): return '{ %s printf("R%d %%llu\\n", (unsigned long long)(%s)); }' % (r['decl'], r['id'], r['expr'])
def gbody(r):
    # gcc narrows `t op= M` on an int object to 32-bit arithmetic, and UBSan then never sees the overflow of the
    # standard's type: a shadow evaluation in the usual arithmetic type on the same source line
    m = re.fullmatch(r'(.*) t = (\w+); t (\S)= (.+);', r['decl'])
    if not m: return body(r)
    return '{ %s tt_ = %s; volatile unsigned long long s_ = (unsigned long long)(tt_ %s %s); } ' % (m.group(1), m.group(2), m.group(3), m.group(4)) + body(r)

def run_cerb(work, exe, rt, r):
    c = os.path.join(work, 'progs', '%d.c' % r['id'])
    try:
        p = subprocess.run([exe, '--runtime=' + rt, '--exec', '--batch', '--nolibc', c], capture_output=True, text=True, errors='replace', timeout=120, env=ENV)
    except subprocess.TimeoutExpired:
        return r['id'], 'X timeout'
    for l in p.stdout.splitlines():
        if l.startswith('Defined '):
            m = re.search(r'stdout: "R\d+ (\d+)\\n"', l)
            return r['id'], ('D ' + m.group(1)) if m and p.returncode == 0 else 'X'
        if l.startswith(('Undefined ', 'Error', 'Killed')): return r['id'], 'X ' + l.split()[0]
    return r['id'], 'X no verdict'

def run_gcc(work, glines, g):
    src = os.path.join(work, 'gcc', g + '.c'); res = {}
    for tag, flags in (('plain', ['-w']), ('ubsan', ['-fsanitize=undefined'])):
        exe = os.path.join(work, 'gccbin', g + '.' + tag)
        p = subprocess.run(['gcc', '-std=c11', '-O0'] + flags + [src, '-o', exe], capture_output=True, text=True)
        cub = set()
        if tag == 'ubsan':  # constant-folded overflow is not seen by UBSan: gcc's own -Woverflow diagnostics
            for m in re.finditer(r'\.c:(\d+):\d+: warning: integer overflow in expression', p.stderr):
                cub.add(glines['%s:%s' % (g, m.group(1))])
        if p.returncode != 0:
            return {i: 'X gcc-compile' for i in groups[g]}
        try: q = subprocess.run([exe], capture_output=True, text=True, timeout=60)
        except subprocess.TimeoutExpired: return {i: 'X gcc-timeout' for i in groups[g]}
        os.remove(exe)
        vals = {int(a): b for a, b in re.findall(r'^R(\d+) (\d+)$', q.stdout, re.M)}
        ub = {glines['%s:%s' % (g, m.group(1))] for m in re.finditer(r'\.c:(\d+):\d+: runtime error', q.stderr)}
        res[tag] = (vals, ub | cub)
    out = {}
    for i in groups[g]:
        pv = res['plain'][0].get(i); uv = res['ubsan'][0].get(i)
        if i in res['ubsan'][1]: out[i] = 'GCCUB'
        elif pv is None or uv is None or pv != uv: out[i] = 'X gcc'
        else: out[i] = 'D ' + pv
    return out

def measure(args, work):
    cand = [r for r in rows if candidate(r)]
    for d in ('progs', 'gcc', 'gccbin'): os.makedirs(os.path.join(work, d), exist_ok=True)
    for r in cand:
        open(os.path.join(work, 'progs', '%d.c' % r['id']), 'w').write(HDR + 'int main(void) { ' + body(r) + ' return 0; }\n')
    cgroups = sorted({r['group'] for r in cand}); glines = {}
    for g in cgroups:
        with open(os.path.join(work, 'gcc', g + '.c'), 'w') as f:
            f.write(HDR + 'int main(void) {\n')
            for k, rid in enumerate(groups[g]):
                f.write(gbody(rows[rid]) + '\n'); glines['%s:%d' % (g, NHDR + 2 + k)] = rid
            f.write('return 0; }\n')
    res = {}
    for name, exe, rt in (('oracle', args.oracle_bin, args.oracle_runtime), ('pristine', args.pristine_bin, args.pristine_runtime)):
        with ThreadPoolExecutor(args.jobs) as ex:
            res[name] = dict(ex.map(lambda r: run_cerb(work, exe, rt, r), cand))
        print('generate.py: %s: %d rows measured, %d with a value' % (name, len(res[name]), sum(v.startswith('D ') for v in res[name].values())), flush=True)
    G = {}
    with ThreadPoolExecutor(args.jobs) as ex:
        for o in ex.map(lambda g: run_gcc(work, glines, g), cgroups): G.update(o)
    res['gcc'] = G
    print('generate.py: gcc: %d groups, %d rows with a value, %d undefined in gcc\'s types' % (len(cgroups), sum(v.startswith('D ') for v in G.values()), sum(v == 'GCCUB' for v in G.values())), flush=True)
    return res

# ---------------------------------------------------------------------------------------------------------------
# 3. selection and emission
# ---------------------------------------------------------------------------------------------------------------
def header(rs, title):
    h = '// %s\n// Generated 2026-11-14 from the measured vicinity of the wchar_t rank correction (record\n// lean_frontend/docs/2026-11-14_wchar-rank-record.md, section 3); one value per expression, in order.\n' % title
    h += '#include <stdio.h>\n#include <limits.h>\n#include <stdint.h>\n#include <stddef.h>\n'
    h += '#define P(e) printf("%llu ", (unsigned long long)(e))\n'
    used = sorted({m for r in rs for m in r['macros'] if m in DIRECT_SET})
    text = ' '.join(r['decl'] + ' ' + r['expr'] for r in rs)
    fixed = [n for n in FIXED if re.search(r'\b%s\b' % n, text)]
    posix = 'IOV_MAX' in text or 'NAME_MAX' in text
    if used or fixed or posix:
        h += '#ifndef __cerb__\n'
        if fixed: h += '// gcc is given the shipped <stdint.h>\'s own (FIXED_STDINT) definitions of the exact-width limits: glibc types int64_t as long, the shipped header as long long\n'
        for n in fixed: h += '#undef %s\n#define %s %s\n' % (n, n, D[n])
        if posix: h += POSIX_DEFS
        for l in GCCDEF:
            if l.split()[1] in used: h += l + '\n'
        h += '#endif\n'
    if 'TC(' in text: h += TC_DEF
    if 'enum E' in text: h += ENUM_DEFS
    return h

def chunks(rs, n):
    k = max(1, -(-len(rs) // n)); m = -(-len(rs) // k)
    return [rs[i:i + m] for i in range(0, len(rs), m)]

def emit(res, outdir):
    A, P, G = res['oracle'], res['pristine'], res['gcc']
    def ok(cls, r):
        i = r['id']
        if i not in A: return False
        if cls == 'kept': return isw(r) and A[i].startswith('D ') and A[i] == P[i] and G[i].startswith('D ')
        return (not isw(r)) and A[i].startswith('D ') and A[i] == G[i]
    written = {}
    for stem, size, cls, pred, title in PROGRAMS:
        rs = [r for r in rows if pred(r) and ok(cls, r)]
        parts = [(stem, rs)] if size is None else [('%s_%d' % (stem, n + 1), c) for n, c in enumerate(chunks(rs, size))]
        for name, part in parts:
            if not part: continue
            with open(os.path.join(outdir, name + '.c'), 'w') as f:
                f.write(header(part, title) + 'int main(void) {\n')
                for r in part: f.write(('  { %s P(%s); }\n' % (r['decl'], r['expr'])) if r['decl'] else '  P(%s);\n' % r['expr'])
                f.write('  printf("\\n");\n  return 0;\n}\n')
            written[name] = len(part)
    return written

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--pristine-bin', required=True); ap.add_argument('--pristine-runtime', required=True)
    ap.add_argument('--oracle-bin', default=os.path.join(ROOT, '_build/default/backend/driver/main.exe'))
    ap.add_argument('--oracle-runtime', default=os.path.join(ROOT, '_build/install/default'))
    ap.add_argument('--jobs', type=int, default=6)
    ap.add_argument('--work', default=os.path.join(ROOT, '.tmp', 'macro_type_rank_gen'))
    ap.add_argument('--keep-work', action='store_true')
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument('--check', action='store_true'); mode.add_argument('--emit', metavar='DIR')
    args = ap.parse_args()
    for exe in (args.oracle_bin, args.pristine_bin):
        if not os.access(exe, os.X_OK): sys.exit('generate.py: FAIL -- not an executable driver: %s' % exe)
    if shutil.which('gcc') is None: sys.exit('generate.py: FAIL -- gcc not found')
    if len(rows) != 54329: sys.exit('generate.py: FAIL -- %d rows enumerated, 54329 expected: the shipped headers\' limit macros changed; review the enumeration before trusting a regeneration' % len(rows))
    work = os.path.abspath(args.work)
    if os.path.exists(work): shutil.rmtree(work)
    os.makedirs(work)
    print('generate.py: %d rows enumerated, %d measured (the rows a program can select)' % (len(rows), sum(candidate(r) for r in rows)), flush=True)
    res = measure(args, work)
    outdir = os.path.abspath(args.emit) if args.emit else os.path.join(work, 'emitted')
    os.makedirs(outdir, exist_ok=True)
    written = emit(res, outdir)
    print('generate.py: emitted ' + ', '.join('%s (%d)' % kv for kv in written.items()), flush=True)
    rc = 0
    if args.check:
        bad = []
        if sorted(written) != sorted(GENERATED): bad.append('the set of emitted programs is %s, the committed set is %s' % (sorted(written), sorted(GENERATED)))
        for name in written:
            committed = os.path.join(HERE, name + '.c')
            if not os.path.exists(committed): bad.append(name + ': not committed'); continue
            if open(committed, 'rb').read() != open(os.path.join(outdir, name + '.c'), 'rb').read(): bad.append(name + ': differs from the committed file')
        if bad:
            print('generate.py: CHECK FAILED -- ' + '; '.join(bad)); rc = 1
            args.keep_work = True; print('generate.py: the emitted programs are kept in ' + outdir)
        else:
            print('generate.py: CHECK OK (%d programs, %d expressions: each emitted file is byte-identical to the committed one)' % (len(written), sum(written.values())))
    if not args.keep_work: shutil.rmtree(work)
    return rc

if __name__ == '__main__':
    sys.exit(main())
