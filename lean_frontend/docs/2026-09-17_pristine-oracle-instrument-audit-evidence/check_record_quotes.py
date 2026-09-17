#!/usr/bin/env python3
"""Record integrity: every verbatim gate/build line quoted in the WP-O record must exist in a file of its evidence dir."""
import re
from pathlib import Path
R = Path('lean_frontend/docs/2026-09-16_pristine-oracle-instrument-record.md').read_text()
E = Path('lean_frontend/docs/2026-09-16_pristine-oracle-instrument-record-evidence')
ev = {p.name: p.read_text(errors='replace') for p in E.iterdir()}
quoted = [l.strip() for l in R.splitlines() if re.match(r'^(Independent oracle|Three-engine report|--corpus|ensure_independent_oracle|lem-|cerberus-(generation|build)|full: |Source unchanged|Release certification|=== B7|PASSED B7|RUN B7|REGRESSION|Baseline check|gcc second-oracle lane OK)', l.strip())]
missing = 0
for q in quoted:
    core = re.sub(r'^--corpus [^:]+:\s*', '', q).split('…')[0].rstrip()
    core = re.sub(r'\s+\(rc 0.*\)$', '', core).rstrip()
    hits = [n for n, txt in ev.items() if core in txt]
    print(('OK  ' if hits else 'MISS'), repr(core[:110]), '->', hits[:3]); missing += not hits
print('quoted lines:', len(quoted), 'missing:', missing)
