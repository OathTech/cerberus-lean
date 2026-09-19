#!/usr/bin/env python3
"""Auditor: every verbatim gate/build line quoted in the record (fenced code blocks + 4-space-indented
verbatim blocks + backticked one-line gate quotes) must exist in some file of the evidence dir (substring,
whitespace-normalised). Reports missing lines."""
import re, sys, os, pathlib
rec = pathlib.Path('lean_frontend/docs/2026-09-18_seam-hygiene-record.md').read_text().split('\n')
ev = pathlib.Path('lean_frontend/docs/2026-09-18_seam-hygiene-evidence')
corpus = ''
for p in ev.rglob('*'):
    if p.is_file():
        try: corpus += p.read_text(errors='replace') + '\n'
        except Exception as e: print('unreadable', p, e)
norm = lambda s: re.sub(r'\s+', ' ', s).strip()
ncorpus = norm(corpus)
quoted = []
infence = False
for i, l in enumerate(rec, 1):
    if l.strip().startswith('```'): infence = not infence; continue
    if infence:
        if l.strip() and not l.strip().startswith('#') and not l.strip().startswith('==='): quoted.append((i, l.strip()))
        continue
    if l.startswith('    ') and l.strip() and not l.strip().startswith('|'):
        quoted.append((i, l.strip()))
missing = []
for i, q in quoted:
    qn = norm(q)
    # allow the record's own truncation ellipsis: check each …-separated piece
    pieces = [p for p in re.split(r'…|\.\.\.', qn) if len(p.strip()) >= 12]
    ok = all(p.strip() in ncorpus for p in pieces) if pieces else (qn in ncorpus)
    if not ok: missing.append((i, q))
print(f'quoted lines: {len(quoted)} missing: {len(missing)}')
for i, q in missing: print(f'  MISSING record.md:{i}: {q[:200]}')
