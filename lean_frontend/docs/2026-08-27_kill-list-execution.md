# The kill-list execution (2026-08-27)

STATUS: SLICE CLOSED at this record (the record ends the slice).
Provenance: [USER 2026-08-27] "execute on the kill list" — the
ratified §1 of the whole-project-assessment disposition
(`docs/2026-08-27_whole-project-assessment-disposition.md`);
item-by-item work order = the assessment's kill list
(`docs/2026-08-27_professor-whole-project-assessment.md` §3).
[AGENT] worker execution throughout, under the R3/R5 purge method
(fresh import scan, re-home-before-delete with texts unchanged,
same-commit gate re-registration, plant tests). Quoted outputs are
verbatim; tallies labeled derived.

## 0. Headline

The forbidden-strategy surface is GONE: all 26 registered
concrete-input theorems, the 4 parked concrete reproducers, the
16-theorem ambient slate with the whole chase-era machinery, the
per-fixture literal-address supply serving them, spec-lab's 23
sample/concrete statement Prop defs, and the exec-equation campaign
(CANCELLED, not parked — PROOF.md rewritten). The `runEffectful`
carrier register is pinned at ZERO: the residual boundary axiom is
now outside every theorem cone in the repository. What stands is
exactly the KEEP column: the quantified threaded slate T1–T5 at
byte-stable statements and trio-exact cones, the framework
(segment layer, heap RA, per-step language, registry, round
evaluator, kits), the spec-lab codec/model/family-∀ layer, and the
entire differential-test ledger.

## 1. Commits

- Commit 1 — `24987aa12` — THE DELTA DISPOSITION (assessment §6):
  Kit/Mem `readBytesFrom_writeBytesTo_within` SALVAGED (census
  327 → 328 [memRW 21], sweep 12404 → 12410); C9 rework + Lanes
  `within` arm + C9T + `.r6-scratch/` dropped; full Tier A green.
- Commit 2 — (this commit) — THE PURGE, one coherent commit
  (build-fatal-if-partial by design; full Tier A green, verbatim
  §8).

## 2. Deleted inventory (commit 2)

### 2.1 Files deleted (relsem package)

| Class | Files |
|---|---|
| Ambient statement files | `T1.lean` `T2.lean` `T3.lean` `T4.lean` `T4Defs.lean` |
| Ambient walk carriers (see §3 split) | the ambient halves of `T1AppEq/T2AppEq/T3AppEq` + all of `T4AppEq.lean` |
| Arc-7 Iris shell | `IrisLang.lean` `IrisState.lean` `IrisRules.lean` `IrisAdequacy.lean` `SlateWP.lean` |
| Transitional OwnP surface | `PerStepOwnP.lean` `PerStepRunner.lean` `PerStepSmoke.lean` `PerStepTacSmoke.lean` |
| Chase machinery | `Tactics/AppWalk.lean` `Tactics/WalkTrace.lean` `Tactics/AppEqAttr.lean` `Kit/AppEq.lean` + `test/Unit/AppWalkTest.lean` (+ its `[[lean_exe]]` and test_unit rows) |
| Concrete-input theorem files | `T6Probe.lean` `T7.lean` `T7Walks.lean` |
| The R6 corpus (all 14) | `Corpus/{E1,E2,E3,E4,E5,C4,C5,C3A,C3B,X7,X2,X3,Z1,C9}.lean` |

40 files git-rm'd; ~18,600 lines deleted repo-wide in the purge
commit (derived from `git diff --stat`; the 26 registered
concrete-input theorems + the ambient 16 + the OwnP/chase machinery
+ per-fixture supply).

### 2.2 Theorem-level deletions inside KEEP files

Every remaining `runEffectful` carrier (the no-cone register's 104
names) was deleted individually, checked against consumers:

- `relsemcore/RelSem/Call.lean`: the 9 ambient harness-adequacy
  bridges (`callReaches`, `callOutcomes_sound`,
  `callAdequate_of_reach`, `callHarnessAdequate_of_adequate`,
  `callHarnessUBFree_of_ubFree`, `callAdequate_of_app_active`,
  `callUBFree_of_app_active`, `callHarnessUBFree_of_app_active`,
  `callHarnessAdequate_of_app_active`). The DEFS (`callND`,
  `CallHarnessAdequate`, …) and the pure `ofStatus_value_inv` stay —
  threaded statement vocabulary.
- `relsemcore/RelSem/Threaded.lean`: the 3 ambient bridges
  (`initial_core_run_state_eq_threaded_ambient`,
  `initial_driver_state_eq_threaded_ambient`,
  `callHarnessAdequate_of_thr`).
- `relsem/RelSem/PerStepCall.lean`:
  `callHarnessUBFree_of_callHarnessAdequate` (sole consumer was
  PerStepOwnP).
- `T1/T2/T3Threaded.lean` tails: the deliberately-impure
  `T?_of_threaded` sanity bridges (the ambient statements they
  proved are deleted).
- Kit files: the dead `@[app_eq …]` attributes (23 occurrences,
  Kit/Round/Mem/Eval/Map) + the `AppEqAttr` imports — the DiscrTree
  index's only consumer was the deleted walker (arc-18 C0 finding,
  now executed); the LEMMAS all stay, registered in the C1 registry.

### 2.3 Spec-lab deletions

The concrete/sample statement class, fully enumerated (derived; the
assessment's "23" was its derived count of the same class — the
exact enumeration executed here is 30 statement Prop defs: DivMod 3,
ByteArr 5, ListAppend 8, TreeRot 11, CnSeed 3, spanning
`*SampleStatement`/`*SampleStreamStatement`/`*PlantHealthyClaim`/
`*Leak{Statement,Claim}`/`BuildOnlyStatement`) plus 10
sample-set/stream data defs and the 7 sample bridges
(`sample_of_family`/`swap_sample_of_family`,
`*_sample_model_iff_stream` ×5) — all deleted, with their 37
SpecLabAudit registrations (gate-list rows + cone pins) and the 10
per-plant refutation schemas + pins in
`proofs/SpecLabProofs.lean`. KEPT, untouched: `Codec.lean` (16
laws), all model lemmas, the 5 `model_forall_iff_stream_forall`
bridges, the `fileOfStream_encode` program-term equalities, the
family-∀ TARGET statements (`DivModI8FamilyStatement`,
`SwapFamilyStatement`), `HarnessFinalAllocs`/`driverBaseline`
(generic leak vocabulary), the generic refutation machinery
(`specifiedInt_injective`, `harnessRunsTo_exclusive`,
`finalAllocs_exclusive`), `mkHarness`, the five generated
`*Core.lean` program terms (consumed by the surviving family-∀
statements and gate lanes), and both `--gate` differential lanes.

### 2.4 Fixture/test-row dispositions

- `tests/verify/*.c` + pinned `*.core`: ALL 22 fixtures STAY
  (model-validation ledger: pin-provenance + main-mode differential
  rows are per-fixture and unaffected; the corpus fixtures are the
  B5 ∀-input acceptance targets).
- `tests/verify/expectations.txt`: 70 harness-point rows tied to
  killed theorems DELETED (t6, t7, e1–e5, c4, c5, c3a, c3b, x7, x2,
  c9, x3, z1, z2); the 18 T1–T5 rows stay. Provenance header in the
  file.
- `test_verify.sh` baseline: 133 → 63 checks — 22 pin-provenance +
  22 main-mode differentials (one per .c fixture, ALL fixtures kept)
  + 18 harness points (T1–T5) + the t4-env-witness probe (its header
  re-labeled: the ambient `T4EnvHyp` is gone; the probe remains the
  process-global witness under the threaded guard) — fail-closed,
  vacuous-pass guarded; verbatim line in §8.
- `EmitLeanCoreTest.slatePoints`: the killed-fixture rows deleted
  (t6/t7/e*/c*/x*/z* — 68 rows, derived); T2–T5 rows + the T1
  `concretePoints` drift/differential net stay.
- `SlateCore.lean` REGENERATED from the pruned `slatePlan`
  (t2/t3/t4/t5 only; the x3Stdlib params-trio emission removed);
  `SlateFiles.lean` killed-fixture assemblies deleted.
- `tests/speclab/` C fixtures + oracle pins: untouched (the
  differential lanes stay green).

### 2.5 The re-homes (texts unchanged; the R5 method)

- `T1AppEq/T2AppEq/T3AppEq` SPLIT: ambient whole-run carriers
  (prefix walks, `dnms_chain`, `ndct_eq`, `driver2_iter`,
  `t?_app_eq`, `t?_result_eq` — every one a `runEffectful` carrier;
  T1's `dnms_chain` was also the last `app_walk` user) DELETED; the
  trio-clean remainder (∀-run-state round lemmas incl. the pinned
  `round6`/`round13`/`round21`, spelling defs, byte-roundtrip
  lemmas) RENAMED `T1Walks/T2Walks/T3Walks.lean` — the
  T4Walks/T5Walks convention — because the KEPT threaded theorems
  consume them (evidence: `T1Threaded` uses `round6` ×5, etc.).
- `t1Fs`/`t1Spec` → `T1Walks.lean`; `t2Fs`/`t2Spec` →
  `T2Walks.lean`; `t3Fs`/`t3Spec` → `T3Walks.lean` (all in their
  original `RelSem.T?` namespaces — every statement text resolves
  the same names, byte-stable; `intRange` was already re-homed to
  `T1File` at R5). `t5File`'s assembly stays in `SlateFiles`.
- Salvage from the killed worker's delta (commit 1): the Kit/Mem
  `within` byte law. C9T's ∀-x statement SHAPE is banked in §6.

## 3. Killed-by-registration (deferrals, per the disposition's
      execution note — each with KEEP-class breakage evidence and a
      trigger)

| Item | KEEP-class breakage evidence | Trigger |
|---|---|---|
| The whole-run concrete-anchor mint mode (`derive_rounds … chain builder` in RoundEval) | Carries the KEPT T1–T5 threaded proofs: `T4Walks.lean` (wa 44 + wb 12 rounds), `T5Walks.lean` (five builder drives), the T1/T2/T3 threaded walk layers — all trio-pinned KEEP theorems' equation supply | The B-plan replacement (B2 symbolic rules / B5 re-proof) lands — the assessment's own B6 sequencing |
| `T1Walks/T2Walks/T3Walks` (the slimmed trio-clean walk supplies, formerly T?AppEq) + `T4Walks`/`T5Walks`/`T5Inv`/`T5Seam`/`T5Spine` engine rooms | Direct imports/consumption by the KEEP theorems (assessment C-10: "do NOT delete before" B5 re-proves) | B5 re-proof through the new route |
| The `@[seg_*]` supply entries for t1–t5 (census remainder) | Same: consumed by `seg_auto` discharging the KEEP theorems | B2/B5 |
| `Kit/Loop.iter_compose*` (assessment C-14 DELETE-after-re-point) | Conversion-table item — §2 of the disposition is TO-BE-RATIFIED; no conversion work executes before ratification | The conversion ratification + T5-route re-point |
| `LemLib.runEffectful` (the axiom itself) | Out of this repo (lem-side); carrier set now ZERO — no theorem cone carries it | The registered lem arc |

No other deferrals.

## 4. Gate re-registrations (same commit; old → new)

| Gate surface | Old | New |
|---|---|---|
| Audit statement-gate slate | 55 statements | 13 (T1–T3 triples + T4/T5 pairs) |
| Audit `stmtAllowed` | 62 rows | 24 rows (threaded vocabulary only) |
| Audit `stmtBannedExact` | 8 names | 7 (`stateIs` left with IrisState; existence check is fail-closed) |
| Statement-gate negative test 1 | `T1.t1_wp` | `Cerb.wpk_load` (heap-route Iris entailment) |
| Audit curated cone pins | ~215 | ~100 deleted with their theorems; every KEEP pin verbatim-stable |
| `runEffectfulCarriers` | 104 names | **0** (gate stays, fail-closed both directions) |
| Audit sweep pin | 12,410 | 6,024 (provenance at the pin: ~6,400 declarations left the closure) |
| step_law census | 328 [segEq 162, segFact 62, segCanon 18, segPost 2, wpSeq 2, engine lanes 82] | 166 [segEq 45, segFact 32, segCanon 5, segPost 2; the wpSeq lane emptied with PerStepOwnP; ALL 13 engine lanes unchanged] — the killed fixtures' ~131 supply entries (the assessment's "~240 literal-address entries" measured at the registry: 117 seg* + the wpSeq pair + per-fixture facts inside the files) left with their files; the surviving 84 seg* entries are the t1–t5 threaded supply, killed-by-registration (§3) |
| `check_one_route.sh` | 51 live modules; OWNP_ALLOWED 14 files; PerStepTacSmoke coexistence exception | 45 live modules (corpus/T6/T7/Kit-AppEq out; T1–T3Walks + the T4/T5 chain + T1–T3Threaded in); OWNP_ALLOWED **EMPTY** — any OwnP-binding file anywhere is fatal; exception removed |
| `check_chase_freeze.sh` | 6-file allowlist | **GATE DELETED** — its entire allowlist emptied (every allowlisted file deleted) and the guarded surfaces (`app_walk*` tactics, AppWalk/WalkTrace imports) no longer exist; reintroduction of the OwnP/arc-7 route stays banned by one-route (plant-tested, §7); test_unit.sh row replaced by a tombstone |
| `check_proof_size.sh` SLATE_FILES | T5, T7, T4Threaded | T5, T4Threaded (T7 deleted); debug-surface ban rows kept as reintroduction guards |
| `test_unit.sh` UNIT/RELSEM test lists | incl. `app-walk-test` | exe deleted + tombstone |
| relsem `lakefile.toml` roots | 82 roots + app-walk-test exe | 51 roots (T?AppEq→T?Walks renames; corpus/ambient/OwnP/chase roots out) |
| `RelSemAll.lean` | 82 imports | 51 imports (header notes the kill) |
| SpecLabAudit statements list | 51 names | 13 (family-∀ targets + model↔stream bridges + encode equalities) |
| SpecLabAudit + SpecLabProofs pins | — | 47 killed-def pins deleted; KEEP pins verbatim-stable |
| `tests/verify/expectations.txt` | 88 harness rows | 18 (provenance header) |

## 5. PROOF.md rewrite summary

- §1 (trust story): the `runEffectful` residual re-stated at the
  achieved end state — carrier set ZERO, ambient family deleted,
  every theorem cone exactly the classical trio (or subset).
- §3 (what is proved): the concrete-theorem inventory is GONE by
  design; the section now opens with the operator mandate, states
  the quantified threaded slate T1–T5 per-theorem WITH explicit
  quantification (the assessment's §3.5 docs-truth finding,
  executed), keeps the honest limitation (no symbolic
  data-dependent branch yet — the B-plan's subject), keeps the
  spec-lab KEEP layer and the differential-evidence paragraph
  (labeled evidence-not-theorems), and records THE EXEC-EQUATION
  CAMPAIGN AS CANCELLED (the forbidden strategy), pointing at the
  disposition record. The R6 corpus paragraph is deleted; the R6
  record carries a SUPERSEDED banner with the honest re-reading.
- §4 (machinery): the "frozen legacy, purge-bound" paragraph
  replaced by the deletion note; flagship list now T1–T5 threaded.

## 6. Salvages (from the killed worker's delta, per assessment §6)

1. `Kit/Mem.readBytesFrom_writeBytesTo_within` — committed at
   `24987aa12` (C-7 class; RefinedC array.v element points-to +
   caesium `heap_mapsto_app` lineage).
2. C9T's ∀-x STATEMENT SHAPE (text only; the file itself deleted) —
   banked here as a B5 acceptance-slate row for the array
   vocabulary (the T4 recipe at array data):

   ```lean
   /-- The chartered input range: x and x+1 both representable
       (arr_rw computes x+1; x = INT_MAX is the UB036 face, excluded
       by precondition — the T2 spec-discovery pattern). -/
   def c9Range (x : Int) : Prop := -2147483648 ≤ x ∧ x ≤ 2147483646

   /-- c9's pure spec on driver results: arr_rw(x) = x + 1,
       Specified. -/
   def c9Spec (x : Int) (r : driver_result) : Prop :=
     r.dres_core_value = intValue (x + 1)
   ```

   Target form: ∀ seed (guarded, 2 draws), ∀ x, c9Range x →
   CallHarnessAdequateThr … "arr_rw" [intValue x] … (c9Spec x).
   This joins the assessment's B5 acceptance slate (clamp0 ∀x,
   abs3 ∀x, is_digit ∀c, is_pow2 ∀x, cap10 ∀x, lead_digit ∀x, …,
   arr_rw ∀x).

## 7. Plant tests (load-bearing gate changes)

1. ONE-ROUTE vs OwnP REINTRODUCTION (required by the brief: with
   check_chase_freeze.sh deleted, one-route must still catch it):
   an untracked `relsem/RelSem/OwnPPlant.lean` binding a
   non-comment `[CerbGS …]` instance-binder token → gate FAILED
   (exit 1), verbatim: "check_one_route: FAIL — NEW OwnP-binding
   file outside the retirement register + labeled exemption:
   relsem/RelSem/OwnPPlant.lean". Plant removed; gate green on the
   clean tree (§8).
2. The statement gate's negative tests are IN-BUILD and ran green
   at the new registration: `wpk_load` (the replacement Iris-
   statement probe after t1_wp died) and the permanent wrapper-hole
   probe both "correctly rejected" (§8 verbatim line) — the
   re-pointed negative test is itself the plant.
3. The fail-closed pin machinery fired throughout the purge (the
   working evidence): the census, sweep, carrier and statement-gate
   pins each went red at the intermediate tree and were re-pinned
   deliberately with provenance — every movement in §4 was
   witnessed as a build failure first.

## 8. Validation (verbatim final gate lines)

Full Tier A at the closing tree, every command exit-checked, ALL 16
lanes exit 0 (the runner printed `TIERA_OVERALL_FAIL=0`). Lines below
VERBATIM from the final runs (test_unit re-run at the closing tree
after the engine-size re-baseline; the earlier full-battery pass ran
identically except the engine-size WARN that re-baseline recorded):

```
Total: 6 passed, 0 failed
check_exec_purity: CLEAN (11 modules)
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_theorem_axioms: generated-tree census OK (195 files: 0 axioms, boundary opaques present, 0 unsafeCast)
check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in 2 tree(s) + LemLibTest.lean)
check_theorem_axioms: OK (arc-8 S3 bar: DAEMON-free cones everywhere)
check_exec_totality: CLEAN (16 generated modules + hand-written CerbND, 0 allowlisted)
check_lem_sync: OK (src e51f885203ccdb8e83aa379e7e1ff3372598759c5b8e216ded6554f0d6181105, gen 50b87c916a110d01d86b05580aafda8f78761a614ac4305d963541758bf31029)
check_fork_drift: OK — layer 1: 59 oracle-surface files = manifest; layer 2: 20 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
check_proof_size: T5.lean — 114 lines (bar 250), 4 manual steps (bar 40)
check_proof_size: T4Threaded.lean — 170 lines (bar 250), 6 manual steps (bar 40)
check_proof_size: OK
check_one_route: OK — one state interpretation on the live route (45 modules OwnP-free; coexistence hazard clear; retirement register EMPTY — no OwnP binder anywhere)
check_engine_size: engine total 6964 lines (baseline 6964)
check_engine_size: OK (reporting instrument; enforcement lives in the R3 register row)
GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
BASELINE OK (213 entries, exact match)
test_verify: 63 passed, 0 failed (22 fixtures, 18 harness points)
test_speclab_divmod: PASS (--gate)
test_speclab_seed: PASS (--gate)
```

("Total: 6 passed" — the unit-exe count moved 7 → 6 with the
app-walk-test deletion, registered in §4. The chase-freeze gate line
is ABSENT by design: the gate is deleted, §4.)

From the relsem `lake build` of the same tree (the in-build audit;
every `#guard_msgs` pin — incl. the T1–T5 threaded cone pins at
EXACTLY `[propext, Classical.choice, Quot.sound]` — is
build-enforced, and the build completed green):

```
info: RelSem/Audit.lean:233:0: RelSem DAEMON absence gate: no constant named DAEMON or DAEMON1 exists in the environment; neither is allowlisted
info: RelSem/Audit.lean:262:0: RelSem boundary-opaque gate: with_tagDefs/forceIO exist, are opaque (kernel-checked witnesses, not axioms), and are not allowlisted
info: RelSem/Audit.lean:551:0: RelSem statement gate: 13 slate statements fuel-opsem-clean (negative tests: wpk_load and the wrapper-hole probe correctly rejected)
info: RelSem/Audit.lean:1075:0: runEffectful no-cone gate: carrier set exact (0 registered ambient-family theorems; no acquisition, no stale entries)
Build completed successfully (379 jobs).
```

(The sweep pin — 6024 declarations — and the step_law census pin —
166 laws — are `#guard_msgs`-exact inside the same green build;
their movement provenance sits at the pins.)

From the speclab `lake build` of the same tree:

```
info: SpecLabAudit.lean:132:0: speclab statement-TCB gate: 13 statements clean; wrapper-hole negative test detecting
Build completed successfully (147 jobs).
```

Derived tally (LABELED): 6/6 unit exes + every gate script OK; the
KEEP statement texts byte-stable (git-diff-verified per file: the
T1–T3 threaded statement defs untouched, T4Threaded.lean and T5.lean
untouched entirely; the EmitLeanCore drift gate re-validated the
regenerated SlateCore byte-identically inside test_unit).
