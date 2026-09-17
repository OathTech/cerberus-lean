#!/usr/bin/env python3
"""AUDITOR: for `immaculate/libc/g2-memcmp-uninit` in a row-10 report dir, classify EVERY differing stderr line pair with
MY OWN tokenizer: a pair is 'header-position-only' if both match the OCaml exception-header shape and differ only in the
position; 'frame-position-only' if both match a backtrace-frame shape and differ only in the position; else OTHER (a real
text difference the lane's projection would have to be hiding). Also checks stdout equality and statuses."""
import json, re, sys
from pathlib import Path
rep = Path(sys.argv[1]) / 'report.json'
d = json.load(open(rep))
rows = [r for r in d['rows'] if r['id'] == 'immaculate/libc/g2-memcmp-uninit']
assert len(rows) == 1, rows
r = rows[0]
print('lane status:', r['status'], '| reason:', r['reason'])
up, fk = r['upstream'], r['fork']
print('statuses:', up['status'], fk['status'], '| stdout sha equal:', up['stdout_sha256'] == fk['stdout_sha256'],
      '| raw stderr sha equal:', up['stderr_sha256'] == fk['stderr_sha256'], '| diagnostic sha equal:', up['diagnostic_sha256'] == fk['diagnostic_sha256'])
a = Path(up['capture'] + '.stderr').read_bytes().decode('utf-8', 'replace').splitlines()
b = Path(fk['capture'] + '.stderr').read_bytes().decode('utf-8', 'replace').splitlines()
print('stdout bytes:', Path(up['capture'] + '.stdout').stat().st_size, Path(fk['capture'] + '.stdout').stat().st_size, '| stderr lines:', len(a), len(b))
HDR = re.compile(r'^(\s*File "[^"]*"), lines? \d+(?:-\d+)?, characters \d+-\d+(:.*)$')
FRM = re.compile(r'^(\s*(?:Raised at|Raised by primitive operation at|Called from|Re-raised at) .*? in file "[^"]*"(?: \(inlined\))?), lines? \d+(?:-\d+)?, characters \d+-\d+$')
kinds = {'header-position-only': 0, 'frame-position-only': 0, 'OTHER': 0, 'equal': 0}
others = []
if len(a) != len(b):
    print('LINE COUNT DIFFERS'); kinds['OTHER'] += 1
for x, y in zip(a, b):
    if x == y: kinds['equal'] += 1; continue
    hx, hy = HDR.match(x), HDR.match(y)
    fx, fy = FRM.match(x), FRM.match(y)
    if hx and hy and hx.groups() == hy.groups(): kinds['header-position-only'] += 1; print('  HEADER  <', x.strip()); print('          >', y.strip())
    elif fx and fy and fx.groups() == fy.groups(): kinds['frame-position-only'] += 1
    else: kinds['OTHER'] += 1; others.append((x, y))
print('differing line pairs by kind:', kinds)
for x, y in others: print('  OTHER <', x); print('        >', y)
print('VERDICT:', 'header+frame positions ONLY' if kinds['OTHER'] == 0 else 'REAL TEXT DIFFERENCE PRESENT')
