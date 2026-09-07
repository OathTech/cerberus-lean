# Fuel measure execution cost — 2026-09-07

[AGENT] Work under the [fenced charter](2026-09-07_codex-charter-fuel-measure-cost.md),
on `arc/fuel-measure-cost` at starting HEAD
`cee6b4639508c543524900bcd763ae04565f1916`. This HEAD adds only the charter
to the target `4d1088004`. No earlier deliverable or active charter job
was present when this work began. **D1 is complete. D2–D5 remain pending;
no attribution conclusion or charter completion is claimed.**

## Property and boundaries

The charter's property, verbatim:

> The Lean semantics at HEAD must cost no more than 10 % more CPU per program than it did before the fuel-parameter arc, and every csmith corpus row that completed under the lane's 15-second budget before the arc must complete under it again — with every sufficiency theorem still kernel-checked and zero baseline movement.

[AGENT] Commands source `/home/dev/projects/cerberus-lean-proj/scripts/env.sh`.
Lean/Lake and the timing lane run under `scripts/capped` with
`CERB_MEM_MAX=48G`. The cap preflight printed
`cap smoke: memory.max=51539607552`, exit 0. Our builds and lanes are
serialized. The initial box load was:

```text
19:54:07 up 1 day,  4:29,  ? user,  load average: 18.63, 28.03, 18.68
```

This is context, not the timing table's load: each timing export's metadata
records its own start/end `uptime`. Verdict-deciding ratios must be repeated.
The initial login shell's logout-file read hit a nono OS sandbox boundary
(`/home/dev/.bash_logout`); subsequent shells are nonlogin. The cap and
build succeeded; no sandbox grants or global settings were changed.

## D1 — instrument and HEAD measurement (complete)

`scripts/measure_csmith_cpu.py` executes the existing
`scripts/test_csmith_corpus.sh --check-baseline` with `SKIP_BUILD=1`.
It reuses the lane's staging, prefixes, header substitution, oracle flags,
cabs-json bridge, Lean invocation, and classification. A shell-local `rm`
function copies only the lane's `.time` records and `status.txt` at cleanup,
then performs the original removal. No existing harness source is edited.
This retention hook is restricted to the target checkout's `exec-test.*`
scratch directories; it is not active outside this instrument's subprocesses.

Each input exports an oracle row and a Lean row. Both carry the lane's
joint status; an unexecuted Lean side carries `NA` exit/resources. CPU is
GNU time user+system seconds (0.01 s precision), including the waited-for
timeout/engine descendants. An exit-124 measurement is censored, not a
completed-program CPU cost. The collector checks every saved status against
the corresponding printed lane row, checks consecutive indices and complete
summaries, and rejects missing/extra timing records. Export success is not a
baseline success: the actual baseline verdict and lane exit are retained.

The primed binaries lacked freshness stamps. The normal `build_cerberus`
and `build_lean` helpers built and stamped both successfully, with a 55-minute
outer tripwire (not reached). [Build output](2026-09-07_fuel-measure-cost-evidence/head-build.txt)
records Lean `Build completed successfully (273 jobs).` and these binary hashes:

| Engine | SHA-256 after build |
|---|---|
| Oracle | `a7ceeb66f4297d5210f3f417fa82b5dc238a303a10f134d494acc737e2f186c6` |
| Lean | `32f8b3427f023ad78afc27fd170284cf09c2b331751652ef588d8d0061a62ad6` |

The instrument's first selftest caught its own incorrect assumptions about
zero-padded input names and the colon after MATCH filenames. Both were fixed
inside the new script. The successful selftest exercised known exact rusage,
a real 0.20-CPU-second stub, an oracle refusal, a CPU-bound timeout, and
missing/malformed time-record refusals. [Verbatim output](2026-09-07_fuel-measure-cost-evidence/instrument-selftest.txt):

```text
CPU instrument SELFTEST OK: exact rusage, real CPU stub, MATCH/CERB_SKIP/TIMEOUT, missing/malformed records refused
```

Tier A ran through `python3 scripts/release.py --mode fast` with
`DUNE_CACHE=disabled` and the 48 GiB cap, before the corpus timing run.
[Runner output](2026-09-07_fuel-measure-cost-evidence/d1-fast.txt) and
[direct lane verdict lines](2026-09-07_fuel-measure-cost-evidence/d1-fast-verdicts.txt)
are retained. Verbatim:

```text
fast: passed; 13/13 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

The included direct `./scripts/test_unit.sh` run passed before any semantic
source edit; it is the charter's required pre-D3 snapshot. This is Tier A
evidence only, not D5's full battery.

The final reporting-table placement adds the instrument as `C5`, preserving
the existing `C4` CI sweep ID. The initial placement before that row would
have shifted its ID; this documentation-only correction followed the fast
pass. A [catalogue comparison](2026-09-07_fuel-measure-cost-evidence/d1-ladder-membership.txt)
using the release runner's own parser verifies that every existing ID,
command and tier is unchanged from HEAD, including the complete Tier A and
Tier B command sets. No timed command or semantic source changed.

The completed whole-corpus command was:

```sh
python3 scripts/measure_csmith_cpu.py --output lean_frontend/docs/2026-09-07_fuel-measure-cost-evidence/head-before-15.tsv
```

Its timeout is 15 s per engine. The raw run directory is
`.tmp/fuel-measure-cost/cpu-fp9njwkc`. The original process finished at
`2026-09-07T22:36:57Z`, export exit 0, after starting at `20:15:07Z`.
The whole-corpus measurement is the charter's pre-justified long differential
pass. [The complete TSV](2026-09-07_fuel-measure-cost-evidence/head-before-15.tsv)
has 1,669 inputs and 3,338 engine rows. Its
[metadata](2026-09-07_fuel-measure-cost-evidence/head-before-15.meta.txt)
records unchanged identities across the timing run, including the measured
oracle SHA-256 `7b8ddb10ecddfa6c9d61eac5632ffa7cb195febcf40e2e9325481bc59ae6ffb3`
(after the Tier A builds) and the same Lean SHA-256 shown above.

[Acceptance checks](2026-09-07_fuel-measure-cost-evidence/d1-acceptance.txt)
verify that every TSV status equals both the retained lane status and its
printed classification, every committed baseline input appears exactly once
per engine, and the only baseline changes are the two known timeouts.
Derived tally: **1,159 MATCH, 499 CERB_SKIP, 11 TIMEOUT**. All nine baseline
TIMEOUT inputs remain TIMEOUT; no other input changes status. The underlying
lane's exit 1 is the expected D1 observation, not a green baseline verdict.
The instrument's integrity acceptance, selftest, and Tier A gates are green.
Evidence occupies 175,389 bytes at this D1 acceptance point, below the
charter's 1 MB total limit. Verbatim lane verdicts:

```text
SUMMARY: total=1669 match=1159 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=11 hang=0 cerb_skip=499 cerb_floor=0 cerb_inconsistent=0
REGRESSION: sa_csmith_369.c baseline=MATCH current=TIMEOUT
REGRESSION: sa_csmith_371.c baseline=MATCH current=TIMEOUT
Baseline check: 2 regression(s), 0 improvement(s)
FAILED: regressions vs baseline
```

Timing-table load, verbatim from the export metadata:

```text
start_uptime=20:15:07 up 1 day,  4:50,  ? user,  load average: 10.84, 7.30, 9.70
end_uptime=22:36:57 up 1 day,  7:12,  ? user,  load average: 5.59, 5.32, 6.25
```

The live pass reproduced both known regressions, verbatim:

```text
[303/1669] TIMEOUT sa_csmith_369 (Lean TIMEOUT(cpu 15.00s of 15.00s wall; timeout 15s))
[306/1669] TIMEOUT sa_csmith_371 (Lean TIMEOUT(cpu 14.99s of 15.00s wall; timeout 15s))
```

[AGENT] These observations are CPU-bound at the lane's limit. At the
312-input observation point they were the only baseline changes (derived
comparison of completed printed statuses with the committed baseline).
This is partial-run evidence, not D1 acceptance. The load read immediately
after that observation was:

```text
 21:00:34 up 1 day,  5:36,  ? user,  load average: 32.11, 9.90, 5.36
```

The separate [live instrument check](2026-09-07_fuel-measure-cost-evidence/d1-live-instrument-check.txt)
verified byte equality of all 1,669 staged inputs and both headers against
the lane's recipe, the exact sorted input list, and real timing-record
parsing on the first 36 completed inputs. The completed export subsequently
passed the full acceptance checks above.

## D2–D5 — not started

Attribution, the pre-arc build and comparison, any proven measure change,
the 1.10 ratio bar, and the full closing battery remain pending. The current
record does not establish any of those requirements.

## What has not been done

No semantics, measure, theorem, worker, `_zero` lemma, generated source,
register, baseline, pin, or opam change. No reference worktree has been
created. No merge or push. The only intended source changes so far are the
new instrument, its NON-GATING reporting-tier documentation, and this record
and its compact evidence. No stop rule has fired.
