#!/usr/bin/env python3
"""AUDITOR: every line inside a ``` fence of the record must exist verbatim (modulo `…` elisions, which
must match as ordered substrings of ONE evidence line) in some file of the evidence directory, or in the
range's own tracked files for code fences (the OCaml diff, the theorem statement)."""
import re, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
rec = (ROOT / 'lean_frontend/docs/2026-09-16_allocator-soundness-address-bound-record.md').read_text().splitlines()
ev = ROOT / 'lean_frontend/docs/2026-09-16_allocator-soundness-address-bound-evidence'
hay = []
for p in sorted(ev.glob('*')):
    hay += [(p.name, l) for l in p.read_text(errors='replace').splitlines()]
extra_files = ['lean_frontend/CerbMemAllocatorProofs.lean', 'memory/concrete/impl_mem.ml', 'memory/vip/impl_mem.ml']
for f in extra_files:
    hay += [(f, l) for l in (ROOT / f).read_text().splitlines()]
def found(line):
    parts = [p.strip() for p in line.split('…') if p.strip()]
    if not parts: return True, None
    for name, h in hay:
        pos = 0; ok = True
        for part in parts:
            j = h.find(part, pos)
            if j < 0: ok = False; break
            pos = j + len(part)
        if ok: return True, name
    return False, None
infence = False; quoted = 0; missing = []
for i, l in enumerate(rec, 1):
    if l.strip().startswith('```'):
        infence = not infence; continue
    if infence and l.strip():
        quoted += 1
        ok, where = found(l.strip())
        if not ok: missing.append((i, l.strip()[:140]))
print(f'fenced lines checked: {quoted}; missing from evidence dir (+ the three source files): {len(missing)}')
for i, l in missing: print(f'  MISSING record:{i}: {l}')
# the prose-embedded runner lines "PASSED A1 (160.1s)" etc.
runner = re.findall(r'`((?:A\d+[bc]?|B\d+(?:\.\d+)?) \(\d+\.\d+s\))`', '\n'.join(rec))
miss2 = [r for r in runner if not any(('PASSED ' + r) in h for _, h in hay)]
print(f'runner timing tokens in prose: {len(runner)}; not found as "PASSED <tok>" in evidence: {len(miss2)} {miss2}')
# provenance tags
txt = '\n'.join(rec)
print('[USER] tags:', len(re.findall(r'\[USER', txt)), ' [AGENT] tags:', len(re.findall(r'\[AGENT', txt)))
print('errata listed:', sorted(set(re.findall(r'\*\*E(\d+) ', txt)), key=int))
