# Concurrency Phase 0 — slices S1+S2 record: the model selector and the SC instance (2026-09-04)

Charter: `2026-09-04_concurrency-phase0-sc-charter.md` (APPROVED [USER
2026-09-04]); interface review + acceptance:
`2026-09-04_concurrency-S1-interface-review-response.md` (D5 discharged);
consumer change manifest: `2026-09-04_concurrency-S1-change-manifest.md`
(+ `…S1-generated-diff.patch`). Branch `feature/concurrency`, rebased onto
mainline `753644005` (fuel arc C1) before this slice. Author [AGENT].

S1 and S2 land as ONE commit ([AGENT] decision): a `CM_sc` that exists but
has no scheduler would have needed a temporary "not implemented" refusal
constructor, a throwaway shape the consumer would have re-pinned against.
Gate for the slice (charter §6): FULL (`.lem` bodies + signatures changed;
cache-disabled regeneration).

## 1. What landed (files; cites are post-change)

- `frontend/model/core_run_aux.lem:37` — `type concurrency_model =
  CM_sequential | CM_sc` (payload-free); `add_to_sb/_stack`,
  `add_to_asw/_stack` take the selector; the four
  `Global.using_concurrency ()` reads are GONE from the model.
- `frontend/model/core_run.lem` — `kill_thread model …`; the legacy
  `core_action_step`/`core_thread_step2` family (no live caller) threads
  the selector too.
- `frontend/model/driver.lem` — `model_refusal` :61, `model_inconsistency`
  :68, `driver_error` +2 constructors :71; the F_SC scan
  `sc_action_check` :89 … `model_check_file` :192, `sc_fragment_ok` :232,
  `epar_free` :235; the generated renderers `string_of_model_refusal`
  :207 / `string_of_model_inconsistency`; `perform_action_request2 model`
  :925 (the `CM_sc` arm = the concrete memory as value store; S3 fills
  it); `can_advance model multi_threaded` :1099 (memory actions/memops are
  scheduling points under `CM_sc` iff ≥2 threads exist);
  `find_can_advance` :1253; `advance_step model` :1136 (spawn under
  `CM_sequential` → `DErr_model_inconsistent MI_spawn_after_scan`,
  :1221); `drive_nonmemory_steps_aux2 model` :1266 (the per-thread read
  returns `(multi_threaded, steps)`, :1279); `new_drive_core_threads
  model` :1482 with the identical-blocked-steps collapse :1495;
  `process_core_step2`/`driver2`/`driver_globals`/`drive` take the model;
  `drive` :1946 opens with the entry scan (`DErr_model_refused`, :1954)
  and keeps the historical tail bind shape (:2110-2125, comment).
- `frontend/model/mini_pipeline.lem:72` — the const-expr mini-run selects
  `CM_sequential` (single-threaded by construction).
- OCaml: `backend/driver/main.ml` (`--concurrency=sc`, cmdliner enum;
  `set_cerb_conf ~concurrency:(model <> CM_sequential)` for the legacy
  global's remaining readers), `backend/common/driver_ocaml.{ml,mli}`
  (`driver_conf.concurrency : Core_run_aux.concurrency_model`; the two
  new error arms call the generated renderers), `backend/common/smt.ml`
  (exhaustive match arms), `backend/web/instance.ml` (`CM_sequential`).
- Lean seams: `Main.lean` (`--concurrency=sc` parsed anywhere after the
  mode flag → `runPipeline … model …` → `drive tagDefs model …`; the two
  error arms in the batch and human printers; `refuseFlag`'s
  `--concurrency` text now names the selector), `CerbCall.lean`
  (`driveCall` stays `CM_sequential`: the `--call` harness mode is
  sequential by construction — its own decision, recorded here),
  `test/Unit/FuelExemplar.lean` (bool→selector at 5 sites; `loop_step_done`
  steps the PAIR; `drive_after_setup` discharges the entry scan by
  `rw [show model_check_file CM_sequential exemplarFile = none from rfl]`
  + `dsimp only`; NEW kernel-computability pins: `sc_fragment_ok
  exemplarFile = true := rfl`, `epar_free …`, `model_check_file
  CM_sequential exemplarFile = none := rfl`), `speclab/test/SLUnit/*` (5
  sites `false` → `CM_sequential`).
- Gates/lanes: `scripts/fork_drift_manifest.txt` (4 moved
  `[expected-semantic]` hashes + NEW `[files]` `backend/common/smt.ml`,
  dated NOTE; hand-edited — the `--refresh` recipe strips the documented
  header and was NOT used wholesale, per the manifest's own arc-14 note);
  `scripts/test_litmus.sh` (every row under `--concurrency=sc`;
  `REFUSE_RE=^model refused: `; the SEQ leg pins the sequential model's
  spawn refusal on one file); `tests/litmus/before_baseline.txt`
  re-recorded (§3); `tests/litmus/sc_reference.py` prints tokens in the
  lane's canonical (bytewise) order; `scripts/LADDER.md` row 12 text;
  `VALIDATION.md` (the flag passage + the boundary sentence); `TODO.md`
  (the concurrency entry).

## 2. Measurements (verbatim; both engines unless stated)

### 2.1 The SC instance on the probes (oracle `--concurrency=sc`, exhaustive; Lean identical)

    SB+sc_sc+sc_sc.c   : 4×Specified(1) 4×Specified(2) 12×Specified(3)   -- 20 traces = 6!/(3!3!)
    LB+sc_sc+sc_sc.c   : Specified(0), Specified(1), Specified(2)
    WRC+sc+sc_sc+sc_sc : Specified(0),(1),(4),(5),(7)                     -- 336 traces, 0.07 s
    IRIW+sc+…          : {0..15} \ {5}                                     -- 6300 traces = 10!/(4!4!), 1.05 s
    MP+na+na.c         : Specified(0), Specified(1)                        -- no race verdict yet (S3)
    LB+rlx_rlx+…       : Error {msg: "model refused: atomic memory order Relaxed is outside the SC fragment (seq_cst only)"}
    SB+sc_sc (no flag) : Error {msg: "model refused: thread spawn (par) under the sequential model; select --concurrency=sc"}
    --concurrency (bare) / --concurrency=c11 : cmdliner "invalid value …, expected sc" (oracle); Lean Z-24 refusal naming the selector

### 2.2 FINDING (fixed in this slice): the k^rounds scheduler redundancy

Before the collapse in `new_drive_core_threads`: SB 496 traces
(3 outcomes), WRC 218,484 traces in 23.4 s, IRIW UNFINISHED at 300 s and
15 GB RSS. Cause (oracle `-d5`, verbatim): `picking step for thread(0)
size: 2 ==> [Step_blocked2; Step_blocked2]` — the parent waiting on k
children carries k identical blocked steps and `ND.pick` branched over
them every round. After: SB 20, WRC 336 (0.07 s), IRIW 6300 (1.05 s) —
exactly the interleaving counts; outcome SETS unchanged. Upstream-facing
(the driver has had this since the reduction-context rewrite); tray
candidate noted in TODO.md.

### 2.3 FINDING (fixed in this slice): the tail's bind association

The first cut of the `drive` tail wrote `driver2 model >> ND.get >>= …`;
lem's `>>`/`>>=` are left-associative, so the outermost bind's first
component changed type (unit → driver_state). Effect: the exemplar's
symbolic step `runOne_bind_active (z := ())` stopped unifying first-order
and Lean fell back to unfolding the whole driver term — `fuel-exemplar-test`
went from ~2 s to an OOM kill at 32 GB (bisected with `#exit`/prefix
probes under an 8 GB cap: steps 1–8 of `drive_after_setup` in 2 s, step
9 — the driver2 bind — killed at 27 s). Fixed by parenthesising the tail
(`driver.lem` comment at the site). Lesson recorded for the consumer's
manifest (§4): the bind SHAPE of `drive` is part of the interface.

### 2.4 The scan is kernel-computable

Probes (`lean_probe.sh`, 6 GB cap): `(model_check_file CM_sequential
exemplarFile).isNone = true := by decide` 1.32 s; `… := by decide
+kernel` 1.25 s; `model_check_file CM_sequential exemplarFile = none :=
rfl` 1.25 s (whole-file elaboration times incl. imports). The three
`rfl` pins in `FuelExemplar.lean` are the standing gate. lem emitted the
mutual triple as plain `def`s (no `partial`, no `termination_by`, no
fuel) under `declare {lean} termination_argument … = automatic`; the
`fuel_measure` fallback the charter allowed was NOT needed.

### 2.5 Gates

**Tier A row 1 — `./scripts/test_unit.sh`** (on the fully rebuilt library, `lake build` default targets, 365 jobs), verbatim key lines:

```
Total: 6 passed, 0 failed
check_exec_purity: CLEAN (11 modules)
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_theorem_axioms: generated-tree census OK (196 files: 0 axioms, boundary-opaque population = the 26 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
check_theorem_axioms: C2 ratchet OK (301 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 66 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
check_no_fuel_numerals: OK (267 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6); allowed Main.lean sites seen: 4 of 4 (hand-written + generated copy))
gen_fuel_parametricity: OK (64 ambient fuel wrappers in the generated tree = the 64 pins of TotalityProofTest.lean Part 1, both directions)
check_lakefile_roots: OK (195 roots = 195 generated modules + the exe root Main; 85 auxiliary modules all built)
check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
check_lem_sync: OK (src 16f73114b56114de297233bf6cd5088cef2ccfc87115e3af43d3f804816f54a2, gen 0efcf7ed00a35381f8a451cc4db9cb1c60c7c0f6c3b889611507ed01a0790055)
check_lem_sync: lean OK (src 16f73114b56114de297233bf6cd5088cef2ccfc87115e3af43d3f804816f54a2, gen 1809d3d8a6d191e4cfaef284bf1e7564c6676defe8f833d8f5b98915812b1440)
check_fork_drift: OK — layer 1: 72 oracle-surface files = manifest; layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
rc=0
```

The `fuel-exemplar-test` exe (with the three new `rfl` pins and the
adapted proofs) is among the 6 passed. Two gate episodes on the way,
both fixed before this run: the D14 token scan flagged the WORD
`native_decide` inside the pin's doc-comment (reworded); the FUEL-arc
axiom leg found the `*_lemMeasureProofs` modules UNBUILT in this worktree
(the exe target does not import them and the primed oleans predated the
regeneration) — a full `lake build` (default targets) is part of the
recipe for this gate, recorded here for the next worker.
**Litmus lane** (`scripts/test_litmus.sh`, every row under `--concurrency=sc` on both engines):

```
### litmus --check-before
SUMMARY: mode=before programs=24 engine_disagreements=0 baseline_mismatches=0 seq_leg_fail=0 red_classes=none
ALL ROWS AT baseline
### litmus --check (target; S3/S4 rows red by design)
[MATCH] SEQ leg (SB+sc_sc+sc_sc.c, no model flag): both engines refuse ("model refused: thread spawn (par) under the sequential model; select --concurrency=sc")
SUMMARY: mode=check programs=24 engine_disagreements=0 target_mismatches=9 seq_leg_fail=0 red_classes=RMW SC
LITMUS LANE FAILED
### litmus --plant
plant (a) corrupted row 'coherence+init+sc_sc.c': mismatches=1 (want >=1)
plant (b) empty corpus: failures=25 (want >=1)
PLANTS TRIPPED (lane is not vacuous)
```

Under `--check` the 15 green rows are every SC multi-outcome row (SB, LB,
WRC, IRIW, hb-mo-cycle, MP+na_sc+sc_na, both coherence rows,
datarace+Rna+Rna), every NONSC refusal row (6, identical text on both
engines) and the SEQ leg; the 9 red rows are exactly the five race rows
(S3: race detection) and the four `RMW-*` rows (S4: the reduction rules).
**The sequential battery — FULL gate (Tier A rows 2–11 + Tier B rows 1–8, `scripts/LADDER.md`), serial, 2026-09-04 23:12–2026-09-05 00:01 UTC, verbatim per-lane return codes (first pass):**

| row | lane | start | rc |
|---|---|---|---|
| A2 | `test_exec minimal` | 23:12:37 | rc=0 |
| A3 | `test_exec coverage` | 23:12:51 | rc=0 |
| A4 | `test_exec debug` | 23:13:18 | rc=0 |
| A4b | `test_exec float` | 23:13:34 | rc=0 |
| A4c | `test_bytes` | 23:13:43 | rc=0 |
| A5 | `test_libc_exec` | 23:13:46 | rc=0 |
| A6 | `test_multi_tu` | 23:14:08 | rc=0 |
| A7 | `test_parse minimal` | 23:14:10 | rc=0 |
| A8 | `test_core minimal` | 23:14:20 | rc=0 |
| A9 | `test_elab` | 23:14:29 | rc=0 |
| A10 | `test_libxml2_uri` | 23:14:45 | rc=0 |
| A11 | `test_cn_coverage` | 23:14:57 | rc=0 |
| B1 | `test_libxml2` | 23:15:25 | rc=0 |
| B2 | `test_parse ci` | 23:27:44 | rc=0 |
| B3 | `test_core ci` | 23:28:07 | rc=0 |
| B4 | `test_verify` | 23:28:22 | rc=0 |
| B5 | `test_immaculate` | 23:29:06 | rc=0 |
| B6a | `speclab selftest` | 23:30:07 | rc=0 |
| B6b | `speclab plant` | 23:33:11 | rc=0 |
| B6 | `speclab divmod` | 23:33:13 | rc=0 |
| B6 | `speclab bytearr` | 23:33:28 | rc=0 |
| B6 | `speclab list` | 23:33:41 | rc=1 |
| B6 | `speclab tree` | 23:33:45 | rc=1 |
| B6 | `speclab seed` | 23:33:50 | rc=1 |
| B7 | `test_gcc_oracle` | 23:33:54 | rc=1 |
| B8a | `hang plant` | 23:56:49 | rc=0 |
| B8b | `kill plant` | 23:57:02 | rc=0 |
| B8c | `fuel plant` | 00:01:21 | rc=0 |

Every Tier A lane and Tier B rows 1–5 and 8 at rc 0 (zero movement:
`test_exec` at its four baselines, bytes 9/9 + 5/5, libc_exec, multi_tu,
parse/core/elab, libxml2_uri 16/16, cn_coverage 213/213, libxml2 full,
parse/core ci, verify, immaculate, the three plant batteries). Two rows
needed a second look:

- **B6 speclab list/tree/seed rc=1 (first pass)**: `speclab-*-core-test
  build failed` — the three SLUnit gate tests carry an EXHAUSTIVE `match`
  on `driver_error` and lacked the two new constructors (the divmod and
  bytearr tests do not match on it). Fixed (two arms each, rendering via
  the generated `string_of_model_*`); re-run 2026-09-05 00:05 UTC at box
  load ~8, all seven speclab lanes verbatim:

```
test_speclab: PASS (both pipelines agree on Specified(0))      -- --selftest
test_speclab: PASS (both pipelines agree on Specified(2))      -- --plant
test_speclab_divmod: PASS (--gate)
test_speclab_bytearr: PASS (--gate)
test_speclab_list: PASS (--gate)
test_speclab_tree: PASS (--gate)
test_speclab_seed: PASS (--gate)
```

- **B7 test_gcc_oracle rc=1 (first pass)**, verbatim:

```
REGRESSION: csmith/sa_csmith_85.c baseline=AGREE/O2_AGREE current=SKIP_LEAN_TIMEOUT/-
Baseline check: 1 regression(s), 0 improvement(s)
```

  This is the lane's documented load-sensitive class (`LADDER.md` Tier B
  row 7 / the script header: "a REGRESSION whose only movement is into
  SKIP_LEAN_TIMEOUT is re-run on a quiet box before it is read as red";
  the very same row is the header's example). Box load during the first
  pass: 1-min average 51 at 00:00 UTC (other agents' work; this branch
  ran one serial lane). A/B on the staged file (same `--cabs-json`
  output, `--batch --first`, `CERB_MEM_MAX=4G`, back to back, load 35–50):

```
MAINLINE round1 wall=26.79s rss=135040KB      S1S2 round1 wall=26.40s rss=125568KB
MAINLINE round2 wall=21.68s rss=137704KB      S1S2 round2 wall=16.61s rss=129656KB
(all four: Defined {value: "Specified(248)", stdout: "", stderr: "", blocked: "false"})
```

  No slowdown is attributable to this slice (mainline = the primary
  checkout's binary at `753644005`). The lane was re-run at load ~7:

```
### B7 test_gcc_oracle (re-run)  [00:06:14] load=7.09
    TRIAGED_UB: 1

SUMMARY: total=1963 compared=1885 agree=1873 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 triaged_ub=1

Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-feature/concurrency/scripts/gcc_oracle_baseline.txt

Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK
rc=0
```

With that, every row of Tier A and Tier B is at rc 0 on this slice's head: the FULL gate holds; the sequential corpora are at ZERO movement (charter exit criterion E3 for this slice).

## 3. The litmus pin, re-recorded

`tests/litmus/before_baseline.txt` re-recorded by `--record-before`
(24 rows, both engines in agreement — a disagreement would have refused to
write). Movement vs the S0 pin (DERIVED from the two files): 16 rows
moved, 8 unchanged.
- 10 SC rows: from ONE serialized verdict to the SC instance's outcome
  set — the six multi-outcome rows now equal their `expectations.txt`
  targets (e.g. `SB+sc_sc+sc_sc.c {Specified(1)}` →
  `{Specified(1),Specified(2),Specified(3)}`; `IRIW…` → the 15-element
  set), the four race rows widen to their SC value sets but still carry
  no race verdict (`datarace+Wna+Wna.c {Specified(1)}` →
  `{Specified(1),Specified(2)}`; `MP+na+na.c {Specified(0)}` →
  `{Specified(0),Specified(1)}`) — S3 turns these into `UB005_data_race`.
- 6 NONSC rows: from a serialized verdict (or, for `fence+sc_sc.c`, the
  matched internal error) to `{ERROR}` with the typed refusal text.
- unchanged: `coherence+sc_sc_sc.c`, `coherence+init+sc_sc.c`,
  `datarace+Rna+Rna.c`, `datarace+Rna+Rna_Wna.c` (their single SC value
  happens to equal the old serialized verdict) and the four `RMW-*` rows
  (still the matched `TODO[Core_reduction]` internal error — S4).
The README's "Reading `before_baseline.txt`" section carries the
per-slice reading.

## 4. Decisions in this slice ([AGENT], within the approved charter and the accepted review)

- S1+S2 as one commit (above).
- `multi_threaded` := "at least two threads EXIST" (not "are runnable"):
  conservative (a waiting parent counts), sound for SC (a single-option
  pick adds no outcome), and it makes the `Epar`-free agreement lemma an
  invariant proof (thread count stays 1) rather than a bisimulation.
- Memops are scheduling points under `CM_sc` like memory actions
  (correctness first; a reduction is a measured, reviewed decision for
  later, not this slice's).
- The identical-blocked-steps collapse is pattern-based (no equality on
  `core_step2`, which carries closures) and changes trace MULTIPLICITY
  only; the sequential lanes compare verdict sequences of single-thread
  programs, which never hit it (zero movement, §2.5).
- `--call` mode (`CerbCall.driveCall`) stays `CM_sequential`; extending the
  call harness to a model selector is not asked for.
- `Cerb_global.concurrency_mode` (OCaml) keeps receiving a bool derived
  from the selector for its remaining non-model readers; no `.lem` reads
  it any more.

## 5. Provenance

[USER 2026-09-04]: charter approval; the "handle carefully" ruling.
[AGENT, refined-cerberus]: the review answers (recorded verbatim).
[AGENT, this branch]: everything else; quoted blocks are verbatim outputs
from this worktree on 2026-09-04. Ephemeral scratch used: the worktree's
`.tmp/` (probe files, logs, the base generated tree for the diff) —
deleted at slice end.
