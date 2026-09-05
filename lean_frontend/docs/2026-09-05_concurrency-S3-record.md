# Concurrency Phase 0 — slice S3 record: the candidate execution, the bridge check, the race verdict (2026-09-05)

Charter: `2026-09-04_concurrency-phase0-sc-charter.md` §4.3–4.4 (APPROVED
[USER 2026-09-04]); consumer review Q2/Q3 (`…S1-interface-review-response.md`);
manifest addendum for the consumer: `2026-09-05_concurrency-S3-change-manifest.md`.
Branch `feature/concurrency`, rebased onto mainline `a910f097c` (fuel arc C2)
before this slice's gates. Author [AGENT]. Gate: FULL.

## 0. What the SC instance now does (both engines, identically)

Under `--concurrency=sc` every load and store is performed against the
concrete memory (the value store, unchanged) AND recorded into a candidate
execution of the axiomatic C11 model (`concurrency_state : Cmm_op.symState`):
the pre-execution (actions with concrete values, threads, location kinds
from the access ctype, `sb`/`asw` from the reduction's annotations) and the
witness (`rf` = the most recent committed same-location write, `mo` = the
writes at each ATOMIC location in commit order, `sc` = the seq_cst actions
in commit order; `lo`/`tot` empty — no locks in F_SC, §S0 record). At trace
end `drive` (a) reports the library's `data_races` as `UB005_data_race` and
(b) requires the library's SC consistency tree to hold — a failing leaf is
the typed kill `DErr_model_inconsistent (MI_sc_inconsistent leaf)`. The order
is races-then-bridge: a racy trace's non-atomic read may have taken its value
from the racing write, which the axiomatic model classes as INCONSISTENT
(`consistent_non_atomic_rf`: the read is not in `vse`); the program is UB and
that is the verdict; the bridge is the invariant over the race-free traces.

## 1. What landed (cites post-change)

- `core_reduction.lem` — `Step_action_request2` carries the action's
  POLARITY and `core_run_annotation` (:118-127; 5→7 components); `step_ctx`
  takes the model (:1090-1094); the sb hook `wrap_tagged` (:1165-1180) tags
  the action's CONTEXT frames and the thread's stack with the new action id
  at its reduction step, for all five request kinds; the callee body of a
  procedure call is sequenced after the call node (`Eproc`, the working-era
  rule); excluded (negative) actions keep polarity `Neg`.
- `core_run_aux.lem` — `add_to_sb_ctx` / `add_to_asw_ctx`: walkers over the
  reduction CONTEXT mirroring `add_to_sb_continuation`'s K-cases (unseq
  siblings untouched; weak-seq continuations get positive tags; strong-seq
  continuations get ALL tags, POSITIVIZED — §2.3); `add_to_sb_stack` /
  `add_to_asw_stack` handle the procedure-call frame `Stack_cons2` (was an
  `error`); the expression walkers traverse the reduction-context forms
  `Ebound`/`Eannot`/`Eexcluded` (were `error`s); `termination_argument
  automatic` for the ctx walkers (no `partial`).
- `core_run.lem` — `kill_thread`: the join's asw edges annotate the parent's
  ARENA as well as its stack (the continuation lives in the arena now).
- `driver.lem` — `model_inconsistency += MI_sc_inconsistent of string`
  (+ renderer); `lk_of_ctype`; `sc_record_action` (the pre-execution step
  via `Cmm_op.symUpdatePreEx` with sb/asw from the annotations — a thread's
  FIRST action inherits its parent-thread `sb_before` entries as asw, the
  working-era rule; the witness update); `action_request_sc2` (the SC arm of
  `perform_action_request2`: sequential effects + record; Create/Alloc/Kill
  performed, not recorded — `SC_condition` excludes Alloc/Dealloc; SeqRMW =
  NA load + NA store, two ids, whole-thread-state sb tagging — the one
  recorded sb over-approximation, confined to Cerberus's sequential
  compound RMW); `sc_failing_leaves` (mutual, `automatic`), `sc_candidate_
  execution` (`release_acquire_fenced_relations`, the SC model's own
  relation calculator); the `drive` tail under `CM_sc` (§0); two debug
  lines at level 2 (`DB_concurrency`), CM_sc only.
- Lean: `CerbStepInstances.lean` (arity), `test/Unit/FuelExemplar.lean`
  (`step_ctx … CM_sequential …`), `Core_run_aux_lemMeasureProofs.lean` (C2's
  `add_to_sb`/`add_to_asw` fuel-measure proofs take the model — `cases
  model`: identity under `CM_sequential`, the walk under `CM_sc` with the
  new arms closed by the induction key; the obsolete `split`s on the former
  `if Global.using_concurrency ()` removed), NEW `test/Unit/SCBridgeTest.lean`
  (§2.4) registered in `lakefile.toml` + `test_unit.sh`.
- `scripts/fork_drift_manifest.txt`: 4 hashes moved (core_reduction.ml,
  core_run_aux.ml, core_run.ml, driver.ml), dated NOTE; `tests/litmus/
  before_baseline.txt` re-recorded (§3); README/LADDER/TODO text.

## 2. Findings on the way (all fixed in this slice; each was measured)

### 2.1 The consistency tree as a construction oracle

The bridge check fired on three classes of trace and each failing leaf
named a construction gap: `consistent_non_atomic_rf` (racy traces — the
verdict order, §0), `consistent_mo` (`mo` must be total over EVERY write at
an atomic location, the non-atomic initialiser included — the location
kind decides, not the write's own order), `well_formed_threads` /
`consistent_non_atomic_rf` on 3+ threads (the missing edges below). After
the fixes the tree holds on every race-free trace of the corpus (E2).

### 2.2 The join's asw edges reached only the stack

`kill_thread` (working era) annotated the parent's STACK continuations;
under the reduction-context semantics the parent's post-join actions live
in its ARENA — every race-free program with a post-join read of a
child-written local was reported racy (e.g. `coherence+init+sc_sc.c`).
Fixed: `add_to_asw` on the arena too.

### 2.3 The negative store's sb edge (the deepest one)

`a = 1; b = a;` lost the store→load edge: the assignment's store is a
NEGATIVE action (`neg(store(...))`, Cerberus's weak-sequencing model of
side effects), and the load of `a` sits in the continuation of an inner
`let weak` whose first component is pure — the expression walker's weak-seq
rule (positive tags only into e2) filtered the tag that had already crossed
the statement's STRONG boundary. Diagnosis: SB-TAG/SC-RECORD debug lines
(kept, `-d2`, CM_sc only) and the dumped remaining program. Fix: a tag
crossing a `Csseq` frame enters e2 as POSITIVE — the working-era rule at
procedure entry (`Set.map (fun z -> (Pos, z))`, upstream core_run.lem:981)
generalised to the context walker. Why not simply tag the rebuilt arena
with the expression walker (which "worked" with positive tags): it also
tags the action's UNSEQUENCED siblings, over-approximating sb — and hiding
a cross-thread race whose thread-local action is unsequenced with a
synchronising atomic in the same full expression. The context walker keeps
the working-era discipline (unseq siblings are not sequenced after).

### 2.4 Plants

`test/Unit/SCBridgeTest.lean` builds candidate executions BY HAND through
the same generated functions the driver calls: a coherent single-thread
SC execution passes every leaf; with `rf` corrupted to the earlier store it
FAILS, naming `coherent_memory_use` and `sc_accesses_sc_reads_restricted`;
an unsynchronised cross-thread non-atomic store/load pair IS a `data_races`
member, and with the asw edge it is not. Verbatim:

```
test: coherent SC execution passes every consistency leaf
  ✓ PASS
test: PLANT: rf corrupted to the earlier store FAILS the tree (named leaf)
  ✓ PASS
test: PLANT names a coherence leaf
  ✓ PASS
test: unsynchronised NA store/load across threads IS a data race
  ✓ PASS
test: the same pair ordered by asw is race-free
  ✓ PASS
  (plant's failing leaves: [coherent_memory_use, sc_accesses_sc_reads_restricted])

5 passed, 0 failed
```

### 2.5 Environment

Rebased over mainline `a910f097c` (C2) mid-slice; C2 had added
`fuel_measure` declares + proofs for `add_to_sb`/`add_to_asw` — adapted
(§1). The installed lem is `d4ba548` (the orchestrator's pin move; the
Lake `LemLib` pin is unchanged at `ecf75b4` on mainline and here).

## 3. Gates

**Tier A row 1 — `./scripts/test_unit.sh`** (fully rebuilt library; 7 exes incl. the new `sc-bridge-test`), verbatim key lines:

```
✓ sc-bridge-test PASSED            (the chain's tail cut the 7-exe total; re-run of the one exe: `5 passed, 0 failed` / `Total: 1 passed, 0 failed`; the chain's rc=0 covers all 7)
check_fuel_forms: OK (81 fuel'd workers: 41 MEASURED (every obligation + proof cone ⊆ the standard three), 13 ABSORBING, 21 reachable-AMBIENT = the 21 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
check_lem_sync: OK (src 1fd26c3448f8bfd341be4fcf36e1d3877afb7776df62d4555f605821ee09140e, gen 3b2147f0583901c4aad3ab1bc3b033177ec812e1112b2b077c47d0cabd0c053e)
check_lem_sync: lean OK (src 1fd26c3448f8bfd341be4fcf36e1d3877afb7776df62d4555f605821ee09140e, gen 4149e69d55b9b07559d2126eb1fedcc46f8658ad23990dd2d405fab5f2855de4)
check_fork_drift: OK — layer 1: 72 oracle-surface files = manifest; layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
rc=0
```

The totality gate's 22 modules include the four this slice changed; the two
new context walkers and the mutual `sc_failing_leaves` pair are plain
`def`s (0 `partial`, 0 allowlisted). C2's 41 MEASURED obligations still
hold, the two re-proved ones among them.

**Litmus lane**, verbatim:

```
### litmus --record-before (deliberate re-pin, S3)
recorded 24 rows to …/tests/litmus/before_baseline.txt
### litmus --check-before
SUMMARY: mode=before programs=24 engine_disagreements=0 baseline_mismatches=0 seq_leg_fail=0 red_classes=none
ALL ROWS AT baseline
### litmus --check (target; RMW rows red by design until S4)
[MATCH] SEQ leg (SB+sc_sc+sc_sc.c, no model flag): both engines refuse ("model refused: thread spawn (par) under the sequential model; select --concurrency=sc")
SUMMARY: mode=check programs=24 engine_disagreements=0 target_mismatches=4 seq_leg_fail=0 red_classes=RMW
LITMUS LANE FAILED
### litmus --plant
plant (a) corrupted row 'coherence+init+sc_sc.c': mismatches=1 (want >=1)
plant (b) empty corpus: failures=25 (want >=1)
PLANTS TRIPPED (lane is not vacuous)
```

20 of 24 rows at their Phase-0 TARGET (every SC row incl. the five race
rows, every NONSC refusal, the SEQ leg); the 4 red rows are exactly the
`RMW-*` rows S4 owes (matched `TODO[Core_reduction]` internal errors).

**The sequential battery (FULL gate):**

Tier A rows 2–11 + Tier B rows 1–8, serial, 2026-09-05 03:40–04:26 UTC (box
load at each lane's start in the fourth column — it began at 56 from other
agents' work), verbatim per-lane return codes:

| row | lane | start | load | rc |
|---|---|---|---|---|
| A2 | `test_exec minimal` | 03:40:24 | 56.46 | rc=0 |
| A3 | `test_exec coverage` | 03:40:53 | 56.39 | rc=0 |
| A4 | `test_exec debug` | 03:41:55 | 59.80 | rc=0 |
| A4b | `test_exec float` | 03:42:06 | 48.56 | rc=0 |
| A4c | `test_bytes` | 03:42:16 | 42.16 | rc=0 |
| A5 | `test_libc_exec` | 03:42:19 | 42.16 | rc=0 |
| A6 | `test_multi_tu` | 03:42:42 | 29.65 | rc=0 |
| A7 | `test_parse minimal` | 03:42:44 | 29.65 | rc=0 |
| A8 | `test_core minimal` | 03:42:54 | 26.01 | rc=0 |
| A9 | `test_elab` | 03:43:02 | 22.77 | rc=0 |
| A10 | `test_libxml2_uri` | 03:43:19 | 18.71 | rc=0 |
| A11 | `test_cn_coverage` | 03:43:30 | 16.36 | rc=0 |
| B1 | `test_libxml2` | 03:43:59 | 11.10 | rc=0 |
| B2 | `test_parse ci` | 03:57:32 | 52.57 | rc=0 |
| B3 | `test_core ci` | 03:57:55 | 38.50 | rc=0 |
| B4 | `test_verify` | 03:58:10 | 30.57 | rc=0 |
| B5 | `test_immaculate` | 03:58:51 | 15.80 | rc=0 |
| B6a | `speclab selftest` | 03:59:47 | 17.70 | rc=0 |
| B6b | `speclab plant` | 04:01:25 | 6.59 | rc=0 |
| B6 | `speclab divmod` | 04:01:27 | 6.22 | rc=0 |
| B6 | `speclab bytearr` | 04:01:38 | 5.65 | rc=0 |
| B6 | `speclab list` | 04:01:48 | 5.16 | rc=0 |
| B6 | `speclab tree` | 04:01:59 | 4.75 | rc=0 |
| B6 | `speclab seed` | 04:02:10 | 4.33 | rc=0 |
| B7 | `test_gcc_oracle` | 04:02:21 | 4.41 | rc=0 |
| B8a | `hang plant` | 04:22:35 | 2.18 | rc=0 |
| B8b | `kill plant` | 04:22:48 | 2.07 | rc=0 |
| B8c | `fuel plant` | 04:26:16 | 17.64 | rc=0 |

Every lane at rc 0 on the FIRST pass, the gcc second-oracle lane included:

```
SUMMARY: total=1963 compared=1885 agree=1873 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 triaged_ub=1
Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK
```

ZERO movement on every sequential lane (charter E3 for this slice): under
`CM_sequential` the sb/asw walkers, the join annotation and the procedure-
entry annotation are the identity, and the debug lines are CM_sc-only.

## 4. Decisions in this slice ([AGENT], within the approved charter and review)

- Verdict order races-then-bridge (§0). Consumer-visible: a racy program's
  outcome list is the UB005 kill, never an inconsistency kill.
- `MI_sc_inconsistent` carries the failing LEAF NAME (data: the library's
  own leaf label), per review Q2's "data, not free text".
- Location equality is the memory model's pointer-value equality
  (`cmm_aux.lem` instantiates `location = Mem.pointer_value`, footprints are
  the upstream `FOOTPRINT` dummy): mixed-size overlapping accesses to the
  same object are NOT related as races in Phase 0 — recorded limitation
  (TODO), inherited from the axiomatic model's instantiation, not this slice.
- `dd` stays empty (as upstream always had it); `lo`/`tot` empty (no locks).
- Create/Alloc/Kill are not model events (SC_condition excludes them);
  their aids still tag continuations (harmless: `symUpdatePreEx` drops
  aids that name no recorded action).
- SeqRMW's whole-thread-state tagging is the one sb over-approximation,
  confined and recorded (no litmus row uses it; Phase 1 revisits with the
  reduction of SeqRMW itself).
- Debug lines (SB-TAG, SC-RECORD, "SC candidate execution") at level 2,
  `DB_concurrency`, CM_sc only — byte-neutral for every sequential run.

## 5. Provenance

[USER 2026-09-04]: the charter approval; "great, continue" (2026-09-05).
[AGENT, refined-cerberus]: the review answers. [AGENT, this branch]:
everything else; quoted blocks are verbatim outputs from this worktree.
