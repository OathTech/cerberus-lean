#!/usr/bin/env python3
"""summarize.py — render a mem-scale sweep TSV as markdown tables plus
derived per-byte costs and growth exponents (arc/mem-scale, 2026-09-01).
Usage: summarize.py results/<sweep>.tsv
Every number printed under 'derived' is computed here from the TSV rows;
the raw rows are reproduced verbatim above them. Instrument only."""
import sys, re, math, collections
rows = []
for line in open(sys.argv[1]):
    if line.startswith('#') or line.startswith('probe\t'): continue
    f = line.rstrip('\n').split('\t')
    if len(f) < 8: continue
    rows.append(dict(probe=f[0], mode=f[1], engine=f[2], exit=f[3], wall=f[4], rss=f[5], verdict=f[6], note=f[7]))

def size_of(p):
    m = re.search(r'_(\d+)$', p); return int(m.group(1)) if m else None
def cls_of(p):
    return re.sub(r'_\d+$', '', p)

base = {}  # (mode, engine) -> rss_kb of z_base
for r in rows:
    if r['probe'] == 'z_base' and r['rss'] != 'NA':
        base[(r['mode'], r['engine'])] = int(r['rss'])

print("### Raw rows (verbatim from the TSV; verdict column: distinct verdicts × count)\n")
print("| probe | mode | engine | exit | wall_s | maxrss_kb | verdict | note |")
print("|---|---|---|---|---|---|---|---|")
for r in rows:
    print(f"| {r['probe']} | {r['mode']} | {r['engine']} | {r['exit']} | {r['wall']} | {r['rss']} | {r['verdict'][:40]} | {r['note']} |")

print("\n### Derived: per-byte resident cost (maxrss − z_base baseline of the same mode/engine) / N, and wall per byte\n")
print("| class | N | engine | ΔRSS_kb | B/byte | wall_s | µs/byte | status |")
print("|---|---|---|---|---|---|---|---|")
by = collections.defaultdict(list)
for r in rows:
    n = size_of(r['probe'])
    if n is None: continue
    st = 'ok' if r['exit'] == '0' else ('TIMEOUT' if r['exit']=='124' else ('KILLED' if r['exit']=='137' else ('PANIC' if r['exit']=='134' else f"exit{r['exit']}")))
    if r['rss'] == 'NA': continue
    b = base.get((r['mode'], r['engine']))
    d = int(r['rss']) - b if b is not None else None
    bpb = (d * 1024 / n) if d is not None else None
    w = float(r['wall']) if r['wall'] != 'NA' else None
    uspb = (w * 1e6 / n) if w is not None else None
    print(f"| {cls_of(r['probe'])} | {n} | {r['engine']} | {d if d is not None else 'NA'} | {bpb:.0f} | {w} | {uspb:.2f} | {st} |" if bpb is not None else
          f"| {cls_of(r['probe'])} | {n} | {r['engine']} | NA | NA | {w} | {uspb:.2f} | {st} |")
    if st == 'ok' and w is not None and d is not None:
        by[(cls_of(r['probe']), r['engine'])].append((n, w, d))

print("\n### Derived: growth exponents between consecutive sizes (log(ratio)/log(size ratio); 1 = linear, 2 = quadratic); ok rows only\n")
print("| class | engine | N₁→N₂ | wall exponent | ΔRSS exponent |")
print("|---|---|---|---|---|")
for (c, e), pts in sorted(by.items()):
    pts.sort()
    for (n1, w1, d1), (n2, w2, d2) in zip(pts, pts[1:]):
        lr = math.log(n2/n1)
        we = math.log(w2/w1)/lr if w1 > 0 and w2 > 0 else float('nan')
        de = math.log(d2/d1)/lr if d1 > 0 and d2 > 0 else float('nan')
        print(f"| {c} | {e} | {n1}→{n2} | {we:.2f} | {de:.2f} |")
