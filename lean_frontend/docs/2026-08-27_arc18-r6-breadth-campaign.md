# Arc-18 R6 — THE BREADTH CAMPAIGN (slice record)

STATUS: R6 CLOSED at this record (park-ends-slice; the record is the
stop signal). Worker slice of the segment ladder (charter:
`docs/2026-08-26_arc18-segment-ladder-charter.md`, rung R6, priced
M-L), branch `arc/segment-ladder`, base `8b9365e2c`. Provenance:
[AGENT] worker build throughout; NO statement-layer change beyond
ADDING the new corpus statements via the house pattern (T1–T7
statement texts untouched — statement gate green at every commit).
Full Tier A green before every batch commit. Quoted outputs are
verbatim; tallies labeled derived. The professor pass on the sample
is the ORCHESTRATOR'S, run independently after this close (charter).

The pre-registered census ([F9]) and corpus plan:
`docs/2026-08-27_arc18-r6-uri-census.md` (committed BEFORE corpus
construction, commit `84a07ba52`).

## 0. HEADLINE

**Eleven programs proved through the segment layer at the cost
floor — 2 manual steps per theorem, ZERO per-program engine
changes — and four vocabulary frontiers measured to root cause and
parked with prices.** The [F5] budget was never exceeded by a proof
(over-budget streak 0; stop-event #5 never triggered — the four
parks are missing-VOCABULARY walls, not proofs ground past). The
campaign's total marginal engine cost across four batches: ONE new
registered law (`Kit.mem_pvfd_block`) + 8 feeder lines
(engine 6955 → 6963, provenanced) + three emitter arms.

## 1. The batch-by-batch table

| id | fixture | tier | census row | atom | rounds | manual steps (headline + twin) | invariants | result |
|----|---------|------|-----------|------|--------|-------------------------------|------------|--------|
| e1 | e1_clamp `clamp0(-3)=0` | EASY | branch floor | read1 | 26 | 2 + 2 | 0 | PROVED |
| e2 | e2_abs `abs3(-5)=5` | EASY | two-arm branch | read1 | 31 | 2 + 2 | 0 | PROVED |
| e3 | e3_scale `scale(7)=17` | EASY | straight-line local | scratch1 | 31 | 2 + 2 | 0 | PROVED |
| e4 | e4_isdigit `is_digit(53)=1` | EASY | §2 ISA_DIGIT | read1 | 55 | 2 + 2 | 0 | PROVED |
| e5 | e5_ismark `is_mark(42)=1` | EASY | §2 IS_MARK 9-arm | read1 | 204 | 2 + 2 | 0 | PROVED |
| c4 | c4_hexval `hex_val(102)=15` | CENSUS | O3 range ladder | read1 | 117 | 2 + 2 | 0 | PROVED |
| c5 | c5_pcthi `pct_hi(65)=52` | CENSUS | O2 nibble arith | scratch1 | 53 | 2 + 2 | 0 | PROVED |
| c3a | c3a_accguard `acc10(21474836,5)` | CENSUS | L5 guards (2-arg) | read2/argobj2 | 163 | 2 + 2 | 0 | PROVED |
| c3b | c3b_leaddigit `lead_digit(273)=2` | CENSUS | L5 loop | write1 + InvMap | 49+48+35 | 2 + 2 | 1 (~25 lines) | PROVED |
| x7 | x7_earlyret `is_pow2(6)=0` | EDGE | E2/E4 return-in-loop | write1 + InvMap | 73+51 | 2 + 2 | 1 (~20 lines) | PROVED |
| x2 | x2_break `cap10(273)=27` | EDGE | E3 break | write1 + InvMap | 71+55 | 2 + 2 | 1 (~20 lines) | PROVED |
| c9 | c9_arrw `arr_rw(41)=42` | CENSUS | §6/§3 array isolation | — | park @ round 35 | — | — | PARKED (§4.1) |
| x3 | x3_call `twice(5)=12` | EDGE | §5 call rule | — | park @ round 12 | — | — | PARKED (§4.2) |
| z1 | z1_chain `chain20(5)=215` | SIZE | write depth 20 | — | mint > 25 min | — | — | PARKED (§4.3) |
| z2 | z2_wide `wide8(1)=44` | SIZE | context width 8 | — | (analytic) | — | — | RECORDED (§4.4) |

Batches: B1 = e1–e5 (`8e59abdd4`), B2 = c4/c5/c3a/c3b
(`0baadc231`), B3 = c9-park + x7/x2 (`dafd50451`), B4 = x3-park +
size ladder (`71a6a6e80`). Interim reports to the orchestrator went
out at each boundary (the [F6] habit extended to every batch).

## 2. The measurement tables

### 2.1 The cost floor (EASY tier; the charter's "must be ~0")

- **Manual proof steps: 2 per theorem** (`verify_fn <spec>` +
  `seg_auto`), 4 per program including the safety twin. Zero
  invariants, zero per-fixture tactic content beyond the two lines.
- **The human content per program:** the FnSpec (~4 lines: name,
  concrete args, post) + the pure spec def (~2 lines) + the
  statement texts (~8 lines, house shape). Everything else is
  engine-room template.
- **Safety-twin marginal cost:** ~8 lines (statement text + the same
  two-line proof); wall-clock ≈ 0 (same build; the twin dispatches
  through the identical registered supply).
- **Loops add exactly the declared invariant** (~20–25 lines:
  spelling table + component projection + the label map + the St
  alignment) — c3b/x7/x2. The composition (`while_inv` +
  entry/exit `Seg.of_chain`) is ~35 more engine-room-facing lines
  in the fixture file, structurally identical across all three.

### 2.2 Marginal law rate per batch (the saturation curve)

| batch | new ENGINE laws | new engine lines | per-fixture supply entries | census |
|-------|-----------------|------------------|---------------------------|--------|
| B1 (5 programs) | 0 | 0 | 61 (segEq 45, segFact 11, segCanon 5) | 191 → 252 |
| B2 (4 programs) | 0 | 0 | 50 (segEq 36, segFact 10, segCanon 4) | 252 → 302 |
| B3 (2 + park) | 1 (`mem_pvfd_block`) | 8 (feeder) | 25 (x7/x2) | 302 → 327 |
| B4 (parks) | 0 | 0 | 0 | 327 |

The curve's shape: the ENGINE was saturated for scalar programs
from batch 1 (five distinct atom variants — read1, read2/argobj2,
scratch1, scratch1p*, write1 — consumed with zero additions; *
scratch1p exercised only via T4). The per-fixture supply rate is
FLAT at ~12 entries/fixture (8–9 k-stage spine equations + 2–3
address facts + 1 canon) — pure boilerplate, ~95% template-identical
across fixtures. This is the measured shape of the arc-19 minting
frontier: the k-stage spine is fixture-independent in FORM and
should be minted or genericized (fixture-independent per-construct
laws), collapsing the ~400-line per-fixture module to its ~40 lines
of genuine data (symbols, addresses, arg bytes, spec).

### 2.3 Mint cost (rounds and wall-clock; the size datum)

- Round counts scale with SOURCE construct count, not lines: 26 (one
  branch) → 204 (9-arm short-circuit ladder: each `||` arm is a
  nested Core case) → 163 (two-arg with guard chains).
- Mint wall-clock (single fixture module, shared-box caveat §5):
  seconds at ≤ 60 rounds, ~1–3 min at 100–200 rounds, **> 25 min at
  the depth-20 write ladder** (§4.3 — nonlinear in ACCUMULATED
  memory-term size, not round count).
- Full-corpus rebuilds (SlateFiles touches invalidate every fixture)
  must run SEQUENTIALLY: parallel re-mints of 9+ fixture modules
  blow the 48G cgroup; per-target serial builds fit. C3B needed the
  64G default cap even alone (the 48G kill during its build masked
  real errors — see §5 honesty note).

## 3. What the campaign validated (the design-layer signal)

1. **The layer's user surface holds at breadth.** Eleven fresh
   programs, five atom shapes, three loop topologies (interior
   iterations; return-from-body; break) — every proof is the same
   two lines over a declared invariant. The Hoare-shape acceptance
   (proof mirrors program) holds: straight-line programs have no
   proof structure beyond the spec; loops have exactly one
   invariant at exactly the loop head; multi-exit costs nothing
   (the exit segment consumes whichever arm the instance takes).
2. **The [F3] spelling normalization held silently** — every corpus
   loop head aligned at the stored spelling by rfl; the twin-builder
   vocabulary never surfaced.
3. **Guard shape is semantically forced, and now measured:** a
   program needs the digest+apartness guard iff its run draws fresh
   symbols. Measured surprise: EVERY C assignment statement (`x = x
   + 1;`) draws one fresh symbol at elaboration (the anon binder) —
   so even straight-line programs that re-assign need the guarded
   face. Only loop-free, reassignment-free programs get the clean
   unguarded ∀-seed statement (e1–e5, c4, c5, c3a — reads and
   initializing declarations only).
4. **The boundary-discovery cost for loops is real but small:** one
   full-mint probe (round-class list) + arena-projection rfl probes
   locate the stored head; the c3b miss (49 vs 48 — the loop-jump
   round) cost ~3 probe builds; x7/x2's boundaries were then
   predicted exactly from the class lists (store+11 = head;
   guard-load−6 = head), suggesting the engine could EMIT join-point
   candidates (registered work item for the minting frontier).

## 4. The parked frontiers (all with committed reproducers)

### 4.1 The array lane (`RelSem/Corpus/C9.lean`, parked round 35)

Three walls; two fixed and landed (EmitLeanCore `Ememop` arm;
`Kit.mem_pvfd_block` — PtrValidForDeref at open memory, liveness by
component fact + alignment closed for the ground escape — plus one
feeder alternative in the memop lane). The OPEN wall: the pure-eval
runstate over the `PEarray_shift` payload does not reduce to Result
at the open-memory anchor. **Price: S-M, a dedicated engine slice**
(array_shift eval shape, whole-array unspecified store,
byte-element loads). BLOCKS census rows c1/c2/c6/c9/c10/c11 — all
uri.c buffer-scan shapes — which is the honest coverage gap: the
census's #1-ranked idiom family (string scans) is NOT yet reachable,
and the R9 capstone waits on this slice. (The census pre-registered
this list; the corpus did not get to flatter itself.)

### 4.2 The call rule (`RelSem/Corpus/X3.lean`, parked round 12)

Root cause found: Core_eval's `PEare_compatible` arm calls
`AilTypesAux.are_compatible`, a generated **`partial def`** —
kernel-opaque (no whnf, no rfl, no provable law). Every internal
function call crosses this check, so no two-function program can be
minted until it is totalized (lem-side fuel or `declare lean
target_rep` hand mirror — the CerbCtypeInstances pattern — +
lean-prelude-src regen + sync/drift gates). **Price: M, a dedicated
slice.** En route, two walls fixed and landed: emitter
OVpointer/PVfunction + PEerror arms; `x3Stdlib` (the ccall
protocol's `params_length`/`_aux`/`params_nth` emitted from
std.core — existing fixtures' file values untouched). The
`FnSpec`/`Summary.consume` worked instance (the R2-landed rule) AND
the lock-shaped ownership-transfer example (x5) both wait on this
slice — neither could be attempted honestly without it.

### 4.3 The depth cliff (`RelSem/Corpus/Z1.lean`, parked)

The 20-layer write1 ladder's open-memory mint did not complete in
25 minutes (vs ~90 s for c3b's 130 rounds at depth 2): each round's
hypothesis normalization walks the whole accumulated fenced write
tower, so per-round cost grows with depth. **Better-abstractions
work item (charter ruling: never a budget bump): index the
accumulating memory term** — named per-layer anchors
(derive_state-style) or a symbolic `writeSeq` spelling carried by
name — the [USER 2026-08-24] giant-terms representation-smell rule
applied to the mint's anchor states. Wall-clock measured under
shared-box contention (§5); the order of magnitude is the datum.

### 4.4 The width cap (z2_wide, recorded analytically)

Eight live locals = eight scratch ranges; the registered driver-atom
vocabulary covers 1–2 (scratch1/scratch1p/scratch2). The
generalization is the pointwise design at N ranges (the C3b
prescription that already generalized scratch1 → scratch1p) — or,
better, the frame-proper treatment where the atom names only the
ranges the POST mentions. Recorded as the width row of the
better-abstractions basket; fixture pinned with harness rows, mint
not attempted (contention + the analytic answer suffices).

### 4.5 Family-∀ (step 4 of the brief; park-with-price, no new price)

The R1 divmod / R5 swap family statements
(`speclab/SpecLab/DivModFiles.lean` `DivModI8FamilyStatement`,
CnSeed's analogue) quantify over the FILE — the expected bytes are
compiled-in constants, so the program TERM varies with the model
input. The engine mints at concrete file anchors only; the layer
does not reach symbolic-file families. This is the C4 record's
already-registered frontier (ground-mode materialization), price
unchanged: either file-parametric minting or the stream-as-INPUT
restatement (the mkHarness choice-stream design's anticipated
pivot). Honest state: sample-∀ faces remain the executable-validated
evidence; family-∀ stays UNPROVED and labeled.

## 5. Honesty notes

- **Two intermediate "green" claims during batch 2 were flawed**
  (checked grep's exit, not lake's): C3B's feeds/composition were
  claimed green while the module in fact failed (wrong boundary +
  wrong exit fuel + a 48G kill masking errors). Caught in-slice at
  the next build, diagnosed (the 49-round head; `fuel+35`), fixed,
  and re-verified exit-0. All COMMITTED trees are genuinely
  validated (full Tier A per commit); the flawed checks never
  reached a commit. Process fix adopted: every build check reads
  the build's own exit code.
- **Shared-box contention:** a second agent (golean) built
  concurrently during batch 4; my builds were serialized and the
  size-ladder wall-clocks are labeled order-of-magnitude.
- **The 48G→64G cap:** C3B and later corpus elaborations were run
  at the `scripts/capped` 64G DEFAULT after 48G kills; no
  maxHeartbeats/maxRecDepth change anywhere in the campaign (the
  one heartbeat-adjacent event — bx_chainrel unification timeout —
  was a genuine bug, fixed by correcting the fuel offset).
- **Proof-size gate:** corpus modules follow the T6Probe precedent
  (fixture+proof in one module, NOT registered in
  check_proof_size — the registered slate files are unchanged). The
  per-program manual-step numbers in §1/§2 are this record's
  accounting; the gate's 40-step bar is met trivially (2 steps) by
  every corpus theorem.

## 6. Census movements (all provenanced at the pins)

- step_law census: 191 → 252 → 302 → 327 (batch provenance comments
  at the pin; heapWalk UNCHANGED at 11 throughout; memBlock 6 → 7 =
  `mem_pvfd_block`).
- Audit sweep: 8982 → 10060 → 11501 → 12383 → 12404.
- Statement gate slate: 33 → 43 → 51 → 55 (22 corpus statements:
  11 headline + 11 twins; all fuel-opsem-clean).
- Cone pins: +25 in-build `#guard_msgs` pins, every one exactly
  `[propext, Classical.choice, Quot.sound]` (the 22 theorems +
  `c3b_run_seg`/`x7_run_seg`/`x2_run_seg`).
- Engine size: 6955 → 6963 (Rounds +8, the pvfd feeder; provenance
  in `scripts/engine_size_baseline.txt`).
- one-route live list: 40 → 51 (the 11 proved fixture modules).
- test_verify: 41 → 133 passed (22 fixtures, 88 harness points);
  EmitLeanCore slate: 6 → 21 emitted decls (incl. the params trio
  + the parked reproducers' data — drift-gated).

## 7. Validation (final battery, verbatim key lines)

Full Tier A at the closing tree — every command exit-checked, all
16 lanes exit 0 (battery log preserved in the worker transcript):

```
Total: 7 passed, 0 failed
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
check_one_route: OK — one state interpretation on the live route (51 modules OwnP-free; coexistence hazard clear; OwnP binders confined to the retirement register)
check_engine_size: engine total 6963 lines (baseline 6963)
info: RelSem/Audit.lean:698:0: RelSem statement gate: 55 slate statements fuel-opsem-clean (negative tests: t1_wp and the wrapper-hole probe correctly rejected)
info: RelSem/Audit.lean:1407:0: runEffectful no-cone gate: carrier set exact (104 registered ambient-family theorems; no acquisition, no stale entries)
test_verify: 133 passed, 0 failed (22 fixtures, 88 harness points)
test_speclab_divmod: PASS (--gate)
test_speclab_seed: PASS (--gate)
```

(The four exec baselines, bytes, libc_exec, multi_tu, parse,
core 106, elab, libxml2_uri 16/16, cn_coverage all exit 0, zero
movement — the batch-4 battery log. The step_law census and audit
sweep are `#guard_msgs`-PINNED in-build — green builds print
nothing; the pinned texts are the docstrings at the pins:
`step_law census: 327 laws [advance 5, construct 9, envAlg 3,
envMap 4, evalArith 2, evalPull 2, heapWP 4, heapWalk 11, loop 5,
memBlock 7, memRW 20, perform 6, roundGlue 3, segCanon 18,
segEq 162, segFact 62, segPost 2, wpSeq 2]` and `RelSem audit
sweep: 12404 declarations`.)

## 8. Commits

- `84a07ba52` — [F9] census + corpus plan (docs-only, BEFORE
  construction).
- `8e59abdd4` — BATCH 1: EASY tier e1–e5 (full Tier A green).
- `0baadc231` — BATCH 2: CENSUS tier c4/c5/c3a/c3b incl. the first
  corpus loop through the invariant route (full Tier A green).
- `dafd50451` — BATCH 3: the array-lane frontier (2 walls fixed,
  1 parked) + x7/x2 multi-exit edge rows (full Tier A green).
- `71a6a6e80` — BATCH 4: the call-rule root cause + the size-ladder
  cliffs, all parked with prices (full Tier A green).
- (this commit) — PROOF.md §3 corpus paragraph + this record.

## 9. What R6 hands the next rungs

- **R7 (purge):** nothing new owed; the corpus lives entirely on the
  live route.
- **R8 (playbook):** the corpus IS the playbook's example set — the
  E-tier template (~40 lines of true per-fixture data) is what the
  dumb-agent probe should be asked to produce.
- **R9 (capstone) and the census gap:** the uri.c scan rows need
  the ARRAY SLICE (§4.1) first; R9 should be re-scoped to land
  after it, or target a scan-free uri.c helper
  (`xmlIsPathSeparator`-class predicates are already in reach —
  e4/e5/c4 are exactly their shape).
- **Arc-19 (minting frontier):** §2.2's flat 12-entries/fixture
  boilerplate rate + §3.4's join-point-candidate emission + §4.3's
  memory-term indexing are the three measured work orders.
