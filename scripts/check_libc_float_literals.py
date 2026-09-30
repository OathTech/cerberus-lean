#!/usr/bin/env python3
"""check_libc_float_literals.py — the float-literal inventory of the pinned libc dump
(named-deviation register N3, VALIDATION.md §2b; bug hunt BUG-5, 2026-09-30).

tests/libc/libc.core is the oracle's Core pretty-printer output, which prints floats with
%.12g (ocaml_frontend/pprinters/pp_core.ml:279-282), so a double needing more than 12
significant digits is rounded in the text Lean parses. This check pins the complete set of
float literals in the dump to the reviewed register scripts/libc_float_literals.txt, both
directions (line, literal, disposition), so a re-pinned dump that adds, drops or moves a
literal fails until it is reviewed. A literal printed with the printer's full 12
significant digits may have been rounded: it must be registered LOSSY-N3 or EXACT-VERIFIED
(with the reason in the register's note column), never plain EXACT-BY-SOURCE.

Usage: check_libc_float_literals.py [--selftest]   (fail-closed; exit 0 only on agreement)
"""
import re, sys, tempfile, os, shutil, subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DUMP = os.path.join(ROOT, "tests/libc/libc.core")
REG = os.path.join(ROOT, "scripts/libc_float_literals.txt")
LIT = re.compile(r'(?<![\w.])([0-9]+\.[0-9]*(?:[eE][+-]?[0-9]+)?|[0-9]+[eE][+-]?[0-9]+)(?![\w.])')
DISPOSITIONS = {"EXACT-BY-SOURCE", "EXACT-VERIFIED", "LOSSY-N3"}

def census(path):
    out = []
    with open(path, encoding="utf-8") as f:
        for i, line in enumerate(f, 1):
            for m in LIT.finditer(line):
                out.append((i, m.group(1)))
    return out

def sig_digits(lit):
    mant = re.split(r'[eE]', lit)[0].replace('.', '').lstrip('0')
    return len(mant.rstrip('0')) if mant else 0

def load_register(path):
    rows = []
    with open(path, encoding="utf-8") as f:
        for n, line in enumerate(f, 1):
            if not line.strip() or line.startswith('#'):
                continue
            parts = line.rstrip('\n').split('\t')
            if len(parts) < 3 or not parts[0].isdigit() or parts[2] not in DISPOSITIONS:
                raise SystemExit(f"check_libc_float_literals: FAIL — malformed register row {n}: {line.rstrip()!r}")
            rows.append((int(parts[0]), parts[1], parts[2]))
    return rows

def check(dump, reg):
    errs = []
    live = census(dump)
    rows = load_register(reg)
    if not live:
        errs.append("the dump has no float literals at all (vacuous census — wrong file or broken regex)")
    have = {(l, t) for l, t in live}
    want = {(l, t) for l, t, _ in rows}
    for l, t in sorted(have - want):
        errs.append(f"unregistered literal {t!r} at line {l}")
    for l, t in sorted(want - have):
        errs.append(f"registered literal {t!r} at line {l} is not in the dump")
    for l, t, d in rows:
        if sig_digits(t) >= 12 and d == "EXACT-BY-SOURCE":
            errs.append(f"line {l} {t!r} has 12 significant digits (possibly rounded by %.12g) but is registered EXACT-BY-SOURCE")
    return errs, len(live), sum(1 for r in rows if r[2] == "LOSSY-N3")

def selftest():
    tmp = tempfile.mkdtemp(prefix="libcfloat.")
    try:
        ok = True
        dump_lines = open(DUMP, encoding="utf-8").read().split('\n')
        reg_text = open(REG, encoding="utf-8").read()
        def run(name, dump_lines_, reg_text_, expect_fail):
            nonlocal ok
            d = os.path.join(tmp, "d.core"); r = os.path.join(tmp, "r.txt")
            open(d, "w", encoding="utf-8").write('\n'.join(dump_lines_))
            open(r, "w", encoding="utf-8").write(reg_text_)
            try:
                errs, _, _ = check(d, r)
            except SystemExit:
                errs = ["malformed"]
            failed = bool(errs)
            if failed != expect_fail:
                ok = False
                print(f"check_libc_float_literals: SELFTEST FAIL — plant {name!r}: expected {'FAIL' if expect_fail else 'OK'}, got {errs or 'OK'}")
        run("unplanted", dump_lines, reg_text, False)
        planted = list(dump_lines); planted[0] = planted[0] + " 2.5"
        run("added literal", planted, reg_text, True)
        run("dropped literal", [l.replace("1000000000.", "1000000000") for l in dump_lines], reg_text, True)
        run("lossy row relabelled EXACT-BY-SOURCE", dump_lines, reg_text.replace("LOSSY-N3", "EXACT-BY-SOURCE"), True)
        run("empty dump", [""], reg_text, True)
        run("malformed register", dump_lines, reg_text + "x\ty\tMAYBE\n", True)
        if ok:
            print("check_libc_float_literals: SELFTEST OK (6 plants: unplanted OK; added, dropped, relabelled-lossy, empty dump, malformed register all FAIL)")
        return ok
    finally:
        shutil.rmtree(tmp)

def main():
    if "--selftest" in sys.argv[1:]:
        sys.exit(0 if selftest() else 1)
    errs, n, lossy = check(DUMP, REG)
    if errs:
        print("check_libc_float_literals: FAIL —")
        for e in errs:
            print("  " + e)
        sys.exit(1)
    print(f"check_libc_float_literals: OK ({n} float literals in tests/libc/libc.core = the register exactly; {lossy} LOSSY-N3)")

if __name__ == "__main__":
    main()
