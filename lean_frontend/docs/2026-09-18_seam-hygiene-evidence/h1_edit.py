#!/usr/bin/env python3
"""H1 seam edit — `panic!` -> `failwithI` at the hand-written seam sites (charter
2026-09-18_charter-seam-hygiene.md §2 H1). Fail-closed: every target line must
contain exactly one `panic!` token and, where a prefix is added, the expected
message opening; any mismatch aborts BEFORE writing anything.

Per-site decisions ([AGENT], one line each — the record carries the table):
  swap        the token only; message byte-identical (it already names its site
              in the OCaml `Module.fn:` / `fn:` form or the CerbFS refusal form)
  prefix P    the token, and the message gains the self-locating prefix P because
              it named no site (the panic line loses `PANIC at <site>` when the
              site moves to LemLib.failwithIImpl)
  KEEP        listed here for completeness, NOT edited
"""
import re, sys
from pathlib import Path

ROOT = Path('/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/seam-hygiene/lean_frontend')

# (line, prefix-or-None) per file; lines are 1-based on the charter-head tree.
PLAN = {
 'CerbDecode.lean': [(41,None),(121,None),(127,None),(132,None),(144,None),(146,None),(151,None)],
 'CerbLocation.lean': [(133,None),(239,'CerbLocation.simpleLocation: ')],
 'CerbFS.lean': [(l,None) for l in (229,234,240,253,260,282,295,309,325,338,342,348,356,369,379,392,397,
                                    413,416,419,422,425,428,431,445,448,456,469,486,495,504,507,510,513,516,519)],
 'CerbFloat.lean': [(302,None),(426,None)],
 'CerberusImpl.lean': [(142,None),(179,None),(181,None)],   # line 69 typeof_enum_impl: KEEP (forbidden enum seam)
 'CerbUtils.lean': [(136,None),(146,None),(155,None),(172,None)],
 'CerbMem.lean': [
   (280,None),(281,None),
   (336,'CerbMem.targetPtrSize: '),
   (421,None),(449,None),(450,None),(452,None),
   (456,'CerbMem.sizeofCtype: '),(460,'CerbMem.sizeofCtype: '),
   (484,None),(502,None),(504,None),
   (508,'CerbMem.alignofCtype: '),(512,'CerbMem.alignofCtype: '),
   (527,None),(537,None),
   (604,'CerbMem.intToBytes: '),
   (619,None),(620,None),(660,None),
   (706,'CerbMem.memValueToBytes: '),(718,'CerbMem.memValueToBytes: '),
   (828,'CerbMem.memValueToBytes_append: '),(837,'CerbMem.memValueToBytes_append: '),
   (1051,'CerbMem.reconstructValue: '),(1120,None),(1130,None),(1134,None),
   (1190,'CerbMem.reconstructValue_indexed: '),(1229,None),(1237,None),(1241,None),
   (1305,None),
   (1385,'CerbMem.casePtrval: '),
   (1419,'CerbMem.maxIval: '),(1428,None),
   (1447,'CerbMem.minIval: '),(1449,None),
   (1460,'CerbMem.concurReadIval: '),
   (1541,None),(1557,None),
   (1730,None),(1732,'CerbMem.arrayShiftPtrval: '),(1733,None),
   (1756,None),(1768,None),(1776,None),
   (1995,None),(1997,None),(1999,None),(2001,None),(2003,None),(2005,None)],
 'CoreParser.lean': [(2413,None)],
 # Main.lean:70 `| .error e => panic! e` — the message IS the variable; handled specially below
}
MAIN_SPECIAL = ('Main.lean', 70, '| .error e => panic! e', '| .error e => failwithI s!"Main.loadCoreImpl: {e}"')

def main():
    edits = {}
    problems = []
    for fname, sites in PLAN.items():
        text = (ROOT/fname).read_text().split('\n')
        new = list(text)
        for (ln, prefix) in sites:
            line = text[ln-1]
            if line.count('panic!') != 1:
                problems.append(f'{fname}:{ln}: expected exactly one panic!, got {line.count("panic!")}: {line.strip()[:100]}'); continue
            if prefix is None:
                new[ln-1] = line.replace('panic!', 'failwithI', 1)
            else:
                m = re.search(r'panic! (s!)?"', line)
                if not m:
                    problems.append(f'{fname}:{ln}: prefix site without a string literal opening: {line.strip()[:100]}'); continue
                interp = m.group(1) or ''
                new[ln-1] = line[:m.start()] + f'failwithI {interp}"{prefix}' + line[m.end():]
        edits[fname] = '\n'.join(new)
    # Main.lean special
    fname, ln, old, repl = MAIN_SPECIAL
    text = (ROOT/fname).read_text().split('\n')
    if old not in text[ln-1]:
        problems.append(f'{fname}:{ln}: expected `{old}`, got: {text[ln-1].strip()[:100]}')
    else:
        text[ln-1] = text[ln-1].replace(old, repl, 1); edits[fname] = '\n'.join(text)
    if problems:
        print('ABORT — no file written:'); print('\n'.join(problems)); sys.exit(1)
    for fname, content in edits.items():
        (ROOT/fname).write_text(content)
    n = sum(len(v) for v in PLAN.values()) + 1
    print(f'h1_edit: {n} sites edited across {len(edits)} files ' +
          f'({sum(1 for v in PLAN.values() for _,p in v if p)} + 1 (Main) with a self-locating prefix)')

if __name__ == '__main__': main()
