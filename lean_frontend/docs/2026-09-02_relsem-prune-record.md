# Prune record: the RelSem relic leaves mainline (2026-09-02)

STATUS: prune-worker record; branch `prune/relsem`, base mainline
`2c7c9347b` (the LAST mainline commit carrying `lean_frontend/relsemcore/`).
Provenance: the ruling is [USER]; the reading of the ruling, the
inventory classification, the relocation design and the plants are
[AGENT] (orchestrator brief + this worker), operator-overridable.
Quoted outputs are verbatim; tallies marked "derived" are derived.

## 0. The ruling and its reading

[USER 2026-09-02], verbatim: "the RelSem semantics is still sitting on
main. It's a relic from the reasoning era, it should have been killed
along with the other reasoning-era artifacts (i.e left on the branch).
The only canonical semantics should be the cerberus opsem".

[AGENT] reading (orchestrator's, adopted here; operator-overridable):
what dies is the RELATIONAL/REASONING framing and the `RelSem`
namespace/package; what survives is any plain OPERATIONAL entry the
semantics-era instruments need — "run this Core function with these
arguments from a driver state" is opsem, not reasoning — relocated as
plain hand-written code in the opsem layer with NO
Iris/relational/adequacy/harness-theorem residue. The relocation
turned out to be mechanical (§2): the call entry never depended on the
relational machine (its imports of `RelSem.Machine/RunND/ExecModel/
Cerberus` were dead — the relocated module compiles against `Driver` +
`Core_aux` alone). No STOP-AND-REPORT condition arose.

Archaeology pointer: the full reasoning-era version of everything
removed here is on branch `arc/segment-ladder`, tag
`park/reasoning-era-20260831` (the 2026-08-31 park record:
`docs/2026-08-31_semantics-first-split.md`, which kept `relsemcore/`
"per scoping" with an "honest residue" note — this record closes that
residue).

## 1. Inventory — every definition in `lean_frontend/relsemcore/` (5 files, 1727 lines)

Classification: DEAD = reasoning-era construct, deleted with the
package; RELOCATE = needed by a semantics-era instrument, moved as
plain code.

### `RelSem/Call.lean` (218 lines) — RELOCATE, all 9 defs

| RelSem name | Verdict | Post-prune name |
|---|---|---|
| `RelSem.Cerb.intValue` | RELOCATE | `CerbCall.intValue` |
| `RelSem.Cerb.funSymsNamed` | RELOCATE | `CerbCall.funSymsNamed` |
| `RelSem.Cerb.injectArg` | RELOCATE | `CerbCall.injectArg` |
| `RelSem.Cerb.injectArgs` | RELOCATE | `CerbCall.injectArgs` |
| `RelSem.Cerb.resolveFunSym` | RELOCATE | `CerbCall.resolveFunSym` |
| `RelSem.Cerb.lookupFunBody` | RELOCATE | `CerbCall.lookupFunBody` |
| `RelSem.Cerb.lookupParamTys` | RELOCATE | `CerbCall.lookupParamTys` |
| `RelSem.Cerb.callFinish` | RELOCATE | `CerbCall.callFinish` |
| `RelSem.Cerb.callND` | RELOCATE | `CerbCall.driveCall` (the `--call` entry; census entry name) |

Consumers (semantics-era instruments): `Main.lean` (`--call`),
`scripts/test_verify.sh` (43 call-point rows of the 117-check lane),
`scripts/check_theorem_axioms.sh` (C2 entry census, 9 entries).

### `RelSem/Machine.lean` (602 lines) — DEAD, all

`Outcome`, `MExpr`, `Config`, `toVal`, `ofVal`, `toVal_ofVal`,
`ofVal_toVal`, `app`, `CsSem`, `CsSem.exhaustive`, `CsSem.ofEval`,
`Step`, `Steps`, `Steps.single/trans/head`, `step_nd_return`,
`step_kill`, `val_stuck`, `done_irreducible`, `app_ifM`,
`app_addConstraints`, `step_ifM_then/else`, `step_addConstraints`,
`step_ifM_inv`, `app_bindFuel_active`, `app_bind_active`,
`step_bind_active`, `app_liftFuel_active`, `app_liftND_active`,
`liftKill`, `app_liftFuel_killed`, `app_liftND_killed`,
`app_nd_return/kill/nd_get/nd_put/nd_update/nd_read/print_debug`,
`app_nd_guard_true/false`, `app_pick_singleton`,
`app_bindFuel_killed`, `app_bind_killed`, `step_bind_killed`,
`step_done_inv`, `step_done_value_inv`, `step_done_killed_inv`,
`step_running_active_inv`, `step_running_killed_inv` — the generic
relational ND machine (the Layer-2 step relation the Iris coupling
sat on). Derived tally (`grep -cE '^(def|abbrev|structure|inductive) '` / `'^theorem '` on the deleted files): 12 defs/types + 40 theorems.

### `RelSem/RunND.lean` (356 lines) — DEAD, all

`Outcome.ofStatus`, `RunResult`, `runND_wrapper_defeq`,
`runNDFuel_zero`, `mem_foldl_prepend`, `runNDFuel_sound`,
`runND_sound`, `runNDFuel_mono`, `runNDFuel_active/killed`,
`runND_active/killed`, `Behaviors`, `behaviors_active_iff`,
`behaviors_killed_iff`, `behaviors_sound` — runner-vs-relation
soundness (the "the executable and the proof object are the same
artifact" bridge). Derived tally: 3 defs + 13 theorems.

### `RelSem/ExecModel.lean` (95 lines) — DEAD, all

`ExecModel` (structure), `ExecModel.Adequate`, `ExecModel.UBFree`,
`Adequate.mono`, `Adequate.and`, `ubFree_iff` — the
model-parametricity interface for adequacy statements. Derived tally:
3 defs + 3 theorems.

### `RelSem/Cerberus.lean` (456 lines) — DEAD, all

`DriveExpr`, `DriveConfig`, `γexh`, `DStep`, `DSteps`, `initConfig`,
`pick_steps_head/second`, `liftMem_step_active/killed`, `PexprStep`,
`step_eval_pexpr_wrapper_defeq`, `driver2_wrapper_defeq`,
`step_eval_pexpr_val_fuel_indep`, `step_eval_pexpr_val_erase`,
`pexprStep_val`, `RunNDActiveSound` (+ theorem `runNDActiveSound`),
`DriveReaches`, `HarnessAdequate`, `DriveBehavior`, `behaviorOfRun`,
`seqModel`, `seqModel_behavior_sound`,
`seqModel_behavior_running_active_iff/killed_iff`,
`seqModel_adequate_of_reach`, `HarnessAdequateM`, `HarnessUBFree`,
`heapOf`, `PointsToByte`, `pointsToByte_functional`, `OwnsAlloc` —
the driver-level instantiation, fuel-erasure lemmas, adequacy
statement shapes, and the points-to base for the Iris heap. Derived tally: 18 defs/abbrevs + 15 theorems.

### Totals (derived)

RELOCATED: 9 definitions (one file). DEAD: 36 defs/types + 71 theorems across four files (derived, same grep). Nothing else in the repo referenced any
DEAD name (verified by `git grep` before deletion; the only code
references to the package were `Main.lean`'s `import RelSem.Call` +
two `RelSem.Cerb.*` uses, and the census script's probe).

### Adjacent relic found during inventory — `initial_core_run_state_seeded`

`frontend/model/core_run_aux.lem` carried a Lean-target-only
(`~{ocaml}`) def `initial_core_run_state_seeded (seed : nat) xs`
(Thread-B, 2026-08-29) whose documented sole purpose was agreement BY
THEOREM with the (already parked) `RelSem.Cerb.
initial_core_run_state_threaded` twin. `git grep` over all `.lem`,
`.lean`, `.sh` and non-docs `.md`: zero consumers. [AGENT] verdict:
reasoning-era statement face, deleted with the package (def + its
comment). The OCaml side is unaffected BY MEASUREMENT: after
regeneration `ocaml_frontend/generated/` is byte-identical to the
mainline primary checkout's tree (`diff -rq`, whole tree) and the
fork-drift gate is green with its pins untouched (§4). NOTE for future
`.lem` edits, learned here the loud way: a free-standing lem comment IS
emitted into the generated OCaml (a comment attached to a `~{ocaml}`
def is dropped with it) — my first attempt left a replacement comment
and the fork-drift gate correctly FAILED (`core_run_aux.ml:
excused-diff hash moved`); the fix was to leave no trace in the
`.lem`, with the deletion recorded here instead.

## 2. Relocation — `lean_frontend/CerbCall.lean`

A hand-written seam at the top level (copied into `generated/` by the
manifest recipe like every other seam), root `CerbCall` in the
`CerberusLean` lib, namespace `CerbCall`, imports `Driver` +
`Core_aux` only. Semantics verbatim from `RelSem/Call.lean`; the only
textual changes are the namespace, `callND` → `driveCall`, the
error/location strings (`"callND: …"` → `"driveCall: …"`,
`"RelSem.callND"` → `"CerbCall.driveCall"`) and the header.

Naming: `driveCall` is "`drive` started at a designated function" —
it is `drive` (driver.lem:1727 / generated Driver.lean:518) with (a)
the startup symbol resolved by NAME over `file.funs` instead of
`file.main` and (b) `prepare_main_args` (Driver.lean:488) replaced by
the elaborated-call-site caller protocol for the parameters.

Mirror-OCaml doctrine: the OCaml driver (`backend/driver/main.ml`,
`backend/common/pipeline.ml`) has NO call-a-function-by-name mode —
checked, none. `CerbCall` is therefore documented in-code as a
PORT-SIDE HARNESS ENTRY (deliberate divergence), and the differential
lanes compensate by running the ORACLE on a rendered wrapper TU
(`int main(void) { return f(args); }`, `test_verify.sh
render_wrapper`) — so every `--call` verdict is still oracle-checked
(the lane's three-way agreement: Lean `--call` == oracle wrapper ==
recorded pin).

Rewired consumers:

| Where | Before | After |
|---|---|---|
| `lean_frontend/Main.lean` | `import RelSem.Call`; `RelSem.Cerb.callND … (argInts.map RelSem.Cerb.intValue)` | `import CerbCall`; `CerbCall.driveCall … (argInts.map CerbCall.intValue)` |
| `lean_frontend/lakefile.toml` | `defaultTargets` incl. `"RelSemCore"`; `[[lean_lib]] RelSemCore` (srcDir `relsemcore`, 5 roots) | lib block deleted; `"CerbCall"` added to `CerberusLean` roots |
| `lean_frontend/handwritten_copy.manifest` | 21 files | 22 files (+ `CerbCall.lean`) |
| `scripts/check_theorem_axioms.sh` | `ENTRIES=(… RelSem.Cerb.callND)`, probe `import RelSem.Call`; D14 grep scans `lean_frontend/test` + `lean_frontend/relsemcore` | `ENTRIES=(… CerbCall.driveCall)`, probe `import CerbCall`; D14 grep scans `lean_frontend/test` + the top-level hand-written `lean_frontend/*.lean` seams (fail-closed on an empty set) — strictly wider than before: the mem-scale S1 theorems live in `CerbMem.lean` |
| `scripts/test_verify.sh` | header cites `RelSem.Cerb.callND` | cites `CerbCall.driveCall` (no logic change) |
| `scripts/check_exec_totality.sh` | comments justify CerbND/State-module totality via RunND/T1 theorems | comments restate totality as an opsem property in its own right |
| `scripts/lean_probe.sh` | header narrates the RelSem two-package prefix split | header keeps the recipe + the general prefix-split hazard; history pointer to the park tag |
| `scripts/test_immaculate.sh` | "NOT a RelSem import" aside | reworded (root-package probe) |
| `tools/check_driver_fresh.sh` | lean source hash included `relsemcore/**.lean` | `relsemcore` dropped (top-level `*.lean` already covers `CerbCall.lean`) |
| `.gitignore` | `lean_frontend/relsem/.lake/` | line removed |
| `frontend/model/core_run_aux.lem` | `initial_core_run_state_seeded` + RelSem-justifying comment | deleted (§1) |
| Hand-written seam comments (`CerbFunMapInstances`, `CerbMem` ×3, `CerbND`, `CerberusFresh`) | cite RelSem files/audits as the tripwire or consumer | cite the surviving gate (`check_theorem_axioms.sh`) or the park tag; no semantics change |
| speclab (`DivModFiles.lean`, `SLUnit/CoreGateTest.lean`), `tests/cn_coverage/README.md` | attribute patterns to "the relsem package" | attribute to the parked reasoning-era package by tag |
| Front docs `README.md`, `DESIGN.md`, `VALIDATION.md`, `CLAUDE.md` | describe `RelSemCore`/`relsemcore/` as part of the semantics package | post-kill truth: one semantics, `CerbCall.lean` as a seam, pointer to this record + the park tag |

## 3. Deletion

`git rm -r lean_frontend/relsemcore` (5 files). Orphaned build
artifacts purged from the primed `lean_frontend/.lake/build/{ir,lib}`
— NOTE: the primed tree still carried artifacts of the PRE-SPLIT
`relsem` proof package as well (`RelSem/T1AppEq`, `RelSem/IrisState`,
`RelSem/SlateWP`, `RelSem/T5Prefix`, …), i.e. the 2026-08-31 split
left stale artifacts in the primary checkout's `.lake`; all
`*RelSem*` paths under `.lake/build` are now gone here (0 remaining).

Residue check, `git grep -n -i relsem -- ':!lean_frontend/docs'`,
after the edits: every surviving hit is either (a) a pointer to this
record's filename or to `docs/2026-08-19_relsem-spike.md` (the
totalization ruling's source, cited from `CerbND.lean`), (b) a
"removed 2026-09-02" note (`check_theorem_axioms.sh` header/D14
comment, `CLAUDE.md`, `DESIGN.md`), or (c) the dated lembugs record
`lean_frontend/lembugs/2026-08-20_daemon-inconsistent-axiom.md`
(history, left as-is), or (d) `CerbCall.lean`'s own HISTORY paragraph
naming its former name. ZERO code, script or config dependencies on
any RelSem name remain (the build has no `RelSem` module; `lake build`
of the default targets and of every test exe is green without one).

The complete post-prune hit list outside `lean_frontend/docs` and
`lean_frontend/lembugs` (`git grep -n -i relsem -- ':!lean_frontend/docs' ':!lean_frontend/lembugs'`, verbatim, paths/lines):

```
lean_frontend/CLAUDE.md:30:  NO second semantics package: the reasoning-era `RelSemCore` lib was
lean_frontend/CLAUDE.md:31:  removed 2026-09-02 (`docs/2026-09-02_relsem-prune-record.md`; park
lean_frontend/CLAUDE.md:228:| `CerbCall.lean` | The `--call <f> [--call-args <ints>]` entry (`CerbCall.driveCall`): `drive` with the startup symbol re
lean_frontend/CerbCall.lean:43:  HISTORY: born 2026-08-20 as `RelSem.Cerb.callND` in the reasoning-era
lean_frontend/CerbCall.lean:44:  `relsemcore/` package; relocated here verbatim-in-semantics on
lean_frontend/CerbCall.lean:47:  Record: docs/2026-09-02_relsem-prune-record.md; the reasoning-era
lean_frontend/CerbND.lean:19:  docs/2026-08-19_relsem-spike.md): the former `partial def runND`/
lean_frontend/DESIGN.md:143:  (`RelSemCore`) was removed from mainline on 2026-09-02 and lives on
lean_frontend/DESIGN.md:144:  the park branch (`docs/2026-09-02_relsem-prune-record.md`);
scripts/check_theorem_axioms.sh:38:# probes are the generated-exemplar + driver2 legs. 2026-09-02 RelSem
scripts/check_theorem_axioms.sh:39:# prune: the last reasoning-era package, relsemcore/, is gone too; the
scripts/check_theorem_axioms.sh:505:#     live; formerly lean_frontend/relsemcore/**, removed 2026-09-02),
```
## 4. Gates (verbatim)

### 4.1 Census, before (mainline `2c7c9347b`, this worktree, pre-edit)

```
check_theorem_axioms: generated-tree census OK (193 files: 0 axioms, boundary opaques present, 0 unsafeCast)
check_theorem_axioms: C2 ratchet OK (292 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 66 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in 2 tree(s) + LemLibTest.lean)
'RelSem.Cerb.callND' depends on axioms: [propext, Classical.choice, Quot.sound]
check_theorem_axioms: C2 entry census OK (9 entries, every cone ⊆ [propext, Classical.choice, Quot.sound])
```

### 4.2 Census, after

```
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_theorem_axioms: generated-tree census OK (194 files: 0 axioms, boundary opaques present, 0 unsafeCast)
check_theorem_axioms: C2 ratchet OK (289 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 66 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in 1 tree(s) + 22 hand-written seam files + LemLibTest.lean)
'CerbCall.driveCall' depends on axioms: [propext, Classical.choice, Quot.sound]
check_theorem_axioms: C2 entry census OK (9 entries, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: mem-scale S1 leg OK (6 C1/C3 equality theorems, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
```

Movement (derived): ratchet scan 292 → 289 files (−5 `relsemcore`,
+1 `lean_frontend/CerbCall.lean`, +1 its `generated/` copy);
generated-tree census 193 → 194 (the copy); D14 `2 tree(s)` → `1
tree(s) + 22 hand-written seam files`; entry list 9 → 9 with
`RelSem.Cerb.callND` → `CerbCall.driveCall`; seam population 66 → 66.

### 4.3 Verify lane, after relocation (pre-plant)

```
test_verify: 117 passed, 0 failed (23 fixtures, 22 call points, 14 corpus fixtures, 21 corpus points)
```

### 4.4 Plants (each: edit → `make lean-prelude-src` → `build_lean` → lane; then revert → rebuild → re-gate, §4.6)

PLANT A — semantic break of the relocated entry: in
`CerbCall.injectArg`, the pointer arm injected `intValue 0` instead of
the caller's value. Lane result (30 FAIL rows, one shown; the summary
verbatim):

```
FAIL t1_id: id(5) — pin Specified(5), lean Specified(0), oracle Specified(5)
…
test_verify: 87 passed, 30 failed (23 fixtures, 22 call points, 14 corpus fixtures, 21 corpus points)
```

Exactly the 30 value-dependent call points went red, each failing
THREE-WAY (Lean vs oracle wrapper vs pin); the 13 constant-result
rows (`add(0,0)`, `sum(0)`, the `p03`/`p12` harnesses, …) stayed
green, as they must. The differential is what caught it — not a
crash.

PLANT B — `sorry` in `CerbCall.resolveFunSym`'s no-match arm (inside
`driveCall`'s cone, off the happy path):

```
'CerbCall.driveCall' depends on axioms: [propext, sorryAx, Classical.choice, Quot.sound]
check_theorem_axioms: FAIL — C2 entry census: axiom outside the exact allowlist [propext, Classical.choice, Quot.sound]:
CerbCall.driveCall: sorryAx
```

(rc=1.) The exact-list gate fires on the RELOCATED name.

### 4.5 Oracle side unchanged (the `.lem` deletion)

```
check_fork_drift: OK — layer 1: 72 oracle-surface files = manifest; layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
```

plus `diff -rq` of `ocaml_frontend/generated` against the mainline
primary checkout: identical (whole tree). Oracle rebuilt
`DUNE_CACHE=disabled` after `make prelude-src`. (The oracle BINARY
hash differs per build because `tools/gen_version.ml` embeds `git
describe --dirty`; the generated-tree identity is the witness.)

### 4.6 Battery after the plant reverts (rebuild-after-revert)

Plants A and B reverted (no `PLANT`/`sorry` in `CerbCall.lean`), `make
lean-prelude-src` + `build_lean` re-run (263 jobs), then the full
LADDER.md Tier A + Tier B battery in one sequential run (ephemeral
runner under `.tmp/`, deleted at slice end; every lane rc=0). Summary
lines verbatim (the lane's own final line(s)):

```
check_handwritten_sync: OK (22 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
test_unit: rc=0 (5/5 exes + sync, purity, axiom, totality, lem-sync ×2, fork-drift, fixture-freeze gates; last leg:) test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
test_exec minimal:  SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0 / BASELINE OK
test_exec coverage: SUMMARY: total=199 match=174 ub_match=12 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0 / BASELINE OK
test_exec debug:    SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0 / BASELINE OK
test_exec float:    SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0 / BASELINE OK
test_bytes:         SUMMARY: exec_match=9 neg_pinned=5 fail=0 / ALL AT COMMITTED EXPECTEDS
test_libc_exec:     SUMMARY: match=7 diff=0 / ALL MATCH RECORDED BASELINE
test_multi_tu:      SUMMARY: total=2 match=2 fail=0 / ALL PASSED
test_parse:         Total: 106 / Success rate: 100% (of cerberus successes) / ALL PASSED
test_core:          Total: 106 / Success rate: 100% (of cerberus successes) / ALL PASSED
test_elab:          SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0  (rc=0: the recorded same/diff state)
test_libxml2_uri:   GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
test_cn_coverage:   BASELINE OK (213 entries, exact match)
test_verify:        test_verify: 117 passed, 0 failed (23 fixtures, 22 call points, 14 corpus fixtures, 21 corpus points)
test_immaculate:    OK: lane matches the committed post-S1 baseline (…)
test_speclab --selftest: test_speclab: PASS (both pipelines agree on Specified(0))
test_speclab --plant:    test_speclab: PASS (both pipelines agree on Specified(2))
test_speclab_divmod --gate:  CoreGateTest: ALL PASSED / test_speclab_divmod: PASS (--gate)
test_speclab_bytearr --gate: ByteArrGateTest: ALL PASSED / test_speclab_bytearr: PASS (--gate)
test_speclab_list --gate:    ListGateTest: ALL PASSED / test_speclab_list: PASS (--gate)
test_speclab_tree --gate:    TreeGateTest: ALL PASSED / test_speclab_tree: PASS (--gate)
test_speclab_seed --gate:    SeedGateTest: ALL PASSED / test_speclab_seed: PASS (--gate)
test_parse tests/ci: Total: 250 / Success rate: 100% (of cerberus successes) / ALL PASSED
test_core tests/ci:  Total: 250 / Success rate: 100% (of cerberus successes) / ALL PASSED
test_libxml2:        SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each) / ALL PASSED
```

No baseline moved. (Battery wall time, derived from the runner's file ctime and its final log line: launched 17:33:19Z → `BATTERY DONE 2026-09-02T17:52:44Z`, ~19 min for the whole Tier A + Tier B run incl. the rebuild and the 4-slice libxml2 battery — well below the tripwire.)

### 4.7 Tier C (reporting instruments, run at the orchestrator's request)

Both reporting-tier lanes were run at the orchestrator's request
("gcc/csmith at baseline"), `SKIP_BUILD=1` against the freshly stamped
binaries (the freshness gates verify the stamps on entry). Verbatim:

```
test_gcc_oracle --check-baseline (default corpus incl. the staged csmith tier):
SUMMARY: total=1953 compared=1880 agree=1871 agree_nd=0 triaged=9 disagree=0 o2_agree=190 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=44 triaged_addr=9
Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK
```

(~24 min wall; the lane's 1953-row skip ledger unchanged.)

The csmith corpus lane (1669 files, ~2.7 h full pass per LADDER.md)
was run as ONE shard, `--shard 1/6 --check-baseline` (the shard-aware
fail-closed baseline check) — a full pass was not run at this slice
[AGENT: grind-tripwire discipline; the 2026-08-31 split record made
the same call]:

```
test_csmith_corpus --check-baseline --shard 1/6:
SUMMARY: total=279 match=127 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=1 hang=0 cerb_skip=151 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
```

## 5. Consumer change-manifest (refined-cerberus)

Checked read-only at `/home/dev/projects/cerberus-lean-proj/refined-cerberus`
(Lake pin `.cerberus-ws/lean_frontend`). There is NO code dependency:
`grep -rn "import RelSem"` over the consumer's `.lean` files (excluding
`.lake`) returns nothing; neither Lake package requires `RelSemCore`.
Every reference is in comments/docs:

| Consumer site | Names referenced | Post-kill replacement |
|---|---|---|
| `cerberus-heaplang/CerberusHeapLang/Round.lean:22-28` ("THE RelSemCore DISCLAIMER") | `RelSemCore`, `RelSem.Machine.Step`, `runND_sound`, `HarnessAdequate` | NO replacement — reasoning-era constructs; the disclaimer's subject no longer exists in the semantics repo. The consumer's own `CerberusRound` is its reference relation (its own restatement). Suggested edit: replace the disclaimer with a one-line note that the semantics repo carries ONLY the operational engine (this record). |
| `RefinedCerberus/Audit.lean:8-9` (pattern attribution) | `relsem/RelSem/Audit.lean` (park branch) | Already points at the park branch; no change needed (historical attribution). |
| `cerberus-heaplang/README.md:310-311, 336, 386` ("Two presentations, one engine") | `relsemcore`, `RelSem` `Step`, `runND_sound`, `HarnessAdequate` | NO replacement — "two presentations" is no longer true of the pinned workspace once it pins past this prune: one presentation (the engine). Consumer's own restatement. |
| `cerberus-heaplang/docs/WALKTHROUGH.md:973` ("A bridge to the semantics repo's relsemcore spine … not imported, not claimed") | `relsemcore` | NO replacement — the non-claim becomes vacuous; may be deleted or kept as history. |
| `docs/DECISIONS.md:147` ("the trimmed relsemcore spine (runND_sound) survives core/semantics-first") | `relsemcore`, `runND_sound` | Statement is now false at the next pin: `runND_sound` does not survive; it is on the park branch. Register update is the consumer's call. |
| dated consumer records (`docs/2026-08-30_*`, `cerberus-heaplang/docs/2026-08-31_*`, `2026-09-01_*`, `2026-09-02_p6-notes.md`) | various | Historical; no action. |

Relocated name the consumer MAY want (it does not use it today):
`RelSem.Cerb.callND` → `CerbCall.driveCall` (`import CerbCall`);
`RelSem.Cerb.intValue` → `CerbCall.intValue`. Everything else the
consumer names has no replacement.

Pin note: this branch is NOT merged; the consumer's semantics pin (`scripts/semantics-pin.env`, `CERBERUS_LEAN_COMMIT=ddcfc919972a…`) predates it. The manifest above applies when the
consumer re-pins to a mainline that includes this prune.

(Shard 1/6 ~39 min wall; `TIERC DONE 2026-09-02T18:51:49Z`. The two
Tier C lanes together ran ~59 min, sequential, on standing differential
corpora — a measurement sweep, not a build/proof grind; noted against
the ~1 h tripwire for the orchestrator's awareness.)

## 6. Worktree / branch state at record time

Branch `prune/relsem` off `2c7c9347b`, worktree
`worktrees/cerberus-lean-prune/relsem`, one commit (this slice). NOT
merged, NOT pushed. Ephemeral runner dir `.tmp/prune/` deleted at
slice end (its logs are quoted above; `.tmp/` is gitignored). The
pre-merge audit ASK is the orchestrator's, per working practices.
