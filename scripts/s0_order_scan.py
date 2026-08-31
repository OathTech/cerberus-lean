#!/usr/bin/env python3
# s0_order_scan.py — effect-retirement S0 (charter §3.6/§8.1 item i):
# the Q1b order-movement corpus scanner.
#
# Provenance: [AGENT] S0 slice deliverable, arc/effect-retirement
# (design note: lean_frontend/docs/2026-08-31_effect-retirement-design.md;
# S0 record: lean_frontend/docs/2026-08-31_S0-scan-record.md — READ IT:
# the calibration probes behind every detection rule are recorded there,
# including the S0-F1 finding that the movement class is BROADER than
# the charter's single site).
#
# What it does: for each input TU, runs the ORACLE's post-desugar
# pretty-print (--pp=ail; typedefs resolved, macros expanded, `for`
# already lowered to block+while, static locals hoisted out) and
# detects, per EAGER ELABORATION REGION:
#
#   region := a function body or a control-substatement block
#             (if/else/while/do/switch body), extended transitively
#             through PLAIN nested blocks (calibration: plain blocks
#             are constructed eagerly with their parent — AilSblock's
#             `E.mapM self ss` + eager `with_block_objects` argument;
#             control substatements are constructed at their parent
#             statement's RUN — cal2_nestif vs cal2_nestblock).
#
#   D1 (charter-narrow trigger, Q1b as ruled): the region contains
#       >=1 const-qualified OBJECT declaration (a block bind with
#       qs.const=true — mints a const-alias sym at with_block_objects
#       run time; calibration cal9/cal10: scalars, arrays and
#       `* const` pointers mint; pointee-const `const T *` does NOT)
#       AND >=1 while/do statement (the only statement forms with
#       construct-time draws — calibration cal_*/cal2_*: expression,
#       assignment, call, if, return, cast, switch statements draw
#       NOTHING at construct time; while draws sym_loop + the
#       do_loop_wrp bind head; do draws sym_loop/sym_case/sym_e).
#
#   D2 (witnessed lower bound of the BROADER movement class, finding
#       S0-F1): the region contains a while/do preceded by any other
#       statement, or >=2 while/do. Under the eager-mapM decoupling
#       (state.lem:58-59 `mapM f = listM (List.map f)`) every such
#       region's construct-time draw batch reorders against run-time
#       draws when m1 maps all draws to run order — const decls are
#       NOT required for movement.
#
# Precision statement (honest, per the S0 charter):
#   - OVERAPPROXIMATIONS (allowed): D1 counts a const decl and a
#     while/do anywhere in the same region without checking their
#     relative dynamic positions; `*const` detection may hit inner
#     pointer levels (`T *const *p`); string literals containing
#     "while (" inside statements would count.
#   - Known exactness: qualifier analysis runs on the ORACLE's OWN
#     desugared output, so typedef-carried and macro-carried const
#     cannot be missed (the raw-C underapproximation hazard).
#   - NOT covered (documented): TUs the oracle cannot desugar are
#     reported as ERROR, never silently skipped (fail-noisy).
#
# Usage:
#   s0_order_scan.py --cerb <path-to-cerberus-wrapper> \
#       [--flags "--nolibc -I ..."] [--label NAME] file.c [file2.c ...]
# Output: TSV  label file status D1 D2 loops consts regions_hit
# Exit: 0 if all files scanned (regardless of hits); 2 if any ERROR.

import argparse
import re
import subprocess
import sys

TYPEISH = re.compile(
    r'^\s*(register\s+)?(const|volatile|signed|unsigned|_Bool|_Atomic'
    r'|char|short|int|long|float|double|struct|union|enum)\b')
CONST_TOK = re.compile(r'\bconst\b')
PTR_CONST = re.compile(r'\*\s*const\b')
LABEL = re.compile(r'^\s*(\w+|case\s+[^:]+|default)\s*:\s*$')


def strip_parens(s: str) -> str:
    out, depth = [], 0
    for ch in s:
        if ch == '(':
            depth += 1
        elif ch == ')':
            depth = max(0, depth - 1)
        elif depth == 0:
            out.append(ch)
    return ''.join(out)


def is_const_object_decl(stripped: str) -> bool:
    """Object-const detection on an Ail-pp line (initializer removed)."""
    decl = stripped.split('=', 1)[0]
    if PTR_CONST.search(decl):
        return True  # `T *const p` (object-const pointer)
    noparen = strip_parens(decl)
    if '*' in noparen:
        return False  # remaining const (if any) is pointee-level
    return bool(TYPEISH.match(noparen) and CONST_TOK.search(noparen))


class Region:
    __slots__ = ('consts', 'loops', 'stmts', 'loop_after_stmt')

    def __init__(self):
        self.consts = 0
        self.loops = 0
        self.stmts = 0
        self.loop_after_stmt = False


def analyze_ail(text: str):
    """Return list of Regions for one TU's --pp=ail output."""
    regions = []
    # stack entries: (region, kind) where kind in {fn, control, plain}
    stack = []
    prev_content = ''
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith('//'):
            continue
        # closing braces first (handles `}`, `} while (...);`, `} else {`)
        working = line
        while working.startswith('}'):
            if stack:
                stack.pop()
            working = working[1:].strip()
            if working.startswith('while'):
                # do-tail `} while (cond);` — consumed, not a loop head
                working = ''
        if not working:
            prev_content = line
            continue
        opens = working.endswith('{')
        body = working[:-1].strip() if opens else working
        in_region = stack[-1][0] if stack else None
        is_loop_head = bool(re.match(r'^(while\s*\(|do\b)', body))
        if in_region is not None and not LABEL.match(body) and \
                not body.startswith('else') and body:
            # statement-ish line at region level
            if is_loop_head:
                in_region.loops += 1
                if in_region.stmts > 0 or in_region.loops >= 2:
                    in_region.loop_after_stmt = True
            in_region.stmts += 1
            if is_const_object_decl(body):
                in_region.consts += 1
        if opens:
            if not stack:
                r = Region()
                regions.append(r)
                stack.append((r, 'fn'))
            else:
                # classification context: the text before `{` on this
                # line, or (bare `{`) the previous line (e.g. switch
                # heads print their brace on the following line)
                ctx = body if body else prev_content
                control = (ctx.endswith(')') or ctx == 'do'
                           or ctx.startswith('else') or is_loop_head
                           or ctx.startswith('switch'))
                if control and body == '' and ctx.endswith((';', '}',
                                                            ':', '{')):
                    control = False
                if control:
                    r = Region()
                    regions.append(r)
                    stack.append((r, 'control'))
                else:
                    stack.append((in_region, 'plain'))
        prev_content = line
    return regions


def scan_file(cerb, flags, path, timeout, cpp=None):
    # SOUNDNESS (S0 calibration, ctypeinc.c probe): the Ail printer
    # SUPPRESSES definitions whose declarations originate in #include'd
    # files. Callers must pass --cpp with `-P` (no line markers) so all
    # tokens appear main-file-local and nothing is dropped.
    cmd = [cerb] + flags + (['--cpp=' + cpp] if cpp else []) + \
        ['--pp=ail', path]
    try:
        p = subprocess.run(cmd, capture_output=True, text=True,
                           timeout=timeout)
    except subprocess.TimeoutExpired:
        return ('TIMEOUT', 0, 0, 0, 0, 0)
    if p.returncode != 0 or not p.stdout.strip():
        return ('ERROR', 0, 0, 0, 0, 0)
    regions = analyze_ail(p.stdout)
    d1 = sum(1 for r in regions if r.consts and r.loops)
    d2 = sum(1 for r in regions if r.loop_after_stmt)
    loops = sum(r.loops for r in regions)
    consts = sum(r.consts for r in regions)
    return ('OK', d1, d2, loops, consts, len(regions))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--cerb', required=True)
    ap.add_argument('--flags', default='--nolibc')
    ap.add_argument('--cpp', default='cc -std=c11 -E -P -CC -Werror '
                    '-Wno-builtin-macro-redefined -nostdinc -undef '
                    '-D__cerb__',
                    help='cpp command (MUST keep -P; add -I dirs here)')
    ap.add_argument('--label', default='-')
    ap.add_argument('--timeout', type=int, default=60)
    ap.add_argument('files', nargs='+')
    a = ap.parse_args()
    flags = a.flags.split()
    errs = 0
    for f in a.files:
        st, d1, d2, loops, consts, regs = scan_file(
            a.cerb, flags, f, a.timeout, cpp=a.cpp)
        if st != 'OK':
            errs += 1
        print(f'{a.label}\t{f}\t{st}\tD1={d1}\tD2={d2}\tloops={loops}'
              f'\tconsts={consts}\tregions={regs}')
        sys.stdout.flush()
    sys.exit(2 if errs else 0)


if __name__ == '__main__':
    main()
