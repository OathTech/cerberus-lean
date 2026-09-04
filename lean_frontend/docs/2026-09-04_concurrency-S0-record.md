# Concurrency Phase 0 — slice S0 record: corpus, lane, "before" pins (2026-09-04)

Charter: `2026-09-04_concurrency-phase0-sc-charter.md` (APPROVED [USER
2026-09-04], D1–D6 as recommended). Branch `feature/concurrency`, tree
= mainline `1b57bcf26` + docs; NO `.lem`, Lean or OCaml source changed in
this slice (regeneration is blocked until C1 merges — brief "Environment
caveat"). Author [AGENT]. Gate for this slice (charter §6 row S0): the
lane's self-test + plants; Tier A is unchanged by construction (the slice
adds `tests/litmus/`, `scripts/test_litmus.sh` and docs only — no gated
file changed; `check_fixture_freeze.sh` covers `lean_frontend/corpus/`, not
`tests/`).

## 1. What landed

- `tests/litmus/` — 24 C litmus programs (14 `SC`, 4 `RMW`, 6 `NONSC`),
  `expectations.txt` (the Phase-0 target sets), `before_baseline.txt` (the
  measured pin), `sc_reference.py` (the SC-DRF reference enumerator),
  `README.md` (provenance, conventions, how to read the pin).
- `scripts/test_litmus.sh` — the lane: both engines exhaustive, OUTCOME
  SETS compared three ways (oracle == Lean == reference row), bijection
  corpus↔rows, `sc_reference.py --check` as the first step, modes
  `--check` (target) / `--check-before` (pin) / `--record-before` /
  `--plant`. Any unparsable output, cap kill or timeout is a failure.
- `scripts/LADDER.md` Tier A row 12: the lane in `--check-before` mode
  until the slice that flips it (S3/S4) re-points it at `--check`.

## 2. Measurements (verbatim)

### 2.1 Derivation gate

```
sc_reference: all 14 SC rows agree with the derivation
```

The enumerator's sets equal every recovered upstream `tests.ml` set they
overlap (SB `{1,2,3}`, LB `{0,1,2}`, MP `{1,2}`, IRIW `{0..15}\{5}`,
coherence `{1}`, hb-mo-cycle `{1,2,3}`, the five `datarace+*` rows); the
new WRC row derives to `{0,1,4,5,7}` (hand check: `z2=1 ⇒ z1=1 ∧ z3=1`).

### 2.2 The pin (`--check-before`), 24/24

```
SUMMARY: mode=before programs=24 engine_disagreements=0 baseline_mismatches=0 red_classes=none
ALL ROWS AT baseline
```

Zero engine disagreements across the corpus: the Lean and OCaml engines
agree on every one of the 24 programs, INCLUDING the four `RMW-*` rows and
the fence row, where both die with the same text
(`INTERNAL_ERROR(TODO[Core_reduction]:_CompareExchangeStrong)` etc. — the
`failwithI` mirror of `core_reduction.lem:799-814`).

### 2.3 The target (`--check`) — RED BY DESIGN, 3/24

```
SUMMARY: mode=check programs=24 engine_disagreements=0 target_mismatches=21 red_classes=RMW NONSC SC
LITMUS LANE FAILED
```

The three green rows (`coherence+sc_sc_sc`, `coherence+init+sc_sc`,
`datarace+Rna+Rna`) are green by coincidence: their target sets are
singletons the serialized run happens to produce. The red classes map to
slices: `SC` multi-outcome rows → S2 (scheduler live); `SC` race rows →
S3 (data-race UB); `NONSC` → S3 (refusals); `RMW` → S4.

### 2.4 Plants

```
plant (a) corrupted row 'coherence+init+sc_sc.c': mismatches=1 (want >=1)
plant (b) empty corpus: failures=25 (want >=1)
PLANTS TRIPPED (lane is not vacuous)
```

### 2.5 The "before" pin itself

`tests/litmus/before_baseline.txt` (24 rows). Every row is ONE outcome and
no row carries a race verdict — the charter §2.1 finding, now pinned over
the whole corpus. Which serialization wins is program-dependent (e.g.
`datarace+Rna+Wna.c` → `{Specified(1)}`: the writer ran first; `MP+na+na.c`
→ `{Specified(0)}`: the reader ran first) — an artefact of the thread
insertion order in `drive_nonmemory_steps_aux2` (`Utils.list_inserts`),
identical on both engines.

## 3. Other S0 measurements (charter §6 S0 items)

- **Locks.** Core has NO mutex actions: `core.lem:274-` `generic_action_`
  carries `Create/Alloc/Kill/Store/Load/RMW/Fence/CompareExchange*/Linux*`
  and the `Store` "locking" bool (`pstore_lock`, translation.lem:3206,
  for §6.2.4#8 objects) — not a mutex. `runtime/libc/include/threads.h`
  only typedefs `mtx_t`. Therefore F_SC has no lock actions in Phase 0;
  the library's `lo`/`locks_only_*` predicates are exercised trivially
  (empty `lo`). Recorded; no design change.
- **Spawns in sequential corpora.** `grep -rl '{-{\|par('` over
  `tests/{minimal,ci,coverage,debug,float,bytes,libc_exec,immaculate,
  verify,multi_tu,cn_coverage,libxml2}`, `lean_frontend/corpus`, and the
  1669-file `tests/csmith` corpus: ZERO hits. The S1 spawn refusal under
  `CM_sequential` cannot move any sequential lane.
- **Front-end finding (tray candidate, not this arc).** `_Atomic int x`
  (C11 6.7.3 qualifier form) is rejected by the front end on both engines
  with the same text: `constraint violation: address argument to atomic
  operation must be a pointer to _Atomic type ('signed int' invalid)`;
  `_Atomic(int) x` and the `atomic_int` typedef work. The corpus uses the
  specifier form; the three upstream-derived files were respelled (headers
  say so). Filed as a one-line candidate in the tray INDEX at S5 with the
  rest of this arc's tray items.
- **Old corpora.** The 2017 Core files fail today's Core grammar
  (`error: unexpected token '='` at `let strong x  =  create (<alignof>…`);
  `{{{ ||| }}}` fails the C parser. Both recorded in the README; C only.

## 4. Decisions in this slice ([AGENT], within the approved charter)

- Token grammar for the lane: `Specified(v)` / `UB…` constructor name /
  `ERROR` / `INTERNAL_ERROR(msg-with-spaces-as-underscores)`; the
  failure TEXT is part of the token so a mismatched failure message is a
  DIFF (the zero-discrepancy rule's "failure text" exception is not taken
  here — on litmus programs the texts are expected identical, and were).
- `REFUSE_RE` placeholder `[Cc]oncurrency` until S1 pins the typed
  refusal text (charter §4.5); NONSC rows are red under `--check` until
  then regardless.
- The lane is Tier A (~1 min warm: 24 tiny programs, both engines) in
  `--check-before` mode; the target mode is what E1 requires at the
  merge-readiness record.

## 5. Provenance

[USER 2026-09-04]: the charter approval. [AGENT]: everything in this
record; all quoted blocks are verbatim lane output from this worktree
(runs of 2026-09-04, primed mainline binaries, fresh driver stamps written
by `build_cerberus`/`build_lean` at lane start). Ephemeral scratch used:
container `.tmp/conc-probe/` (probe copies; deleted at slice end).
