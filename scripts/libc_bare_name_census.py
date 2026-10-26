#!/usr/bin/env python3
"""Per-procedure bare-name census of a libc Core dump printed at -d5 (`name{n}`).

A SPEEDBUMP, not transport fidelity (inner_arg_temps review P2-3; quotation hygiene
Q4, 2026-10-26; VALIDATION "Core text parameter-identity speedbumps"): the text
transport (`tests/libc/<variant>.core`, parsed by Main.loadLibc) joins symbols by
bare name inside a procedure, so two DISTINCT symbols that share a bare name within
one proc are the shape the join cannot distinguish. This census prints the oracle's
`-d5` dump of the `.co` (every symbol spelled `name{number}`), keeps the procs and
funs whose names the pinned text transports (the `-d5` dump also prints the linked
std.core procs, which both engines parse from std.core's own text), and lists, per
proc, each bare name mapping to more than one symbol number. The committed register
`tests/libc/bare_name_census.tsv` (variant, proc, name, number of distinct symbols)
is the reviewed set: a new row, a vanished row or a changed count fails loudly. It
is a census of the printed spelling, not a liveness or scope analysis; the
principled fix (numbering every named symbol, or a structured transport) is the
queued transport item (TODO.md).

Usage: libc_bare_name_census.py <variant> <d5-dump> <pinned-text> <register>
       libc_bare_name_census.py <variant> <d5-dump> <pinned-text> - --emit   (print rows)
"""
import re, sys
from collections import defaultdict
from pathlib import Path

DECL = re.compile(r'^(proc|fun|glob|def|builtin|struct|union)\s+([A-Za-z_][A-Za-z0-9_]*)(?:\{(\d+)\})?')
TOK = re.compile(r'\b([A-Za-z_][A-Za-z0-9_]*)\{(\d+)\}')
PINNED = re.compile(r'^(?:proc|fun)\s+([A-Za-z_][A-Za-z0-9_]*)')

def census(d5: Path, pinned: Path):
    transported = {m.group(1) for line in pinned.read_text(encoding='utf-8', errors='replace').splitlines()
                   if (m := PINNED.match(line))}
    if not transported:
        raise SystemExit('census: the pinned text names no proc')
    procs, cur = {}, None
    for line in d5.read_text(encoding='utf-8', errors='replace').splitlines():
        m = DECL.match(line)
        if m:
            cur = (m.group(2), m.group(3)) if m.group(1) in ('proc', 'fun') and m.group(2) in transported else None
            if cur:
                if cur in procs:
                    raise SystemExit(f'census: {cur[0]}{{{cur[1]}}} printed twice')
                procs[cur] = defaultdict(set)
        if cur:
            for name, num in TOK.findall(line):
                procs[cur][name].add(int(num))
    if not procs:
        raise SystemExit('census: no transported proc found in the -d5 dump')
    rows = set()
    for (pname, _), names in procs.items():
        for name, nums in names.items():
            if len(nums) > 1:
                rows.add((pname, name, len(nums)))
    return rows, len(procs)

def main():
    args = sys.argv[1:]
    emit = '--emit' in args
    args = [a for a in args if a != '--emit']
    variant, d5, pinned, register = args[0], Path(args[1]), Path(args[2]), Path(args[3])
    rows, nprocs = census(d5, pinned)
    if emit:
        for p, n, k in sorted(rows):
            print(f'{variant}\t{p}\t{n}\t{k}')
        return
    expected = set()
    for ln, line in enumerate(register.read_text().splitlines(), 1):
        if not line.strip() or line.startswith('#'):
            continue
        parts = line.split('\t')
        if len(parts) != 4 or not parts[3].isdigit():
            raise SystemExit(f'census: malformed register line {ln}: {line!r}')
        if parts[0] == variant:
            expected.add((parts[1], parts[2], int(parts[3])))
    if not expected:
        raise SystemExit(f'census: the register has no rows for variant {variant}')
    new, gone = sorted(rows - expected), sorted(expected - rows)
    if new or gone:
        for p, n, k in new:
            print(f'census: {variant}: NEW shared bare name: proc {p}: {n} maps to {k} symbol numbers (not in the register)', file=sys.stderr)
        for p, n, k in gone:
            print(f'census: {variant}: register row no longer observed: proc {p}: {n} ({k} numbers)', file=sys.stderr)
        raise SystemExit(1)
    procs_hit = len({p for p, _, _ in rows})
    print(f'libc_prep: census OK ({variant}: {nprocs} transported procs/funs; {len(rows)} shared bare names in {procs_hit} procs = the register; a speedbump on the printed spelling, not transport fidelity)')

if __name__ == '__main__':
    main()
