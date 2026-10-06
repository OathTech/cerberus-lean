#!/usr/bin/env python3
"""gen_fuel_parametricity.py — the fuel-parametricity pin list of
lean_frontend/test/Unit/TotalityProofTest.lean Part 1, derived from the
generated tree (fuel-parameter arc C1; pre-merge audit M1: the list must not
be a static snapshot with an uncommitted generator).

For every AMBIENT fuel wrapper in lean_frontend/generated/ — a line
`def f <binders> [LemFuel] : T := f_lemFuel LemFuel.fuel` (head possibly over several lines) in a generated
(non-seam) module — emit `example <binders> (n : Nat) : @f <args> =
@f_lemFuel <args> n := rfl`. The instance arguments follow each head's own
instance binders IN BINDER ORDER (PNVI arc S1, 2026-10-05: a function that
also reads the switch set binds `[LemFuel] [CerbGlobal.Switches]`): `⟨n⟩`
stands at every `[LemFuel]` position — on the right only when the worker
itself binds `[LemFuel]` (it passes the ambient on) — and every other class
instance is a bound variable `iK` of the example, shared by the wrapper and
its worker and matched BY CLASS. A worker that binds a class its wrapper does
not is a FAIL (fail-closed; plant E1 of --selftest). Binders are read from
the generated heads, so a drift in a wrapper's binders fails the test's
build; THIS script's --check makes a drift in the wrapper SET fail
test_unit.sh: the set of wrapper names in the tree must equal the set pinned
in TotalityProofTest.lean, both directions (a new fuel'd function without a
pin, or a pin whose function is gone, is RED). Measured wrappers
(`f_lemFuel (t.lemSize x) …`) are not ambient and are not listed — their
fuel-freedom is pinned by their sufficiency obligations instead.

Shape cross-check (pre-merge audit A5 of the lem re-pin to 4e70bb5,
2026-10-04 [AGENT]; docs/2026-10-04_lem-repin-4e70bb5-pre-merge-audit.md):
the wrapper regex is literal about the right-hand side (`f_lemFuel LemFuel.fuel`,
one space, at end of line) and about the head (`^def`), so a wrapper laid out
differently was silently NOT counted (audit plants G2 RHS broken over lines,
G3 double space, G6 `@[inline] def`). Every `LemFuel.fuel` token outside
comments (failure_census.strip_comments; strings kept, so such a token in a
string is counted too) of a non-seam generated module must lie inside the
right-hand side of a counted wrapper, and every counted wrapper must hold one;
otherwise FAIL naming file:line. Plant-tested by --selftest.

Usage:
  gen_fuel_parametricity.py --emit      print the Part 1 block (paste into the test)
  gen_fuel_parametricity.py --check     compare the tree's wrapper set with the test's pins; exit 1 on drift
  gen_fuel_parametricity.py --selftest  plants on scratch copies of the generated tree (G*: --check; E*: --emit),
                                        then --check and --emit on the real one
"""
import re, sys, os, glob, shutil, tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from failure_census import strip_comments

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
LF = os.path.join(ROOT, 'lean_frontend')
TEST = os.path.join(LF, 'test', 'Unit', 'TotalityProofTest.lean')

def seam_names():
    with open(os.path.join(LF, 'handwritten_copy.manifest')) as fh:
        return {l.strip() for l in fh if l.strip() and not l.startswith('#')}

def wrappers(gen=os.path.join(LF, 'generated')):
    """(module, name, wrapper-binders, worker-binders) for every ambient wrapper —
    the binder texts of both heads (the worker's up to its `(lemFuel : Nat)`), from
    which emit() reads the instance binders in order (PNVI arc S1)."""
    rows = []
    seams = seam_names()
    for f in sorted(glob.glob(os.path.join(gen, '*.lean'))):
        b = os.path.basename(f)
        if b in seams:
            continue
        t = open(f).read()
        try:
            clean = strip_comments(t)
        except ValueError as e:
            sys.exit(f"gen_fuel_parametricity: FAIL — {b}: comment stripper: {e} (fail-closed)")
        # Shape cross-check (A5): the tolerant candidates are all `LemFuel.fuel`
        # tokens outside comments; each must sit in a counted wrapper's RHS.
        cands = [c.start() for c in re.finditer(r"(?<![\w.'])LemFuel\.fuel(?![\w'])", clean)]
        spans = []
        # The type may span lines (lem's layout engine breaks long heads since the
        # re-pin to 4e70bb5, 2026-10-04 [AGENT]; record docs/2026-10-04_lem-repin-4e70bb5-record.md);
        # it may not contain `:=`, so a match never crosses into another definition.
        for m in re.finditer(r'^def\s+(\w+)\s+((?:\{[^}]*\}\s*|\[[^\]]*\]\s*)*):\s*((?:(?!:=)[\s\S])*?)\s*:=\s*(\w+)_lemFuel LemFuel\.fuel[ \t]*$', t, re.M):
            name, binders = m.group(1), m.group(2)
            if m.group(4) != name:
                sys.exit(f"gen_fuel_parametricity: {b}: wrapper {name} applies {m.group(4)}_lemFuel — unexpected shape")
            w = re.search(r'^\s*def\s+' + re.escape(name) + r'_lemFuel\s+((?:(?!:=)[\s\S])*?)\(lemFuel : Nat\)', t, re.M)
            if not w:
                sys.exit(f"gen_fuel_parametricity: {b}: no worker head for {name}")
            rows.append((b[:-5], name, binders, w.group(1)))
            spans.append((name, m.start(4), m.end()))
        line = lambda k: t.count('\n', 0, k) + 1
        stray = [k for k in cands if not any(a <= k < e for _, a, e in spans)]
        empty = [(nm, a) for nm, a, e in spans if not any(a <= k < e for k in cands)]
        if stray or empty:
            msg = [f"{b}:{line(k)}: `LemFuel.fuel` outside the right-hand side of any counted wrapper (a wrapper in a shape the strict pattern does not read?)" for k in stray]
            msg += [f"{b}:{line(a)}: counted wrapper {nm} has no `LemFuel.fuel` outside comments" for nm, a in empty]
            sys.exit("gen_fuel_parametricity: FAIL — wrapper shape cross-check: tolerant candidates "
                     f"({len(cands)}) != strictly counted wrappers ({len(spans)}) in {b}:\n  " + "\n  ".join(msg))
    if len(rows) < 10:
        sys.exit(f"gen_fuel_parametricity: only {len(rows)} wrappers found — is lean_frontend/generated regenerated? (vacuity guard)")
    return rows

def parse_binders(bs):
    out = []
    for m in re.finditer(r'\{([^}]*)\}|\[([^\]]*)\]', bs):
        if m.group(1) is not None:
            names, ty = m.group(1).split(':')
            out.append(('impl', [x for x in names.split() if x], ty.strip()))
        else:
            out.append(('inst', m.group(2).strip()))
    return out

def emit(rows):
    # Instance binders are emitted IN BINDER ORDER (PNVI arc S1, 2026-10-05: a worker
    # that also reads the switch set binds `[LemFuel] [CerbGlobal.Switches]`, the
    # instance reader after the fuel — lem-lean instance-reader record §2 "Binder
    # order"); `⟨n⟩` stands at the `[LemFuel]` position, every other class instance
    # is a bound variable `iK` shared by the wrapper and its worker (matched by class).
    lines = [f"-- {len(rows)} ambient wrappers (generated by scripts/gen_fuel_parametricity.py --emit from the generated tree; scripts/gen_fuel_parametricity.py --check pins this SET in test_unit.sh)"]
    for mod, name, wb, workerb in rows:
        parsed = parse_binders(wb)
        tys = [n for x in parsed if x[0] == 'impl' for n in x[1]]
        btxt = ''
        if tys:
            btxt += ' {' + ' '.join(tys) + ' : Type}'
        inst_name = {}
        largs = list(tys)
        for x in parsed:
            if x[0] != 'inst':
                continue
            if x[1] == 'LemFuel':
                largs.append('⟨n⟩')
            else:
                nm = f'i{len(inst_name)+1}'; inst_name[x[1]] = nm
                btxt += f' [{nm} : {x[1]}]'; largs.append(nm)
        rargs = list(tys)
        for x in parse_binders(workerb):
            if x[0] != 'inst':
                continue
            if x[1] == 'LemFuel':
                rargs.append('⟨n⟩')
            elif x[1] in inst_name:
                rargs.append(inst_name[x[1]])
            else:
                sys.exit(f"gen_fuel_parametricity: {mod}: worker {name}_lemFuel binds [{x[1]}], which its wrapper does not (fail-closed)")
        rargs.append('n')
        lhs = f'@{name} ' + ' '.join(largs)
        rhs = f'@{name}_lemFuel ' + ' '.join(rargs)
        lines.append(f'example{btxt} (n : Nat) : {lhs} = {rhs} := rfl')
    return '\n'.join(lines)

def pinned():
    t = open(TEST).read()
    return set(re.findall(r'^example.*?:\s*@(\w+)(?:\s+[^⟨=]*)?⟨n⟩[^=]*=\s*@\1_lemFuel\b', t, re.M))

def check(gen=os.path.join(LF, 'generated')):
    rows = wrappers(gen)
    tree = {r[1] for r in rows}
    pins = pinned()
    missing = sorted(tree - pins); stale = sorted(pins - tree)
    if missing or stale:
        if missing:
            print("gen_fuel_parametricity: FAIL — fuel'd wrapper(s) in the tree with NO parametricity pin in TotalityProofTest.lean: " + ', '.join(missing))
        if stale:
            print("gen_fuel_parametricity: FAIL — pin(s) in TotalityProofTest.lean with no wrapper in the tree: " + ', '.join(stale))
        print("  regenerate Part 1: scripts/gen_fuel_parametricity.py --emit")
        sys.exit(1)
    print(f"gen_fuel_parametricity: OK ({len(tree)} ambient fuel wrappers in the generated tree = the {len(pins)} pins of TotalityProofTest.lean Part 1, both directions)")

# (name, text appended to a scratch copy of Driver.lean, substring the FAIL must carry)
PLANTS = [
    ('G1 new multi-line wrapper (strict pattern)',
     'def plantG1_lemFuel (lemFuel : Nat) : Nat := 0\ndef plantG1 [LemFuel] :\n    Nat :=\n  plantG1_lemFuel LemFuel.fuel\n',
     "NO parametricity pin in TotalityProofTest.lean: plantG1"),
    ('G2 RHS broken over lines',
     'def plantG2_lemFuel (lemFuel : Nat) : Nat := 0\ndef plantG2 [LemFuel] : Nat :=\n  plantG2_lemFuel\n    LemFuel.fuel\n',
     "outside the right-hand side of any counted wrapper"),
    ('G3 double space in the RHS',
     'def plantG3_lemFuel (lemFuel : Nat) : Nat := 0\ndef plantG3 [LemFuel] : Nat := plantG3_lemFuel  LemFuel.fuel\n',
     "outside the right-hand side of any counted wrapper"),
    ('G6 attribute before def',
     'def plantG6_lemFuel (lemFuel : Nat) : Nat := 0\n@[inline] def plantG6 [LemFuel] : Nat := plantG6_lemFuel LemFuel.fuel\n',
     "outside the right-hand side of any counted wrapper"),
    ('G7 RHS in parentheses',
     'def plantG7_lemFuel (lemFuel : Nat) : Nat := 0\ndef plantG7 [LemFuel] : Nat := plantG7_lemFuel (LemFuel.fuel)\n',
     "outside the right-hand side of any counted wrapper"),
    ('G8 counted wrapper inside a block comment',
     'def plantG8_lemFuel (lemFuel : Nat) : Nat := 0\n/-\ndef plantG8 [LemFuel] : Nat := plantG8_lemFuel LemFuel.fuel\n-/\n',
     "counted wrapper plantG8 has no `LemFuel.fuel` outside comments"),
]

# (name, text appended to a scratch copy of Driver.lean, substring the --emit FAIL must carry)
# — the emit-side fail-closed branch (pre-merge audit L4, 2026-10-06)
EMIT_PLANTS = [
    ('E1 worker binds an instance class its wrapper does not',
     'def plantE1_lemFuel [LemFuel] [CerbGlobal.Switches] (lemFuel : Nat) : Nat := 0\n'
     'def plantE1 [LemFuel] : Nat := plantE1_lemFuel LemFuel.fuel\n',
     "worker plantE1_lemFuel binds [CerbGlobal.Switches], which its wrapper does not (fail-closed)"),
]

def selftest():
    import io, contextlib
    gen = os.path.join(LF, 'generated')
    drv = os.path.join(gen, 'Driver.lean')
    if not os.path.isfile(drv):
        sys.exit("gen_fuel_parametricity: SELFTEST FAILED — no generated/Driver.lean to plant on")
    print("gen_fuel_parametricity: SELFTEST — planting on scratch copies of generated/Driver.lean (loud plant banner; nothing in the tree is touched)")
    fail = 0
    work = tempfile.mkdtemp(prefix='fuelparam-plant.')
    try:
        for name, text, needle in PLANTS + [('control: unplanted scratch copy', '', None)]:
            sg = os.path.join(work, 'gen'); shutil.rmtree(sg, ignore_errors=True); os.mkdir(sg)
            for f in glob.glob(os.path.join(gen, '*.lean')):
                if os.path.basename(f) != 'Driver.lean':
                    os.symlink(f, os.path.join(sg, os.path.basename(f)))
            with open(drv) as src, open(os.path.join(sg, 'Driver.lean'), 'w') as dst:
                dst.write(src.read() + '\n' + text)
            buf = io.StringIO(); rc = 0
            try:
                with contextlib.redirect_stdout(buf):
                    check(sg)
            except SystemExit as e:
                rc = 1; buf.write(str(e.code) if e.code not in (None, 1) else '')
            out = buf.getvalue()
            ok = (rc == 0 and 'OK (14 ' in out) if needle is None else (rc == 1 and needle in out)
            first = next((l for l in out.splitlines() if (needle or 'OK') in l), out.splitlines()[0] if out else '')
            print(f"  PLANT {'OK  ' if ok else 'FAIL'} [{name}] rc={rc} -> {first.strip()}")
            if not ok:
                print('    ' + out.replace('\n', '\n    '), file=sys.stderr); fail = 1
        for name, text, needle in EMIT_PLANTS + [('emit control: unplanted scratch copy', '', None)]:
            sg = os.path.join(work, 'gen'); shutil.rmtree(sg, ignore_errors=True); os.mkdir(sg)
            for f in glob.glob(os.path.join(gen, '*.lean')):
                if os.path.basename(f) != 'Driver.lean':
                    os.symlink(f, os.path.join(sg, os.path.basename(f)))
            with open(drv) as src, open(os.path.join(sg, 'Driver.lean'), 'w') as dst:
                dst.write(src.read() + '\n' + text)
            rc, out = 0, ''
            try:
                out = emit(wrappers(sg))
            except SystemExit as e:
                rc, out = 1, str(e.code)
            ok = (rc == 0 and out.startswith('-- 14 ambient wrappers')) if needle is None else (rc == 1 and needle in out)
            first = out.splitlines()[0] if out else ''
            print(f"  PLANT {'OK  ' if ok else 'FAIL'} [{name}] rc={rc} -> {first.strip()}")
            if not ok:
                print('    ' + out.replace('\n', '\n    '), file=sys.stderr); fail = 1
    finally:
        shutil.rmtree(work)
    print("  REVERTED (real tree):")
    try:
        check()
        n_emit = len(emit(wrappers()).splitlines()) - 1
        print(f"gen_fuel_parametricity: --emit on the real tree OK ({n_emit} examples)")
    except SystemExit:
        fail = 1
    if fail:
        sys.exit("gen_fuel_parametricity: SELFTEST FAILED")
    print(f"gen_fuel_parametricity: SELFTEST OK ({len(PLANTS)} --check plants + {len(EMIT_PLANTS)} --emit plant with the declared FAIL, both unplanted controls OK, real tree OK)")

def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else ''
    if mode == '--emit':
        print(emit(wrappers())); return
    if mode == '--check':
        check(); return
    if mode == '--selftest':
        selftest(); return
    sys.exit(__doc__)

if __name__ == '__main__':
    main()
