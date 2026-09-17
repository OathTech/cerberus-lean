#!/usr/bin/env python3
"""Auditor's check over the WORKER'S evidence (o1-raw-diffs-*.txt): for each of the 21 deleted
register rows, every changed stderr line pair must be an OCaml backtrace frame differing only in
its position (auditor's own tokenizer, independent of the lane's FRAME_POSITION regex)."""
import re
from pathlib import Path
E = Path('lean_frontend/docs/2026-09-16_pristine-oracle-instrument-record-evidence')
deleted = [l.strip() for l in (E / 'o5-register-rows-deleted.txt').read_text().splitlines() if l.strip()]
FRAME = re.compile(r'^\s*(Raised at|Raised by primitive operation at|Called from|Re-raised at)\s+(.*?) in file "([^"]*)"( \(inlined\))?, lines? (\d+(?:-\d+)?), characters (\d+-\d+)$')
blocks = {}
for f in ('o1-raw-diffs-tray-immaculate.txt', 'o1-raw-diffs-ci.txt'):
    for b in re.split(r'^={20,}\n', (E / f).read_text(), flags=re.M):
        m = re.match(r'CASE (\S+)\s+status=(\S+)', b)
        if m:
            blocks[m.group(1)] = (m.group(2), re.search(r'--- stderr unified diff \((\d+) lines\):\n(.*?)(?=\n--- stdout unified diff|\Z)', b, re.S),
                                  re.search(r'--- stdout unified diff \((\d+) lines\):\n', b))
print('deleted rows:', len(deleted), '; cases in the two evidence files:', len(blocks))
bad = 0
for case in deleted:
    if case not in blocks:
        print('MISSING from o1-raw-diffs evidence:', case, '(re-run fresh instead — see check_deleted_rows_fresh.py)'); continue
    status, sm, so = blocks[case]
    minus, plus = [], []
    for line in (sm.group(2).splitlines() if sm else []):
        line = line[4:] if line.startswith('    ') else line
        if line.startswith(('--- ', '+++ ', '@@')): continue
        (minus if line.startswith('-') else plus if line.startswith('+') else []).append(line[1:])
    notes = []
    if len(minus) != len(plus): notes.append(f'unequal changed-line counts {len(minus)} vs {len(plus)}')
    for a, c in zip(minus, plus):
        fa, fc = FRAME.match(a), FRAME.match(c)
        if not fa or not fc: notes.append(f'NON-FRAME changed line: {a!r} -> {c!r}')
        elif fa.group(1, 2, 3, 4) != fc.group(1, 2, 3, 4): notes.append(f'frame differs beyond position: {a!r} -> {c!r}')
    bad += bool(notes)
    print(f'{"BAD" if notes else "OK "} {case}: status={status} stderr-changed={len(minus)}/{len(plus)} stdout-diff={(so.group(1) + " lines") if so else "none"} {"; ".join(notes)}')
print('BAD count:', bad)
