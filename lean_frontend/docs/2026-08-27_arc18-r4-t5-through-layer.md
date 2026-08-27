# Arc-18 R4 — T5 THROUGH THE LAYER + T1/T2/T3 RE-HOUSED (slice record)

STATUS: R4 CLOSED at this record (park-ends-slice; the record is the
stop signal). Worker slice of the segment ladder (charter:
`docs/2026-08-26_arc18-segment-ladder-charter.md`, rung R4, priced
M-L by [F4]), branch `arc/segment-ladder`, base `78439359c`.
Provenance: [AGENT] worker build throughout; no statement-layer
change beyond ADDING the new T5 statement (T1/T2/T3 statement texts
byte-stable, verified by git diff + the in-build statement gate +
EmitLeanCore drift inside test_unit). Full Tier A green before every
commit (verbatim lines §8). Quoted outputs are verbatim; tallies
labeled derived.

## 0. HEADLINE

**T5-THE-THEOREM IS PROVED** — the chartered ∀-n input-family
statement (the fixture header's shape: 0 ≤ n ≤ 100 ⇒ outcomes =
{Specified(n·(n−1)/2)}, no UB), at the guarded ∀-seed house form,
THROUGH THE SEGMENT LAYER at the SYMBOLIC trip count, cone exactly
{propext, Classical.choice, Quot.sound}, in a **two-line proof**
(`RelSem/T5.lean`: 114 lines / 4 manual steps against the 250/40
bars — the proof-size gate's T5 row flipped pending → measured).
T1/T2/T3 are re-housed as `verify_fn <spec>; seg_auto` with
statements and cones byte-stable. The ambient-era T5 chain
(T5Fixture/T5Prefix/T5Iter) is retired with same-commit pin
re-registration. The [F8] measurement (§2) found **ZERO unexplained
"other" survivors** — charter stop-event #1 does not trigger.

## 1. The proof-shape exhibit (T5 proof body VERBATIM)

```lean
theorem T5Threaded : T5ThreadedStatement := by
  verify_fn sumSpec
  seg_auto
```

(same two lines for `T5Threaded_ubFree`). The statement (also
verbatim, `RelSem/T5.lean`):

```lean
def T5ThreadedStatement : Prop :=
  T5EnvHypThr →
  ∀ (seed : Nat), T5SeedApart seed →
    ∀ (n : Int), t5Range n →
      CallHarnessAdequateThr seed t5File.tagDefs t5File "sum"
        [intValue n] t5Fs (t5Spec n)
```

The human content behind the two lines: the FnSpec (`sumSpec` —
name, argument family, range pre, guarded post), the ONE declared
loop invariant (`T5S.t5SeamInv` — s = k·(k−1)/2 ∧ i = k at the k-th
head, both twin spellings routed by the R2 [F3] normalizer), and one
registered readout fact (`t5_post_o` — the exit value meets the
closed form via `triF_closed`). The trip count is n.toNat, SYMBOLIC:
`Seg.while_inv` applies at the free variable — the loop induction
lives in the once-proved rule, never in the fixture file.

## 2. THE [F8] MEASUREMENT — the 28-hypothesis pack through the layer

The body walks' pack (`T5S.BPack`, the C3b record's "27-hypothesis
pack"; recount on the committed structure = 28 fields — derived
tally) classified as it fares through the layer:

**FRAME-INTERNALIZED — 24 of 28** (vanished into the segment rule /
frame / family induction; none reaches the user surface):

| pack field(s) | absorbed by |
|---|---|
| hbuilt | `St_built` (∀-k family; base = kernel rfl, step = the once-proved `envStepF_built` chain) |
| hlkN hlkS hlkI | `St_lkN/lkS/lkI` (∀-k env-lookup families through the R4-hardened `seg_env_lookup` — skip via kernel-decide apartness at static keys, omega at seed keys, HIT at the loop's rebind layers) |
| hdd0 hdd2 hdd3 | `St_dd` over the `St_dead` family (dead list invariantly empty at heads) |
| halN | the n-object footprint: `allocIs` minted at injection, carried by the frame, consumed by the atom rule (`St_alN` on the family side) |
| halS halI | `St_alS/alI` over `St_allocs` (the scratch pair's own table entries) |
| hfpm hlum | `St_fpm/St_lum` (memStep re-pins them each step) |
| hrdN | the n-object byte footprint: `pointsToBytes` from injection through the frame (`St_rdN` + `St_bm_out` family-side) |
| hrdS hrdI | `St_rdS/rdI` over the pointwise byte families `St_bm_s/St_bm_i` (the loop-local images ARE the invariant's data) |
| hrecN hrecS hrecI | `recon_i32` (the general roundtrip at symbolic values, range from the invariant's envelope) |
| hi2bS hi2bI | `i2b_i32` (rfl at symbolic values) |
| hlt hiv0 | the while rule's own trip-count bound (k < n inside `InvMap.while_inv`'s BodyOb; 0 ≤ k is Nat coercion) |
| hsv0 hsv1 | `triF_nonneg`/`triF_le` — the loop measure's arithmetic envelope, derived from the invariant declaration |

**PURE-SUPPLY — 4 of 28** (survive as EXPECTED statement-level
supply arithmetic — the queued ghost-supply design question, not a
layer failure):

| pack field | surviving as |
|---|---|
| hdig | `T5EnvHypThr` (the digest pin — the statement guard's first conjunct) |
| hscB hexcB | `T5SeedApart seed` (seed + 256 < 2⁶⁰) + the closed supply forms `St_symc/St_exc` (= seed + 2k / 2k, k ≤ 100 — omega) |
| hn1 | the chartered input range `t5Range n` (statement PRE by the fixture header's design — spec content, listed here because the walk also consumes it as supply arithmetic) |

**OTHER — 0 of 28.** No unexplained survivors; stop-event #1 does
not trigger. Derived counts: 24 + 4 = 28.

Mechanism-KIND finding (the brief's measurement clause): exactly ONE
genuinely new rule class was needed — `wpk_seq_scratch2` — and it
was the C3b map's named, priced known-M sub-item, not a surprise.
Everything else was law-count and dispatch plumbing.

## 3. What R2's machinery had already dissolved (the C3b map,
      item by item)

| C3b item (price) | disposition at R4 |
|---|---|
| 1. env-lookup peels ∀-k (S-M) | `St_lk*` families, discharged by R2's `seg_env_lookup` — after TWO latent engine bugs were fixed (§5, the ∀-k closure's real content) |
| 2. pack-fact family lemmas (S-M) | T5Inv families (`St_bm_*`, `St_rd*`, `recon_i32`/`i2b_i32` clones, supply/scalar pins) — mechanical as priced |
| 3. hbody + iter_compose (S) | `t5_seam_body0/bodyS` (R2's landed seam obligations) + `InvMap.while_inv`; `iter_compose` never consumed — the R2 layer's ∃-round `Seg.iter` subsumed it inside the while rule |
| 4. fuel algebra + ndct/driver2 (S) | DISSOLVED into R2's `Seg`/`driver2_of_seg` — budget-mono at `lemDefaultFuel` is one omega; zero per-fixture fuel arithmetic |
| 5. harness spine at open maps (S-M) | `T5Spine` k-stage equations — the T1/T7 recipe verbatim at symbolic n (`inject_ptr_arg1` is rfl-grade at open n) |
| 6. `wpk_seq_scratch2` (M) | BUILT (the slice's M item): the C3b design note's pointwise prescription realized END-TO-END — final state as an opaque fixture function characterized pointwise (rest/allocation-chain/byte facts), ghost jumps straight to the final images, `MemInv.scratch2_pointwise` rebuilt from the pointwise facts. ORDER-INDEPENDENT in the write interleaving — the note's syntactic `writeSeq`-canonical-form direction was NOT needed |
| 7. statement + adequacy + gates (S) | landed; T5 gate row flipped, slate 29 → 31 |

scratch2-class status: R2's `wpk_seq_write1` did NOT subsume it (T7's
loop re-writes a caller object; T5's scratch pair lives and dies
inside the atom) — the C3b M-pricing was accurate.

## 4. Per-segment manual-line count (the down-pressure number)

- Per SEGMENT in the user proof: **0 manual lines** — all 11 joints
  of the T5 harness walk (5 rest stages, 1 nd_get canon, 2 argobj,
  1 scratch2 atom, 1 terminal) dispatch through the registry.
- Per THEOREM: 2 manual lines (`verify_fn`, `seg_auto`); T5.lean
  total 4 manual steps / 114 lines (gate-measured).
- The fixture's non-engine human content: the FnSpec (~6 lines), the
  invariant declaration (R2's `t5SeamInv`, ~20 lines), the readout
  fact (~12 lines).
- Engine-room supply for this fixture (NOT user-facing, all
  kernel-checked): `T5Spine` 683 lines (spine equations, the ∀-k
  pack assembly, exit legs, atom equation, readout), T5Inv's R4
  additions ≈ 700 lines (families + rest-independence + exit
  endpoints). Honest accounting: the walk-supply-to-proof ratio is
  the arc-19 minting frontier's work order, exactly as registered.
- T1/T2/T3 re-housed: 2 manual lines per theorem (from 11-13-line
  hand walks + bridge boilerplate); their hand wpK lemmas deleted.

## 5. Walls hit, and what they became (prices paid; all species-3
      compliant — the missing automation was built, no manual ladder
      committed)

- **Two latent kernel-rejection bugs in `seg_env_lookup`** (the R2
  env-peel automation, exposed by the ∀-k closure at OPEN base
  envs): (a) the built-ness slot fabricated an UNCHECKED refl cast —
  kernel-rejected at symbolic bases; became `mkBuiltProof` (the
  fmapAddBy_built chain at term-carried instances, base by checked
  refl or local hypothesis); (b) `mkDecideProof` on a FALSE closed
  disequality (the loop REBINDS s/i at the same keys) fabricated a
  kernel-rejected skip proof that masked the hit route; became the
  equal-key skip guard. Both caught by the kernel, as designed.
- **The heartbeat-poisoning family** (the slice's hardest wall,
  ~6 iterations): speculative unification against arbitrary
  registered entries — and mis-matched `verify_fn` alternatives —
  burned the enclosing declaration's 200k budget, poisoning every
  LATER match into instant timeout (measured: one seg_side = 34.2s,
  all-entries miss cascade). Became three engine legs, NO
  maxHeartbeats bump anywhere: per-probe heartbeat isolation
  (`withProbeBudget`), KEYED registry pre-selection (goal-form
  DiscrTree, symmetric to `goalFormKeys`, in both `proveByRegistry`
  and `matchSegEq`; full-scan fallback keeps fence-robustness), and
  the SHAPE-INDEXED `verify_fn` (`classifyStmt` reads the goal's
  leading binder domains and picks the ONE bridge alternative).
  Registered arc-19 relevance: this is measured evidence for the
  Lithium-style goal-directed dispatch pre-commitment.
- **Data-hole pinning** (mechanism finding, engine leg): a symbolic
  spec parameter (T5's n) reaches the registered atom equation ONLY
  through its byte image — blind local search picked the WRONG
  same-typed binder (the statement face's outer binder). Became
  footprint-based unification in `matchSegEq` (the equation's byte
  image/allocation record unified against the DISCOVERED proof-mode
  resources before hole-solving) + innermost-first `solveHole` +
  `tryTac` postponed-synthesis flush (a wrong `refine` alternative
  can no longer "succeed" with deferred errors).
- **∀-shaped registered facts**: `instantiateEntry` telescoped past
  the expectation's own ∀-binders; became the partial telescope at
  arity difference — and the final-image facts are stated at the
  rule's LENGTH spelling so unification pins the images before
  binder domains are compared (the finA/finB discrimination is by
  GEOMETRY: the B-range fact `t5_rangeB` pins aB before the B-image
  hole is matched).
- **The twin exits at the terminal**: `bxzero43` ≠ `bx44` even at
  restOf level (probed) — `stFin` is a match on the trip count and
  every downstream fact routes by `cases n.toNat` (the [F3] seam's
  index routing reaching the SegDone terminal).
- **Map-independence of the final rest** (the scratch2 rule's fixed
  ρ'): proved by the St-family rest-independence induction — every
  step a kernel rfl through restOf-projections (probe-verified
  before writing; the field-by-field builder emissions make restOf
  congruence rfl-grade).
- **Runtime-exception escape**: deep-recursion storms during
  speculative unification escaped plain `catch`; became
  `tryCatchRuntimeEx` restore-and-miss in `instantiateEntry`.

## 6. Retirements + re-registrations (same-commit, R3 method)

DELETED (import scan first; zero registered laws in the files):
`RelSem/T5Fixture.lean`, `RelSem/T5Prefix.lean`, `RelSem/T5Iter.lean`
(the arc-9→15 ambient-era climb; importers were only the chain
itself + Audit + RelSemAll). Re-registrations in the deleting commit:

- Audit: the A-F1 pin block (entry5_walk + envL_* at the
  runEffectful quartet) retired — re-registered AS the R4 flagship
  pins (T5Threaded/T5Threaded_ubFree/t5_run_seg/driver2_o at exactly
  the classical trio; the env-lookup capability lives on ∀-k as
  T5Inv's `St_lk*`, trio-clean); runEffectful carrier set 112 → 104
  (exact-set gate green); audit sweep re-pinned with provenance.
- lakefile roots −3; RelSemAll tombstone.
- chase-freeze allowlist 7 → 6 (T5Prefix out); one-route OWNP
  register 16 → 14 (T5Prefix/T5Iter out); proof-size policy comment.
- Plant tests: re-added T5Prefix importing AppWalk → chase-freeze
  RED; re-added T5Iter binding `[CerbGS …]` → one-route RED; both
  green on the clean tree.
- Stale `.lake` artifacts of the deleted modules purged.

NOT retired (live, constitutive of the flagship — not residue):
`T5Walks` (the five drive-minted chains = the equation supply),
`T5Inv` (the invariant family + ∀-k closures), `T5Seam` (the [F3]
invariant declaration + body obligations the composition consumes).
These are current-route engine-room supply, not ambient-era
artifacts; nothing is left for R7 from this rung beyond what the
register already schedules (AppWalk/T1AppEq family per the R3 table).

## 7. Census movements (all provenanced at the pins)

- step_law census: 105 → 106 (heapWalk 10: scratch2) → 130 (T5
  supply) → 168 (T1/T2/T3 supply; segEq 54, segFact 26, segCanon 6,
  segPost 1).
- Audit sweep: 8403 → 8654 (engine + families) → 8769 (T5 spine +
  flagship) → 8798 (re-housing) → 8469 (retirement).
- Engine size: 6533 → 6698 → 6810 → 6860 (three provenanced
  re-baselines, all in `scripts/engine_size_baseline.txt`; every leg
  is dispatch plumbing over registered laws — the engine-to-law rule
  observed).
- Statement gate slate: 29 → 31 (T5Threaded, T5Threaded_ubFree).
- runEffectful carriers: 112 → 104.
- Proof-size gate: T5.lean row pending → **114 lines / 4 manual
  steps** (bars 250/40); T7 unchanged 249/19.

## 8. Validation (verbatim gate lines, final battery)

Full Tier A at the closing tree (`test_unit.sh` exit 0; lines
verbatim from the run logs):

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
check_chase_freeze: OK — no chase-surface imports/uses outside the legacy allowlist (6/6 allowlisted files present)
check_one_route: OK — one state interpretation on the live route (40 modules OwnP-free; coexistence hazard clear; OwnP binders confined to the retirement register)
check_engine_size: engine total 6860 lines (baseline 6860)
test_verify: 41 passed, 0 failed (7 fixtures, 26 harness points)
test_speclab_divmod: PASS (--gate)
test_speclab_seed: PASS (--gate)
info: RelSem/Audit.lean:656:0: RelSem statement gate: 31 slate statements fuel-opsem-clean (negative tests: t1_wp and the wrapper-hole probe correctly rejected)
info: RelSem/Audit.lean:1241:0: runEffectful no-cone gate: carrier set exact (104 registered ambient-family theorems; no acquisition, no stale entries)
```

In-build cone pins (each `#guard_msgs`-exact): `T5Threaded`,
`T5Threaded_ubFree`, `t5_run_seg`, `driver2_o` — exactly
`[propext, Classical.choice, Quot.sound]`; the T1/T2/T3 Threaded
family pins byte-stable through the re-housing. Statement
byte-stability: T1/T2/T3 statement defs untouched (git-diff-verified,
zero hits on `ThreadedStatement` texts); the only statement-layer
ADDITION is the new T5 statement, per the brief.

## 9. Commits

- `4774a8a97` — scratch2 engine leg + the T5 ∀-k family closure
  (+ census/engine re-pins; full Tier A green).
- `274facbe9` — T5 THROUGH THE LAYER (T5Spine + T5.lean flagship +
  gates flipped + engine hardening; full Tier A green).
- `4e5c8e052` — T1/T2/T3 re-housed (statements/cones byte-stable;
  wpK walks deleted; full Tier A green).
- `12e66296c` — the retirement (+ same-commit re-registrations +
  plant tests; full Tier A green).
- (this commit) — PROOF.md §3 honest refresh + this record.
