# tests/parity-probes/uncertainty — the upstream-uncertainty survey's probe corpus (2026-10-20)

**Not a gate.** No lane walks this directory: `scripts/LADDER.md` lists `tests/parity-probes/` only as the
parity-detective lane's home (rows 123/143, no tier), no `scripts/*.sh` or `tests/common.sh` references
`parity-probes` (checked by grep on 2026-10-20), and `scripts/check_fixture_freeze.sh` pins
`lean_frontend/corpus/` alone. There is no baseline here and nothing turns red when a probe's answer changes;
the record is the claim and these files are its runnable evidence.

Record: `lean_frontend/docs/2026-10-20_upstream-uncertainty-survey-record.md` (the uncertainty-marker
inventory of the shared Lem / hand-written OCaml / std.core / Lean seams, and the 247 probes that measured the
silent sites). One directory per cluster, named by the record's cluster letter; probe names carry the site
prefix used in the record's tables (`an-`, `un-`, `au-`, `ax-`, `ac-` = anonymous members, `ca-`/`cb-` =
compound assignment, `bf-`/`bo-`/`bp-` = `_Bool`, `fl-`/`fs-` = floating types, `wc-`/`wt-` = wchar_t,
`cs-`/`sl-` = string-literal subobjects, `si-` constant expressions, `di-` designators, `td-` tentative
definitions, `en-` enumerators, `st-` size_t/ranks, `va-`/`np-`/`vl-` variadics/prototypes/VLAs, `nl-` null
shifts, `zp-` zapping, `ov-`/`ra-` overlap/temporaries, `se-`/`sx-` statement expressions, `ch-` character
decoding, `pf-` printf, `sh-`/`pr-` shifts/promotions, `fp-`/`at-`/`ag-`/`sz-`/`tq-`/`go-` misc; `ag-02`,
the `_Alignof(long double)` probe, is filed under T-misc although the record's cluster-D table shows it).

## Running one probe

```bash
SKIP_BUILD=1 scripts/ce ./scripts/test_exec.sh tests/parity-probes/uncertainty/B-compound-assignment/cb-02-lhs-call-index.c
gcc -std=c11 -w -o cb-02.gcc tests/parity-probes/uncertainty/B-compound-assignment/cb-02-lhs-call-index.c && ./cb-02.gcc; echo $?   # 14; rm cb-02.gcc
```

`scripts/ce` is the Oath container's environment wrapper (it provides the opam switch); elsewhere, run the
harness with your own OCaml build environment. The harness prints `[1/1] MATCH <name>: VAL:{…}` when the
oracle and the Lean port agree on a value, `UB_MATCH` for an agreed UB verdict, `CERB_SKIP (exit N)` when the
oracle produced no verdict (exit 1 = a front-end rejection, 125 = a crash) and `DIFF`/`MISMATCH` when the two
engines differ. **gcc's "result" is the process exit code, i.e. the C return value modulo 256**: several
probes return values above 255 (the engines print the full value, gcc the residue; the record's notes say so).
The oracle's own message for a CERB_SKIP row: `tools/oracle.sh <file.c>`; the Lean port's: `tools/lean.sh
<file.c>`.

## The instrument (`tools/`)

Run from anywhere; every script finds the repository root from its own location, and the two runners honour
`CERB_ENV_WRAPPER` (a command prefix that provides the OCaml environment; on the Oath boxes
`CERB_ENV_WRAPPER=<container>/scripts/ce`). `tools/run_probes.sh <dir> <out.txt> [glob]` runs every probe of a
directory on gcc and through `scripts/test_exec.sh` (`SKIP_BUILD=1`), one line per probe (`<name>.c | gcc=<exit
or COMPILE_FAIL(…)> | <the harness line, verbatim>`). `tools/oracle.sh <file.c>` / `tools/lean.sh <file.c>` print
one engine's batch verdict or crash text (the Lean side exports the Cabs JSON into `.tmp/uncertainty-probes/`).
`python3 -I tools/render_results.py <out.txt>...` renders result files as the record's markdown tables with the
survey's per-probe classification (a probe missing from its dictionary prints with an empty class, never a
silent grade). `python3 -I tools/inventory.py [--out DIR]` regenerates the marker inventory: it greps the shared
Lem, the hand-written OCaml, `std.core` and the Lean seams with the record's pattern, classifies every hit by
the record's rule plus the survey's hand overrides (keyed by file:line at mainline `3ac3ff336`; they drift with
the sources and are dated), and writes `inventory.csv` and `appendix_b.md` (the full class-(b) list) under
`.tmp/uncertainty-inventory/` by default. Verified on 2026-10-20: `inventory.py` reproduces the record's 1560
hits (373 a / 528 b / 659 c) row for row; the runners reproduce the record's rows for cluster M. Nothing here
is portable to a machine without the built oracle and Lean binaries, which `scripts/test_exec.sh` needs anyway.
