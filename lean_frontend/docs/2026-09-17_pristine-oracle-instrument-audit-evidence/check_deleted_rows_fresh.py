#!/usr/bin/env python3
"""Auditor's check over FRESH captures (.tmp/audit/only21 = `--corpus all --only <the 21 deleted rows>` at 586b550b8):
pristine vs fork raw stderr must have equal line counts and every differing line pair must be an OCaml backtrace
frame differing ONLY in its position (auditor's tokenizer); statuses equal; stdout empty on both."""
import json, re, sys
from pathlib import Path
rep = json.load(open(sys.argv[1] if len(sys.argv) > 1 else '.tmp/audit/only21/report.json'))
FRAME = re.compile(r'^\s*(Raised at|Raised by primitive operation at|Called from|Re-raised at)\s+(.*?) in file "([^"]*)"( \(inlined\))?, lines? (\d+(?:-\d+)?), characters (\d+-\d+)$')
bad = 0
for row in rep['rows']:
    up = Path(row['upstream']['capture'] + '.stderr').read_text(errors='replace').splitlines()
    fk = Path(row['fork']['capture'] + '.stderr').read_text(errors='replace').splitlines()
    uo = Path(row['upstream']['capture'] + '.stdout').read_bytes(); fo = Path(row['fork']['capture'] + '.stdout').read_bytes()
    notes = []
    if row['upstream']['status'] != row['fork']['status']: notes.append(f"status {row['upstream']['status']} vs {row['fork']['status']}")
    if uo != fo or uo: notes.append(f'stdout differs or non-empty ({len(uo)}/{len(fo)} B)')
    if len(up) != len(fk): notes.append(f'stderr line counts {len(up)} vs {len(fk)}')
    changed = 0
    for a, b in zip(up, fk):
        if a == b: continue
        changed += 1
        fa, fb = FRAME.match(a), FRAME.match(b)
        if not fa or not fb: notes.append(f'NON-FRAME differing line: {a[:90]!r} vs {b[:90]!r}')
        elif fa.group(1, 2, 3, 4) != fb.group(1, 2, 3, 4): notes.append(f'frame differs beyond position: {a[:90]!r} vs {b[:90]!r}')
    payload = next((l for l in up if l.strip() and not l.startswith('cerberus: internal error')), '')[:70]
    bad += bool(notes)
    print(f"{'OK ' if not notes else 'BAD'} {row['id']}: lane={row['status']} status={row['upstream']['status']} lines={len(up)} changed={changed} payload={payload.strip()!r} {'; '.join(notes)}")
print('rows:', len(rep['rows']), 'BAD:', bad, 'counts:', rep['counts'])
