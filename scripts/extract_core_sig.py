#!/usr/bin/env python3
"""Extract a SIGNATURE-level summary from OCaml `cerberus --pp core` output
(arc-4 S4, test_elab.sh helper).

Emits the same canonical line format as the Lean pipeline's `--pp-core`
mode (lean_frontend/Main.lean, ppCoreSignature):

    tagdef struct <name> members=<m1,m2,...>
    tagdef union <name> members=<...>
    glob <name>
    fun <name> arity=<n>
    proc <name> arity=<n>
    procdecl <name> arity=<n>       (OCaml prints these as `proc n (tys)`,
                                     no `: eff` / no body)
    builtin <name> arity=<n>

GRANULARITY LIMITATION (prominent, deliberate): only declaration names,
kinds, arities and aggregate member names are extracted — NOT bodies.
The Lean pipeline has no real Core pretty-printer (CerbPP is
placeholders), and building one is out of scope for this slice, so the
elaborated-Core differential bottoms out at this signature level.

Parsing notes (against ocaml_frontend/pprinters/pp_core.ml):
  - `pp_cond` means OCaml only prints procs/tagdefs whose location is in
    the main file; header-defined ones are absent from its output.
  - GlobalDecl entries print nothing (pp_globs), so `glob` covers
    GlobalDef only — matching the Lean dump.
  - Parameter lists may wrap across lines; we scan for the balanced
    closing paren.
  - ANSI color codes are stripped first (pp colors symbols when on a TTY).

Self-test: `extract_core_sig.py --self-test`.
"""
import re
import sys

ANSI = re.compile(r'\x1b\[[0-9;]*m')
NAME = r'[A-Za-z_$][A-Za-z0-9_$]*'
RE_GLOB = re.compile(rf'^glob\s+({NAME})\s*:')
RE_FUN = re.compile(rf'^(fun|proc|builtin)\s+({NAME})\s*\(')
RE_TAGDEF = re.compile(rf'^def\s+(struct|union)\s+({NAME})\s*:=')
RE_MEMBER = re.compile(rf'^\s+({NAME})\s*:')


def top_level_arity(params: str) -> int:
    """Number of top-level comma-separated items in a param list body
    (balanced over parens/brackets); empty/whitespace body = 0."""
    if params.strip() == '':
        return 0
    depth = 0
    count = 1
    for ch in params:
        if ch in '([':
            depth += 1
        elif ch in ')]':
            depth -= 1
        elif ch == ',' and depth == 0:
            count += 1
    return count


def scan_balanced(lines: list[str], i: int, start_col: int):
    """From lines[i][start_col] == '(', collect the paren-balanced body
    (possibly spanning lines). Returns (body, line_index_of_close, rest_of_line)."""
    depth = 0
    body = []
    li = i
    ci = start_col
    while li < len(lines):
        line = lines[li]
        while ci < len(line):
            ch = line[ci]
            if ch == '(':
                depth += 1
                if depth == 1:
                    ci += 1
                    continue
            elif ch == ')':
                depth -= 1
                if depth == 0:
                    return ''.join(body), li, line[ci + 1:]
            body.append(ch)
            ci += 1
        body.append(' ')
        li += 1
        ci = 0
    raise ValueError('unbalanced parameter list in pp core output')


def extract(text: str) -> list[str]:
    text = ANSI.sub('', text)
    lines = text.split('\n')
    out: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        m = RE_GLOB.match(line)
        if m:
            out.append(f'glob {m.group(1)}')
            i += 1
            continue
        m = RE_TAGDEF.match(line)
        if m:
            kind, name = m.group(1), m.group(2)
            members = []
            j = i + 1
            while j < len(lines):
                mm = RE_MEMBER.match(lines[j])
                if not mm:
                    break
                members.append(mm.group(1))
                j += 1
            out.append(f'tagdef {kind} {name} members={",".join(members)}')
            i = j
            continue
        m = RE_FUN.match(line)
        if m:
            kw, name = m.group(1), m.group(2)
            open_col = line.index('(', m.start(0) + len(kw))
            body, li, rest = scan_balanced(lines, i, open_col)
            arity = top_level_arity(body)
            if kw == 'proc':
                # Proc with body: `proc n (...): eff ... :=`; bodiless
                # ProcDecl: `proc n (tys)` with nothing after the paren.
                kind = 'proc' if ':' in rest else 'procdecl'
            else:
                kind = kw  # fun | builtin
            out.append(f'{kind} {name} arity={arity}')
            i = li + 1
            continue
        i += 1
    return out


def self_test() -> None:
    sample = """-- Aggregates
def struct Point :=
  x: 'signed int'
  y: 'signed int'

-- Globals
glob g: pointer [ail_ctype = 'signed int'] :=
  let strong a_487: pointer = create(Ivalignof('signed int'), 'signed int') in
  pure(a_487)

-- Fun map
proc add (a: pointer, b: pointer): eff loaded integer :=
  pure(Unit)

fun pair_thing (p: (loaded integer, loaded integer)): integer :=
  pure(0)

proc undefined_fn (integer, integer)

builtin bswap (integer)

proc main (): eff loaded integer :=
  pure(Unit)

proc wrapped (a: pointer,
    b: pointer): eff loaded integer :=
  pure(Unit)
"""
    got = extract(sample)
    want = [
        'tagdef struct Point members=x,y',
        'glob g',
        'proc add arity=2',
        'fun pair_thing arity=1',
        'procdecl undefined_fn arity=2',
        'builtin bswap arity=1',
        'proc main arity=0',
        'proc wrapped arity=2',
    ]
    assert got == want, f'\n got: {got}\nwant: {want}'
    print('extract_core_sig: self-test OK')


if __name__ == '__main__':
    if '--self-test' in sys.argv:
        self_test()
    else:
        for line in extract(sys.stdin.read()):
            print(line)
