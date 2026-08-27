# Arc-18 R2 — THE SEGMENT LAYER (slice record)

STATUS: R2 CLOSED at this record (park-ends-slice; the record is the
stop signal). Worker slice of the segment ladder (charter:
`docs/2026-08-26_arc18-segment-ladder-charter.md`), branch
`arc/segment-ladder`, base `0bc67d121`. Validation: full Tier A green
before each commit (verbatim lines §7). Provenance: [AGENT] worker
build throughout; the one mid-slice ruling consumed is the [USER
2026-08-26] FnSpec promotion-compatibility RATIFICATION (relayed by
the orchestrator; tag updated in-code, charter doc untouched per
brief).

## 1. What landed (deliverables 1–9)

1. **The segment judgment** (`relsem/RelSem/Segment.lean`) — DONE.
   `Seg C B s s' := ∃ k, k ≤ B ∧ ∀ fuel, C (fuel + k) s = C fuel s'`
   (+ `SegDone` for terminal offers): Floyd cut points at Core labels
   carried on the ∀-fuel relative chain equations the evaluator
   mints, **∃-round budgeted from day one** ([F1]) — the budget is
   the Dijkstra/Gries bound function's shadow ([F7] total-correctness
   divergence, donor table row 1). Invariants are a MAP from labels
   (`SegInv`/`InvMap`, RefinedC `typed_block` mirror) with body/exit
   obligations DERIVED (`BodyOb`/`ExitOb`/`InvMap.while_inv`), never
   hand-composed. Footprint vocabulary is CerbMemInterp-only (the
   layer is a live-route module under check_one_route).
2. **Composition proved once** — DONE. `Seg.trans`/`trans_done`
   (budgets add), `Seg.iter` (VARIABLE per-iteration rounds — the
   [F1] breaker `iter_compose_var`/`_from` landed in `Kit/Loop.lean`,
   closing the arc-9 `_var` work-order item), `Seg.while_inv`
   (head-invariant + guard-false exit), `SegDone.run` +
   `driver2_of_seg` (the ∃-round budget meets `lemDefaultFuel`
   exactly once, in the layer).
3. **FnSpec** ([F9]) — DONE, greenfield. One contract form
   `{fname, args, pre, guard, post}`, two roles (obligation via
   `WpOb`/`dischargeThr`/`dischargeUBThr`; summary via
   `Summary.consume` = Hoare procedure rule + frame). The `guard`
   slot carries the guarded-∀-seed house shape (T4-apartness
   lineage). Promotion-compatibility is the RATIFIED [USER
   2026-08-26] forward-design constraint (in-code note at the
   definition).
4. **[F3] join-point spelling normalization** — DONE, demonstrated
   LIVE on the T5 twins (`relsem/RelSem/T5Seam.lean`):
   `JoinSpellings` routes index 0 through the fall-in spelling
   (`mkLH1`) and k ≥ 1 through the stored spelling (`mkLH`);
   `t5SeamInv_St_eq` proves the layer's derived head family
   coincides with the landed C3b family at every index; BOTH twins'
   body obligations (`t5_seam_body0` via `bfirst`, `t5_seam_bodyS`
   via `b`) are stated over the ONE declared invariant and
   discharged, trio-exact cones, walk-pack facts entering as one
   bundled hypothesis (`BPack`) whose ∀-k closure is exactly the R4
   rung. t7 measured SINGLE-spelling (all heads stored-aligned by
   rfl) — the seam table degenerates there, as designed.
5. **Thin faces** (`relsem/RelSem/SegmentFaces.lean`) — DONE.
   `verify_fn <spec>` (statement → WP obligation through
   FnSpec + threaded adequacy, 6 statement shapes), `seg_auto`
   (registry-dispatched per-joint discharge: goal-form keys + the
   registered `variant`, proof-mode resource discovery by shape),
   `seg_env_lookup` (the env-peel automation: skip/hit over the
   captured-comparator laws — kernel `decide` at closed layers,
   omega at seed layers; the species-3 answer to what would
   otherwise have been a per-layer manual grind), registration
   attributes `@[seg_eq/seg_fact/seg_canon/seg_post]` into THE ONE
   registry (`LawRegistry.stepLawExt` — no second registry).
   Brick-wp discipline: lemmas + thin faces, no logic in macros.
6. **Smoke** — DONE, both:
   (a) **T6 re-proved THROUGH the layer** (statement + cone
   byte-stable, trio-exact), full proof body verbatim:
   ```lean
   theorem T6Threaded : T6ThreadedStatement := by
     verify_fn pickSpec
     seg_auto
   ```
   (same two lines for `T6Threaded_ubFree`; the hand walk
   `t6_wpK_thr` + `t6_post_o` are DELETED — subsumed).
   (b) **ONE NEW branch-in-loop fixture**: `tests/verify/t7_flip.c`
   (`flip(n)`: while-loop whose arms ALTERNATE data-dependently —
   odd arm two stores, even arm one; per-iteration round counts 95 /
   72 / 94 / 70 — the uniform-k composition cannot state it),
   oracle-pinned in the test_verify pattern (4 expectation points),
   proved through the layer with ONE invariant (`flipInv`/`invMap7`)
   at a guarded ∀-seed statement: `RelSem/T7.lean`, 249 lines / 19
   manual steps (proof-size gate; slate-registered), cones exactly
   the classical trio. The loop atom's read-write store ladder
   needed one new once-proved walk rule (`wpk_seq_write1` +
   `writeSeq` ghost fold — CerbHeapWalk/CerbHeapRA/MemLocal), the
   scratch2-class gap named at C3b, now closed.
7. **walk→segment rename** — DONE on user-facing surfaces (PROOF.md,
   the correspondence table's naming map; T5Walks/T7Walks headers
   now state "walk" is engine-room vocabulary; `Seg` is the user
   noun). Engine module names unchanged by design.
8. **Donor-correspondence table v1** — DONE:
   `docs/2026-08-26_arc18-r2-donor-correspondence.md` (13 construct
   rows, ours ↔ RefinedC ↔ BRiCk, MIRRORED/ADAPTED/DIVERGENT with
   the charter-named divergences; + the naming map).
9. **This record** + [F6] close items — DONE: PROOF.md §3 refreshed
   (T4 honestly OPEN at R5; T5 OPEN at R4 with the substrate
   enumerated; T7 + the segment layer added; §4 gains the layer
   bullet); R0 audit wording fixes applied (the "kernel-witnessed
   FALSE" overstatement in the C4 record and the Threaded.lean
   header re-worded to the acceptance doc's careful reading —
   collision kernel-witnessed, falseness additionally resting on the
   capture argument; DivModFiles.lean cite §4→§3; the C4 record's
   moved Audit.lean line reference annotated outside the verbatim
   block).

## 2. Design shape (one paragraph per idea; lineages)

**The judgment.** Segments are relative chain equations with an
∃-bounded round count — Floyd's cut-point method (1967 lineage) at
the equation calculus, composed by the Hoare sequence/while rules
proved once. The WP layer consumes a whole segment at the driver-atom
rule (`driver2_of_seg`), so fuel arithmetic never reaches user
proofs. **Invariants as a map.** `InvMap` mirrors RefinedC's
`gmap label → typed_block` (deps/refinedc
theories/typing/programs.v:68–73, BSD): the user declares one object
per label; obligations are derived. **Spelling normalization.** The
C3b-measured fall-in/stored seam is owned by `JoinSpellings` +
`SegInv.St` index routing — an elaboration artifact neither donor
substrate has (divergent-by-necessity, table row 5). **Contracts.**
`FnSpec` is procedure-rule + frame in role, Hoare-style pure
pre/guard/post in form (reach-not-clone: no refinement-type layer;
promotion-compatible by the ratified constraint). **Faces.**
brick-wp's discipline (deps/BRiCk IDEAS-ONLY): every applied rule an
ordinary kernel-checked theorem; elaborators shape claims, never
certify.

## 3. Engine growth (all once-proved, fixture-free)

- `Segment.lean` (~560 lines incl. LoopComps) + `SegmentFaces.lean`
  (~700): the layer + faces. Engine-size baseline re-pinned 6281
  (provenance in `scripts/engine_size_baseline.txt`).
- `Kit/Loop.lean`: `roundSum`, `iter_compose_var_from`,
  `iter_compose_var` (@[step_law loop fromNVar/from0Var]).
- `Kit/Map.lean`: `envBeq` (fixture-free promotion of T5Inv's
  generated-BEq spelling).
- `CerbHeapWalk.lean`: `wpk_seq_write1`(+`_ecast`) — the write1 walk
  rule; `wp_write1` macro; registry-backing 13 laws.
- `CerbHeapRA.lean`/`MemLocal.lean`: `writeSeq` +
  `bytes_update_seq_ghost` / `MemInv.writeSeq_pres` (store-ladder
  ghost folds).
- `RoundEval/Lanes.lean`: proveBuilt pack-first scan (+12 lines,
  literal-env builtness for open-memory drives).
- Registry census 105 laws (pinned in Audit:
  `[advance 5, construct 9, envAlg 3, envMap 4, evalArith 2,
  evalPull 2, heapWP 4, heapWalk 9, loop 5, memBlock 6, memRW 20,
  perform 6, roundGlue 3, segCanon 2, segEq 18, segFact 5,
  wpSeq 2]`). Audit sweep 7182 → 8404 across the slice's three
  re-pins (provenance comments at the pin).

## 4. The t7 evidence (why the ∃-round form was necessary)

flip(7)'s iterations cost 95 / 72 / 94 rounds + a 70-round exit —
data-dependent, non-uniform. `Seg.iter`'s variable-round composition
states it directly; the fixed-round `iter_compose` cannot (it remains
registered for uniform loops like T5). The invariant is ONE
declaration (`invMap7`: value-trajectory 7→4→2→0 at the loop head);
the composed run (`t7_run_seg`) is by `InvMap.while_inv` + three
St-alignment rfls; the statement discharge is `verify_fn flipSpec;
seg_auto`.

## 5. Walls hit, and what they became (prices paid)

- **The env-peel wall** (~15 iterations, the slice's hardest):
  symbolic-seed environment lookups under the captured-comparator
  closure defeated rw/mkAppM/nested-tactic routes (elaboration-order,
  mdata, HO-unification, and RECOVERY hazards — `Elab.runTactic`
  recovers inner failures into sorried proofs; `mkDecideProof` does
  not reject open props). Became `seg_env_lookup`: pure-Meta
  construction, unify-first instance discipline (instances from the
  GOAL — the envBeq lesson generalized), checked-defeq hit detection,
  closedness-guarded kernel decide + explicit-facts omega. Species-3
  compliance: the missing automation was built; no manual peel ladder
  was committed.
- **Round-64 digest wall** (t7 drives): fresh-symbol lookups opaque
  past env materialization — became the `hdig`/`hbuilt` pack facts +
  drive-local `fmapLookupBy` fencing + the proveBuilt pack-first scan
  (all law-shaped, no fixture logic in the engine).
- **HO-unification divergence** at `of_chain` (`?C (fuel + ?k)` is
  not a Miller pattern) — priced as explicit `(C :=)(k :=)`
  discipline at call sites (documented in Segment.lean).
- **Phantom-param elaboration** (t7Offer) — the C3b hazard again;
  explicit type ascription.
- **`St (k+1)` symbolic-index defeq** — `St_align` rewrites, not
  defeq, at open k (T5Seam bodyS; term-mode St-aligns in T7).

## 6. Honest frontier (what R2 does NOT claim)

- **T5-the-theorem**: OPEN at R4. The seam demo hypothesizes the
  walk packs (`BPack`); their ∀-k closure over the harness family +
  the end-to-end composition are R4 (the C3b corrected map items
  1–2). Ambient T5-prefix stands meanwhile.
- **T4**: OPEN at R5 (round-22 frontier unchanged this slice;
  PROOF.md §3 now says so plainly).
- **Summary/Summary.consume**: form + generic rule landed; first
  worked two-function instance is R6 (charter).
- **seg_auto** is registry-dispatched, not a search procedure —
  goal-directed search is the arc-19 pre-commitment (Lithium
  architecture first).
- The speclab family-∀ endpoints are untouched by this slice (C4
  state stands).

## 7. Validation (verbatim gate lines, final battery)

Full Tier A at the closing tree (test_unit.sh exit 0; all lines
verbatim from the run logs):

```
✓ effects-proof-test PASSED
✓ totality-proof-test PASSED
✓ core-parser-test PASSED
✓ fresh-int-test PASSED
✓ pp-test PASSED
✓ app-walk-test PASSED
✓ emit-lean-core-test PASSED
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_theorem_axioms: generated-tree census OK (195 files: 0 axioms, boundary opaques present, 0 unsafeCast)
check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in 2 tree(s) + LemLibTest.lean)
check_theorem_axioms: OK (arc-8 S3 bar: DAEMON-free cones everywhere)
check_lem_sync: OK (src e51f885203ccdb8e83aa379e7e1ff3372598759c5b8e216ded6554f0d6181105, gen 50b87c916a110d01d86b05580aafda8f78761a614ac4305d963541758bf31029)
check_fork_drift: OK — layer 1: 59 oracle-surface files = manifest; layer 2: 20 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
check_proof_size: T7.lean — 249 lines (bar 250), 19 manual steps (bar 40)
check_proof_size: OK
check_chase_freeze: OK — no chase-surface imports/uses outside the legacy allowlist (8/8 allowlisted files present)
check_one_route: OK — one state interpretation on the live route (40 modules OwnP-free; coexistence hazard clear; OwnP binders confined to the retirement register)
check_engine_size: OK (reporting instrument; enforcement lives in the R3 register row)
test_unit: sync gate OK (21 hand-written files byte-identical to generated/)
info: RelSem/Audit.lean:1215:0: runEffectful no-cone gate: carrier set exact (112 registered ambient-family theorems; no acquisition, no stale entries)
info: RelSem/Audit.lean:657:0: RelSem statement gate: 29 slate statements fuel-opsem-clean (negative tests: t1_wp and the wrapper-hole probe correctly rejected)
test_verify: 41 passed, 0 failed (7 fixtures, 26 harness points)
test_speclab_divmod: PASS (--gate)
test_speclab_seed: PASS (--gate)
```

Audit sweep pinned 8404 declarations, boundary-clean (in-build
#guard_msgs). Cone pins (in-build): `T7Threaded`, `T7Threaded_ubFree`,
`t7_run_seg`, `t5SeamInv_St_eq`, `t5_seam_body0`, `t5_seam_bodyS` —
each exactly `[propext, Classical.choice, Quot.sound]`; T6 pins
byte-stable through the layer re-route. Engine-size re-baselined
6281 → 6533 at close (provenance in
`scripts/engine_size_baseline.txt`; the two grown rows were WARN-live
through the mid-slice battery). Statement byte-stability: the T6/T1–T3
statement text untouched this slice (EmitLeanCore drift gate green).
Derived tally (LABELED): test_unit 7/7 unit executables + all gate
scripts OK; check_engine_size line above is the post-re-baseline
re-run.

## 8. Commits

- `710f25f9c` — the layer + faces + T6-through-the-layer (+ gates
  re-pinned; full Tier A green).
- `09c322067` — t7 flagship (fixture + oracle pins + walks + T7.lean)
  + write1 walk rule + seg_env_lookup + donor table (+ gates; full
  Tier A green).
- (this commit) — [F3] T5 seam demo + LoopComps promotion + rename
  pass + PROOF.md §3 + R0 wording fixes + this record.
