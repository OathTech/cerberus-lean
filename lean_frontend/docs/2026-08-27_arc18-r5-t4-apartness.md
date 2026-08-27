# Arc-18 R5 — T4-APARTNESS THROUGH THE SEGMENT LAYER (slice record)

STATUS: R5 CLOSED at this record (park-ends-slice; the record is the
stop signal). Worker slice of the segment ladder (charter:
`docs/2026-08-26_arc18-segment-ladder-charter.md`, rung R5, priced
M), branch `arc/segment-ladder`, base `03402431b`. Provenance:
[AGENT] worker build throughout; NO statement-layer change — the
guarded T4 statement texts (`t4MinStaticSym`, `T4SeedApart`,
`T4EnvHypThr`, `T4ThreadedStatement`, `t4Spec`, `t4Fs`) are
BYTE-IDENTICAL to their pre-slice texts (git-diff-verified per def;
`t4Spec`/`t4Fs`/`intRange` re-homed with texts unchanged — §6).
Full Tier A green at the closing tree (verbatim lines §8). Quoted
outputs are verbatim; tallies labeled derived.

## 0. HEADLINE

**T4-THE-THEOREM IS PROVED** — the guarded ∀-seed struct-member
statement (the arc-16 S4 park's priced fix; the arc-7
exit-criterion target at the threaded state), THROUGH THE SEGMENT
LAYER, cone exactly {propext, Classical.choice, Quot.sound}, in a
**two-line proof** (`RelSem/T4Threaded.lean`: 170 lines / 6 manual
steps against the 250/40 bars). The full threaded slate **T1–T7 is
now proved through the segment layer**. `T4Threaded_ubFree` lands
beside it (same route). The historic blockers both fell to EXISTING
machinery plus three measured engine legs: the hash-collision
capture is excluded by the statement's `T4SeedApart` guard (its
arithmetic feeds the walk engine's omega lanes and
`seg_env_lookup`), and the ∀-x symbolic argument rides the R4
data-hole/byte-image discipline. **The T1AppEq import is CLEARED
from the live route** (§6 — R7's unblocking condition, met).

## 1. The proof-shape exhibit (T4 proof body VERBATIM)

```lean
theorem T4Threaded : T4ThreadedStatement := by
  verify_fn membSpec
  seg_auto
```

(same two lines for `T4Threaded_ubFree`). The statement (FROZEN
text, byte-stable through the slice):

```lean
def T4ThreadedStatement : Prop :=
  T4EnvHypThr →
  ∀ (seed : Nat), T4SeedApart seed →
  ∀ x : Int, intRange x →
    CallHarnessAdequateThr seed t4File.tagDefs t4File "memb"
      [intValue x] t4Fs (t4Spec x)
```

The human content behind the two lines: the FnSpec (`membSpec` —
name, ∀-x argument family, `intRange` pre, the guard
`T4EnvHypThr ∧ T4SeedApart seed`, `t4Spec` post) and one registered
readout fact (`t4_post_o`). No loop, so no invariant declaration:
T4 is a straight-line program and its proof is structurally the
sequence rule end to end.

## 2. The equation supply (engine room; `RelSem/T4Walks.lean`)

Two evaluator walks mint the WHOLE 56-round run — zero hand-derived
per-round equations — at OPEN heap maps and the OPEN seed under the
apartness bound (`symc + 1 < 229457971439601039`):

- **`wa` — 44 rounds** from the ready builder `mkRdy` (free env
  binder + `hlkV` lookup pattern — the T5 free-env discipline):
  create-struct (layout facts from `htags`), the unspecified store,
  the v-load at symbolic x, and BOTH NEG-store cycles — each drawing
  one fresh symbol at the open seed, inserting it into the
  comparison-keyed env, and consuming it downstream: exactly the
  ≈35-round region the arc-16 S4 record priced as "bulk
  re-derivation the part-2 machinery should structure first", now
  ordinary mints.
- **`wb` — 12 rounds + terminal** from the mid builder `mkMid`
  (every varying component free): the s.a read-back through the
  member-b write layer, kill, the `Erun` return jump, the terminal
  offer at `Specified x`.

The composition is the plain Hoare sequence rule: `t4_run_seg` =
`Seg.of_chain (wa) |>.trans_done (SegDone.of_chain (wb))` at the
rfl-aligned mid boundary (`wa44_align` — the endpoint IS the builder
at its own components; the boundary is a Floyd cut point, nothing
more). Walk B's hypotheses discharge at the composition through the
once-proved lemmas: env built-ness + the `s` lookup by
`seg_env_lookup` (skipping the two anon layers by omega from the
guard, static layers by kernel decide), the read-back by the
registered write-projection laws (`readBytesFrom_writeBytesTo_
disjoint`/`_hit` over the tidy rfl-pinned mid memory `memMid`).

The driver atom `driver2_o` (`@[seg_eq scratch1p]`) characterizes
the whole `driver2` loop by the ready rest + v's footprint; the
struct scratch's entire lifetime is internal; the errno object rides
the frame. Layout facts (`sizeofS_fact` etc.) are the T4AppEq
recipe cloned fixture-locally from `htags` (the retirement-scheduled
files are NOT imported — the T5Inv clone precedent, also applied to
the byte-roundtrip lemmas).

## 3. THE ROUND-22 FRONTIER — disposition: DISSOLVED (measured)

The arc-17 S3 park ("`rT` minted 22 rounds, round 23 = the anon-env
wall: consuming spellings not law-shaped; movers = an abstract env
layer or effect-state threading") is CLOSED WITHOUT either mover:

- The S3 drive ran from MATERIALIZED derive_state states; its wall
  was env maps materialized into raw trees with seed-vs-static
  comparisons stuck inside folded tree operations. The R4-era
  builder mode (free env binder + `fmapAddBy` fencing + the env-lane
  omega mints, built for T5's per-iteration draws) keeps envs
  law-shaped — driven that way, rounds 23–44 (anon inserts, both
  member stores, all anon lookups) mint mechanically under the
  apartness hypothesis.
- The old `rT` scaffolding (closed-memory ladder + the frontier
  note) is DELETED with the T4Threaded rewrite; nothing of the
  materialized route survives on the live path.
- Honest residual: the wall CLASS did not vanish for free — three
  NEW engine legs were measured out by the struct fixture (§4), and
  the deep-ladder read-back needed the standard multi-walk cut
  (§4.3) rather than one 56-round walk. All fixes are structural
  (no budget raises).

## 4. Walls hit, and what they became (prices paid; species-3
      compliant — the missing automation was built, no manual round
      ladder committed)

1. **The extern-stuck escape half-reduction** (kernel addDecl
   rejection at round 5, the unspecified struct store): the
   fenced-head ground escape accepted PARTIAL whnf results —
   `sizeofCtype structSCty` is closed but reads the tag-table
   OPAQUE, so the escape half-unfolded it into an opaque-stuck
   Decidable tower (measured: round-1 payload 801 → 1622 objs),
   destroying the pack's tidy spellings; the later substitution then
   built kernel-rejected mixed-spelling terms. Became the
   PARTIAL-REDUCTION REJECTION (RoundEval/Core.lean): an escape
   result carrying an opaque constant is a half-reduction — rejected,
   spelling kept for the substitution pass. (A result carrying merely
   FENCED heads stays accepted — a label-table lookup legitimately
   returns an `fmapAddBy`-spelled payload; measured on walk B's
   `Erun` round.)
2. **Concrete-chain env lookups at symbolic values** (round 18): the
   first builder draft carried the CONCRETE ready env; mid-walk
   lookups then ran over concrete-key chains carrying symbolic
   values — closed enough to fence, too symbolic to ground. Became
   the T5 free-env builder discipline (env binder + `hlkV` pattern),
   not an engine change.
3. **The round-49 deep-ladder read-back budget**: the s.a load at
   the 4-layer write ladder (580-obj memory spelling) ran 7 law side
   conditions through one shared 200k budget — the reconstruct side
   starved. Became (a) the per-SIDE budget scope in `hyp_norm_side`
   (`withCurrHeartbeats` at the default value — scoping, never a
   raise; the S2 §4 pattern at side-condition granularity), and (b)
   the standard MULTI-WALK CUT (the T7 e/bEven/bOdd/bx shape): walk
   B runs from a free-component builder so its side conditions
   normalize small terms. Canon lineage: Floyd cut points — a
   boundary mid-statement is still just a cut point.
4. **`mkBuiltProof` had no closed-chain base case**: `seg_env_lookup`
   at the composition site meets a concrete env chain over the EMPTY
   map (T4's harness env), and the built-ness constructor's layer
   descent bottoms out at `FmapBuilt fmapEmpty = False` (built-ness
   starts at the FIRST insert — T5/T7 only ever discharged at free
   bases with hypotheses). Became the CLOSED-CHAIN materialized refl
   (SegmentFaces): a closed chain whnfs to `Fmap.mk` and closes by
   the captured-comparator refl; the fvar guard keeps symbolic-key
   chains off the whnf.
5. **The atom's write interleaving vs `wpk_seq_scratch1`'s term
   shape**: scratch1's `allocStoreBytes` interface states exactly two
   write layers; T4's scratch takes FOUR (uninit, unspecified
   padding, member a, member b), and no term-shape equality over a
   symbolic byte map can collapse them. Became **`wpk_seq_scratch1p`**
   (CerbHeapWalk) — the scratch2 POINTWISE final-state interface at
   ONE range (opaque `F bm am` + pointwise byte/allocation/rest
   facts; `MemInv.scratch1_pointwise` + the insert-erase `get?`
   lemmas in MemLocal) + the `seg_scratch1p` macro and dispatch arm.
   NOT a new mechanism kind: it is the C3b pointwise design already
   priced and landed for scratch2, instantiated at one scratch —
   within the rung's M price.

## 5. Per-segment manual-line count (the down-pressure number)

- Per SEGMENT in the user proof: **0 manual lines** — all 11 joints
  of the harness walk (5 rest stages, 1 nd_get canon, 2 argobj, 1
  scratch1p atom, 1 terminal) dispatch through the registry.
- Per THEOREM: 2 manual lines (`verify_fn`, `seg_auto`);
  T4Threaded.lean total 170 lines / 6 manual steps (gate-measured;
  bars 250/40 — the extra 4 are `driver2_o`'s composition body and
  the readout, both engine-room-facing).
- Engine-room supply for this fixture: `T4Walks.lean` 800 lines
  (fixture data, the two drives, the k-stage spine, the mid-memory
  discharge lemmas, the composed segment + pointwise final-state
  facts). The walk-supply-to-proof ratio remains the arc-19 minting
  frontier's work order, as registered at R4.

## 6. THE T1AppEq CLEARANCE (R7's unblocking condition — met) + re-homes

- `RelSem/T4Threaded.lean` no longer imports `RelSem.T1AppEq` (nor
  any ambient-family module). Transitive check (derived, script over
  import headers): T4Threaded's closure = 40 modules, containing
  NONE of {T1AppEq, T2AppEq, T3AppEq, T4AppEq, T4Defs, T1, T2, T3,
  T4, Tactics.AppWalk}.
- Remaining `import RelSem.T1AppEq` (grep, verbatim):

  ```
  RelSem/T3AppEq.lean:32:import RelSem.T1AppEq
  RelSem/PerStepSmoke.lean:32:import RelSem.T1AppEq
  RelSem/T2AppEq.lean:29:import RelSem.T1AppEq
  RelSem/T4Defs.lean:37:import RelSem.T1AppEq
  RelSem/T1.lean:33:import RelSem.T1AppEq
  ```

  All five are the ambient family or its clients: T1/T2AppEq/
  T3AppEq/T4Defs are the ambient chain itself; PerStepSmoke is the
  arc-16 S1 smoke client that deliberately discharges the AMBIENT
  `T1Statement` (runEffectful-carrying) — it retires or re-homes
  WITH the family at R7. **ZERO live-route importers remain.**
- Re-homes (the R3/R4 method — re-home first, texts unchanged, same
  commit): `intRange` T1.lean → T1File.lean (live statement
  vocabulary; T1File already lives on every threaded route);
  `t4Fs` T4.lean → T4Walks.lean (a `namespace RelSem.T4` block —
  the statement text's `t4Fs` resolves to the same name);
  `t4Spec` T4.lean → T4Threaded.lean. The ambient `T4.lean` now
  imports the live route for them (ambient depends on live — R7
  deletes ambient without touching the statements).
- **R7 delta vs the R3 importer table**: R7 can now delete the
  whole AppEq family (T1AppEq/T2AppEq/T3AppEq/T4AppEq/T4Defs), the
  ambient statement files T1–T4 (their theorems are the 104-strong
  runEffectful carrier set), PerStepSmoke, AppWalk + its Tactics,
  and PerStepRunner (Audit gate re-registrations as scheduled).
  REMAINING R7 PREREQUISITE (registered here, not owed by R5): the
  T1/T2/T3 threaded files still import their ambient statement files
  for statement vocabulary (`t1Spec`/`t2Spec`/`t3Spec`, `drDone`
  ladders); the R5 re-home recipe (this slice's `intRange`/`t4Fs`/
  `t4Spec` moves) is exactly the method — mechanical, S-priced.

## 7. Census movements (all provenanced at the pins)

- step_law census: 168 → 191 (heapWalk 10 → 11 [`wpk_seq_scratch1p`];
  segEq 54 → 63, segFact 26 → 37, segCanon 6 → 7, segPost 1 → 2 —
  the t4 fixture supply).
- Audit sweep: 8469 → 8982 (T4Walks drives + spine + the re-housed
  route; provenance at the pin).
- Statement gate slate: 31 → 33 (T4Threaded, T4Threaded_ubFree; the
  in-gate "T4Threaded absent by design" note deleted);
  `t4MinStaticSym` joins the statement-vocabulary allowlist (a Nat
  literal def — first-order executable, the guard's bound).
- Engine size: 6860 → 6955 (Core 346 → 377 the escape rejection;
  Hyp 1033 → 1041 the per-side scope; SegmentFaces 1120 → 1176 the
  closed-chain built refl + the scratch1p macro/arm — provenance in
  `scripts/engine_size_baseline.txt`).
- CerbHeapWalk registry-backing list: 13 → 15 (scratch1p + the R4
  scratch2 omission fixed, noted in-file).
- Proof-size gate: `T4Threaded.lean` REGISTERED — 170 lines / 6
  manual steps (bars 250/40). T5 114/4, T7 249/19 unchanged.
- runEffectful carrier set: unchanged (104 — no ambient theorem
  moved).
- In-build cone pins added (each `#guard_msgs`-exact, trio):
  `T4Threaded`, `T4Threaded_ubFree`, `T4W.t4_run_seg`,
  `T4.driver2_o`, `Cerb.wpk_seq_scratch1p`.

## 8. Validation (verbatim gate lines, final battery)

Full Tier A at the closing tree (every command exit-checked):

```
Total: 7 passed, 0 failed
check_exec_purity: CLEAN (11 modules)
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_theorem_axioms: generated-tree census OK (195 files: 0 axioms, boundary opaques present, 0 unsafeCast)
check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in 2 tree(s) + LemLibTest.lean)
check_theorem_axioms: OK (arc-8 S3 bar: DAEMON-free cones everywhere)
check_exec_totality: CLEAN (16 generated modules + hand-written CerbND, 0 allowlisted)
check_lem_sync: OK (src e51f885203ccdb8e83aa379e7e1ff3372598759c5b8e216ded6554f0d6181105, gen 50b87c916a110d01d86b05580aafda8f78761a614ac4305d963541758bf31029)
check_fork_drift: OK — layer 1: 59 oracle-surface files = manifest; layer 2: 20 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
check_proof_size: T5.lean — 114 lines (bar 250), 4 manual steps (bar 40)
check_proof_size: T7.lean — 249 lines (bar 250), 19 manual steps (bar 40)
check_proof_size: T4Threaded.lean — 170 lines (bar 250), 6 manual steps (bar 40)
check_chase_freeze: OK — no chase-surface imports/uses outside the legacy allowlist (6/6 allowlisted files present)
check_one_route: OK — one state interpretation on the live route (40 modules OwnP-free; coexistence hazard clear; OwnP binders confined to the retirement register)
check_engine_size: engine total 6955 lines (baseline 6955)
test_verify: 41 passed, 0 failed (7 fixtures, 26 harness points)
test_speclab_divmod: PASS (--gate)
test_speclab_seed: PASS (--gate)
info: RelSem/Audit.lean:660:0: RelSem statement gate: 33 slate statements fuel-opsem-clean (negative tests: t1_wp and the wrapper-hole probe correctly rejected)
info: RelSem/Audit.lean:1273:0: runEffectful no-cone gate: carrier set exact (104 registered ambient-family theorems; no acquisition, no stale entries)
```

## 9. Commits

- `72b438cf8` — T4-apartness through the layer: the T4Walks two-walk
  drive + the re-housed T4Threaded route + the engine legs +
  wpk_seq_scratch1p + all gate re-registrations (full Tier A green,
  every command exit 0; §8 verbatim).
- (this commit) — PROOF.md §3 honest refresh (T4 flips OPEN → PROVED;
  the full threaded slate T1–T7 through the layer) + this record.
