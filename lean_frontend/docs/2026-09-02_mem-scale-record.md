# MEMORY-SCALE arc — implementation record (class-0 slices S0 / S1 / S1' / S2)

Date: 2026-09-02. Branch `arc/mem-scale`, rebased onto mainline
`ddcfc9199` (from `bbdbacaff`; no conflicts). Author: implementation
worker. Governing document: `2026-09-01_mem-scale-design.md` (charter
v0-R1.1, RULED); measurements: `2026-09-01_mem-scale-profile.md`. This
record is written per slice as each closes (kill-loss containment);
every quoted output is verbatim, derived tallies are labelled derived.

Hard invariants held throughout (charter §1, §6.5): the reference
memory model's observable behaviour does not change; no fuel / stack /
`maxRecDepth` / heartbeat bump anywhere; no `native_decide` /
`bv_decide` / `ofReduce*`; every algorithmic shape divergence from the
OCaml is documented in-code with the cite.

Pre-fix driver binaries (the S1' plant reference), sha256 prefixes at
the start of the arc (tree `e7f91cf78`, stamps fresh per
`tools/check_driver_fresh.sh`): oracle `c93bbfebd196f782`, Lean
`91c805fb050f76be`.

## S0 — loudness (HANG classification) — DONE

### What changed

- `scripts/common.sh`: `TIME_BIN=/usr/bin/time`, `require_time_bin`
  (fail-closed), `time_record_cpu_wall`, `classify_exit124` — exit 124
  with (User+System)/wall < 0.1 → `HANG(cpu Xs of Ys wall; timeout
  Ns)`, else `TIMEOUT(cpu … ; timeout Ns)`; an unreadable time record
  is a HARNESS ERROR (rc 1), never a TIMEOUT. Plant hook
  `CERB_LEAN_BIN_OVERRIDE` (loud banner on every use; the SKIP_BUILD
  Lean freshness check is skipped LOUDLY under it).
- `scripts/test_exec.sh`: both driver runs wrapped in `$TIME_BIN -v -o
  <record> timeout …` (GNU time propagates exit status unchanged —
  verified 139/134/124/70); new status `HANG` (rank 0, fatal in default
  mode, fatal on a new file, never `UNSUPPORTED`-absorbed); `hang=` in
  the SUMMARY line; the oracle-side exit 124 stays `CERB_SKIP` with the
  CPU/wall ratio printed in the skip line.
- `scripts/test_ci_sweep.sh`: `LEAN_HANG` / `CERB_HANG` rows (the
  sweep already subdivides oracle failures), same wrapper.
- `scripts/test_hang_plant.sh` (new): drives both lanes with a sleeping
  stub and a busy-looping stub, asserts the readings, and asserts the
  classifier's fail-closed path.
- `lean_frontend/docs/upstream-tray/lean4/01-stack-overflow-handler-deadlock.md`
  (new; INDEX pointer added): the Lean runtime report draft.
- `lean_frontend/TODO.md` KNOWN HANG item (c) marked done.

### Plant evidence (verbatim, `scripts/test_hang_plant.sh`, 2026-09-02)

```
PLANT OK   [exec/sleep → HANG]: [1/1] HANG 001-return-literal (Lean HANG(cpu 0.00s of 3.00s wall; timeout 3s))
PLANT OK   [exec/sleep summary]: FAILED: 1 Lean HANG(s) — exit 124 with CPU/wall < 0.1: no output, no exit (charter C9 shape)
PLANT OK   [exec/busy → TIMEOUT]: [1/1] TIMEOUT 001-return-literal (Lean TIMEOUT(cpu 3.00s of 3.00s wall; timeout 3s))
PLANT OK   [exec/busy summary]: FAILED: 1 Lean timeout(s)
PLANT OK   [sweep/sleep → LEAN_HANG]: ci	tests/ci/0001-emptymain.c	LEAN_HANG	HANG(cpu 0.00s of 3.00s wall; timeout 3s)
PLANT OK   [sweep/busy → LEAN_TIMEOUT]: ci	tests/ci/0001-emptymain.c	LEAN_TIMEOUT	TIMEOUT(cpu 2.99s of 3.00s wall; timeout 3s)
PLANT OK   [classifier fail-closed]: HARNESS ERROR: time record /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/mem-scale/.tmp/scripts/hang-plant.sKJ0b5Kl9Z/does-not-exist.time missing
test_hang_plant: all plants read as expected (sleep→HANG, busy→TIMEOUT, both lanes; missing record→harness error)
```

### The real input (S0 gate) — verbatim, `SKIP_BUILD=1 TIMEOUT_SECS=400 CERB_MEM_MAX=32G scripts/capped scripts/test_exec.sh tests/mem-scale-probes/probes/a_zero_global_10000000.c`, pre-fix Lean binary `91c805fb050f76be`

```
[1/1] HANG a_zero_global_10000000 (Lean HANG(cpu 3.29s of 400.12s wall; timeout 400s))
SUMMARY: total=1 match=0 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 hang=1 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
FAILED: 1 Lean HANG(s) — exit 124 with CPU/wall < 0.1: no output, no exit (charter C9 shape)
FAILED: zero comparisons happened (all files skipped) — vacuous run
```

(The oracle completed the 10 M input inside the 400 s budget first —
the file reached the Lean side.) This row doubles as the S1' plant's
pre-fix reference.

### Do any committed rows change class? Verified, not assumed — NONE

- `scripts/exec_csmith_corpus_baseline.txt` carries 8 `TIMEOUT` rows;
  re-materialised (the lane's shim) and re-run through test_exec.sh at
  the lane's `TIMEOUT_SECS=15`, verbatim:

```
[1/8] TIMEOUT sa_csmith_197 (Lean TIMEOUT(cpu 14.99s of 15.00s wall; timeout 15s))
[2/8] TIMEOUT sa_csmith_419 (Lean TIMEOUT(cpu 14.99s of 15.00s wall; timeout 15s))
[3/8] TIMEOUT sa_csmith_435 (Lean TIMEOUT(cpu 14.97s of 15.01s wall; timeout 15s))
[4/8] TIMEOUT sia_csmith_072 (Lean TIMEOUT(cpu 15.00s of 15.00s wall; timeout 15s))
[5/8] TIMEOUT sia_csmith_161 (Lean TIMEOUT(cpu 15.00s of 15.00s wall; timeout 15s))
[6/8] TIMEOUT sia_csmith_169 (Lean TIMEOUT(cpu 15.01s of 15.02s wall; timeout 15s))
[7/8] TIMEOUT sia_csmith_976 (Lean TIMEOUT(cpu 14.99s of 15.00s wall; timeout 15s))
[8/8] TIMEOUT sia_csmith_996 (Lean TIMEOUT(cpu 15.00s of 15.00s wall; timeout 15s))
```

  All CPU-bound (ratio ≈ 1.0): the class is unchanged, no baseline
  commit needed. No other exec baseline carries a TIMEOUT row.
- `tests/ci_sweep/results/*.tsv` (Tier-C reporting artifact, not a
  gate) carries 3 `LEAN_TIMEOUT` rows (libc mode). Re-measured with
  the sweep's exact command under `/usr/bin/time -v` at 15 s and 60 s
  (verbatim, derived columns = the raw time -v fields):

```
40_stdio timeout=15s rc=134 user=1.37 sys=0.03 wall=0:02.47
40_stdio timeout=60s rc=134 user=1.34 sys=0.04 wall=0:02.45
pr69320-4 timeout=15s rc=124 user=14.88 sys=0.11 wall=0:15.00
pr69320-4 timeout=60s rc=0 user=31.88 sys=0.13 wall=0:32.02
pr20621-1 timeout=15s rc=124 user=14.79 sys=0.23 wall=0:15.02
pr20621-1 timeout=60s rc=134 user=21.76 sys=0.31 wall=0:23.14
```

  None is HANG-shaped (CPU ≈ wall on every 124). OBSERVATION, not
  caused by S0 and not acted on here: `tests/tcc/40_stdio.c` now exits
  134 in 2.5 s on the current binary where the committed sweep row says
  `LEAN_TIMEOUT` — the committed sweep TSV predates the current driver
  (a Tier-C artifact re-record is a separate deliberate instrument run;
  registered for the orchestrator). No CERB_TIMEOUT row was
  re-measured (the oracle fails loudly on its own ceiling; its class is
  unchanged by construction — `CERB_TIMEOUT` rows stay `CERB_TIMEOUT`
  unless CPU-idle, which this instrument would now reveal on the next
  sweep).

### Tier-A exec rows under the new classifier (verbatim SUMMARY + verdict)

```
=== minimal: test_exec.sh --check-baseline
SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
=== coverage
SUMMARY: total=199 match=174 ub_match=12 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
=== debug
SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
=== float
SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
```

### The Lean upstream report — standalone reproducer: negative result

A standalone Lean 4.32.2 program with the same non-tail monadic `mapM`
shape overflows and aborts LOUDLY ("Stack overflow detected.
Aborting.", SIGABRT) at 10^7 elements; a variant allocating a large
`ByteArray` per element (malloc path) did not deadlock in 3 trials at
each of three sizes. So the deadlock requires the fault to land while
a lock is held, which our driver does deterministically and the toy
does not; the draft carries the in-project reproducer and the negative
result. [AGENT] slip, recorded: those six variant-B trials were run
WITHOUT `scripts/capped` (they page-faulted up to 94 GB RSS for 60 s
each on the shared box) — every later run in this arc is capped.

### Decisions in S0 (provenance)

- [AGENT] Oracle-side exit 124 in `test_exec.sh` keeps its `CERB_SKIP`
  class (adding an oracle-side status there would widen the baseline
  taxonomy for a class the oracle has never exhibited — it fails
  loudly on its own ceiling); the ratio is printed in the skip line so
  an oracle-side hang cannot pass unremarked. `test_ci_sweep.sh`, which
  already subdivides oracle failures, gets `CERB_HANG`.
- [AGENT] A HANG on an `*.unsupported.c` file is `HANG`, not
  `UNSUPPORTED`: no output + no exit is never "expected".
- [AGENT] The plant is driven through the real lanes via a loud
  `CERB_LEAN_BIN_OVERRIDE` hook rather than by unit-testing the
  classifier alone, so the lanes' status plumbing (record_status,
  SUMMARY, fatal exit) is what is asserted.
