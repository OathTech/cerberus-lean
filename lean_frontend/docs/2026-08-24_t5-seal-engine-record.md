# arc/t5-seal — seal-through-the-chase built (engineRev 5); the R13 wall REFINED, not killed

Date: 2026-08-24. Branch: `arc/t5-seal` (worktree
`worktrees/cerberus-lean-arc/workbench-v2`, base = mainline
`39aabec47`). Provenance: [AGENT:t5-seal] throughout. All builds via
`scripts/ce` + `scripts/capped`; no heartbeat/maxRecDepth/ambient
bumps anywhere (every budget below is a walker-internal LEDGERED
sub-cap or a pure fuel).

Commits: `35f8afdb3` (T5Ladder, audit W-1), `9f8080498` (engineRev 5).
Probe scratch (untracked, arc-11 §9 policy): `ProbeT5S4c.lean`
(slimmed to consume the committed ladder; `walk_vt N depth D` gained
the chase-depth argument), `ProbeSealKernel.lean` (whnfCore/casesOn
iota probes), outputs `scratch/probet5s4c-seal-r1..r30.out` (the
engine-iteration ladder; r30 = the final state) +
`scratch/probet5s4c-postmig-r1.out` (ladder-migration equivalence
run) + `scratch/ProbeT5S4c-pre-ladder-migration.lean.bak`.

## 1. Ladder migration (audit W-1) — DONE

`RelSem/T5Ladder.lean`: the ProbeT5S4c 25-entry have-fact ladder
(hpI1..hpS22) plus hlk513/hlk512 and the a543 extern/funs misses,
restated as committed theorems over the interstitial prefix family
`envP1..envP22` (one def per prefix of `envIter n k` over `envL n k`;
per-prefix `FmapBuilt`; `unitSym_cmp_ne` carries the stuck-seed
hdig/hseed + slate-bound discipline; `envP22_spec` is the rfl
coherence pin against `envL n (k+1)`). 32 exactness pins in
Audit.lean — the family sits at the clean quartet
`[propext, runEffectful, Classical.choice, Quot.sound]`; the two
pure-fixture rfl facts at the classical trio. Audit sweep re-baselined
3348→3356→3436 (ladder) →3522 (engine), reasons at the pin.

Equivalence validated by re-running the walk on the committed facts:
13 rounds fired, R13 stuck at `fuel + 66` — byte-for-byte the
pre-migration position (`scratch/probet5s4c-postmig-r1.out`).

## 2. The engine (engineRev 5) — what landed

Design target: the resumption record §5's SEAL-THROUGH-THE-CHASE.
Landed, in `Tactics/AppWalk.lean` + `WalkTrace.lean`:

* **kWhnfR** — kernel-refusal-visible whnf; chase-side calls are
  kernel-only (`fallback := false`): the old elaborator retry after a
  refusal was measured pure waste (~50k-heartbeat grind per refused
  form; the first R13 attack ground 38+ CPU-minutes in these).
* **Deep mode** — after any enclosing refusal, non-leaf forms are
  never handed to the kernel whole. Head progress: capped `whnfCore`
  + pure `headBeta` (whnfCoreCapped was measured silently no-oping on
  large beta-redexes — a caught runtime trip; headBeta cannot fail).
  Structure: **exposure** (`exposeStuck` — one delta+beta + capped
  whnfCore) surfaces the rec/matcher head for the (b) descent; the
  anchor stays the shallow reference and compositions cross
  `anchor = exposed` by one delta at the Eq.trans points. Leaf-sized
  subterms (≤ max sealDepth 192) keep full kernel treatment.
* **Checkpoint seals** (`chaseCheckpoint`) — intermediate forms past
  `WalkCfg.chaseSealDepth` (default 48; semantics documented in-code:
  a statement-inlining bar, NOT an ambient knob — count trades for
  depth) become named aux definitions; every certificate statement
  references seal constants. Kind `.chase` in the trace IR.
* **Propositional iota** (`getIotaLemma`/`applyIotaLemma`/
  `iotaByLemma`) — THE decisive certificate shape (see §3.2): iota
  steps are proved by GENERIC equation lemmas minted once per
  (head, ctor-vector) and cached process-globally; the generic RHS
  head is a bound minor/alt variable, so the kernel can only unfold
  the LHS — the check is local by construction; instantiating at
  eval-scale terms is application typechecking, zero reduction.
* **Robustness** — a kernel-refused link degrades to local
  no-progress (rev-4 behavior let one thrown kernel exception unwind
  50 productive levels); per-level settled heartbeat windows (the
  walkLoop per-round accounting pushed into chase levels — every
  primitive inside a level individually capped, total = depth ×
  per-level caps, ledgered); per-discharge memo cache (`ChaseCache`,
  fuel-guarded no-progress reuse, never shared across a restoreState
  boundary); process-global refused-head registry (a refusal is a
  ~20-30s kernel guard-trip — measured 36 × ≈ 598s in one attempt —
  paid once per head).
* **Engine defects fixed** (pre-existing, exposed by the climb):
  1. recursor descent used `args.size - 1` for the major — WRONG for
     over-applied recursors (motive returning functions: the monadic
     shapes); now `RecursorVal.getMajorIdx`;
  2. the (b) resume DISCARDED sub-advance progress when the parent
     did not unlock in one whnf (`continue` dropped p2);
  3. `findDecideFact`'s uncapped `isDefEq` tripped maxRecDepth on
     deep-state decide subterms (now attempt-capped probes).
* **Ledger** — obligations-per-chase logged (trace lane), e.g.
  verbatim from `scratch/probet5s4c-seal-r30.out`:
  ```
  kwf: chase ledger — 22 kernel obligation(s) this chase (prog=true)
  kwf: chase ledger — 44 kernel obligation(s) this chase (prog=true)
  kwf: chase ledger — 48 kernel obligation(s) this chase (prog=false, second-chance)
  ```
* **Tests** — AppWalkTest E11 (a DOCTORED chase link — false
  statement, refl value — must be kernel-refused at `addDecl`;
  negative-tested, with the async-elaboration caveat recorded: under
  `Elab.async` the kernel check is deferred but still build-fatal;
  the exercise runs under `Elab.async false`), E12 (checkpoint seal
  kernel-accepted defeq + propositional-iota certificate `check`-clean
  and kernel-added), E13 (deep chase on a kernel-guard-class
  major-chain synthetic; SKIP-tolerant on the refusal premise — the
  guard is an environment property).

engineRev 4 → 5 (history in WalkTrace.lean); stale recordings refuse.

## 3. THE R13 WALL, REFINED (the record's §5 assumption was incomplete)

The resumption record modeled the wall as REDUCTION DISTANCE vs the
kernel's recursion guard, fixable by keeping statements shallow.
Measured mechanics (reproducers: run the probe; per-finding outputs
cited):

1. **A kernel refusal is expensive, not just fatal**: `Kernel.whnf`
   churns ~20-30s before `deep recursion detected` trips
   (`kWhnfR 27746ms … refused=true`, seal-r6; 36 refusals ≈ 598s of
   one attempt, seal-r18). Refusing HEADS recur (the eval/bind
   family), so the head memo is process-global.
2. **Real term depth is NOT the wall**: at a representative refused
   link, `realDepth x=154 y=146` (seal-r21) — far below any
   plausible guard. The refusal is reduction behavior, not statement
   structure.
3. **Instantiated single-step defeq links are kernel-refused** even
   with SHALLOW (sealed) statements: checking `x = y` where y is ONE
   matcher/rec iota from x dies identically raw or sealed
   (seal-r18/r20: `link-cert ORD-EX: (kernel) deep recursion
   detected` on both attempts). Diagnosis: the kernel's lazy-delta
   unfolds the higher-definitional-height side — the REDUCT's head —
   and dives into continuing the whole eval instead of unfolding the
   matcher. Statement shape cannot fix an unfold-order problem.
4. **The fix that works is generic-level certification**
   (propositional iota, §2): with the RHS head a bound variable the
   kernel has no reduct side to prefer. Minted lemmas fired through
   `step_eval_pexpr_lemFuel.match_95` → `step_eval_peop` →
   `t0.casesOn`/`t0.rec` → `Option.rec` (seal-r24..r30), each an
   ordinary kernel-checked declaration, reusable across rounds.
5. **Where it still stalls**: the chase now penetrates ~55 levels
   into the Epure PEcase conv-chain (R13's semantic content: the loop
   guard's conv_int×2 comparison), but the monadic eval's remaining
   shapes (state-threaded bind spines with function-valued
   intermediates; concrete-but-large `valueFromPexpr` operand evals)
   still produce no-progress cascades — each engine iteration
   (~25-40 min measured cycle) has unlocked exactly one further
   layer, with an unbounded-looking count remaining. R13 attempt
   cost at park: ~17 min/attempt, 4 iota fires, 51 checkpoints,
   terminal collapse at an inner `full_eval_pexpr` sub-chase
   (seal-r30 lines 10902-11162).

## 4. Honest position and the named next moves

* 13/79 PRESERVED under the rev-5 engine (r30: R0-R12 fired, R13
  stuck at `fuel + 66`); all committed surfaces green (relsem 364
  jobs + gates, test_unit 7/7 incl. E1-E13, test_verify 29/29).
* R13 NOT killed; T5 remains parked at 13/79; the k=0 45/79 walk
  stands (neither subsumed nor retired). The proof-size T5 row stays
  honestly PENDING.
* Next moves, in preference order:
  1. **Finish the five-move calculus** (engine): the remaining
     deep-mode stalls are the same debuggable species (per-layer
     shape defects, each ~1 engine iteration). Moves already sound:
     beta (symmetric defeq), iota (generic lemma), delta (exposure
     crossing), position (Eq.ndrec, syntactic hint), leaf (kernel
     whnf). The stalls are navigation gaps, not certificate gaps.
  2. **The fact route for R13-class rounds** (hybrid): state the
     guard's conv-chain eval as committed context facts built
     T1-ladder-style (s1_t5..s4_t5 composition — terms stay
     moderate); the chase's eq-fact stage consumes them at the
     stuck crossing. "Fact classes already patterned" was the
     record's own model; the wall refinement says the facts must sit
     at the FULL-EVAL crossings, not only at lookups.
  3. **Kernel-canonical reduct construction** (engineering, larger):
     mirror kernel whnf step semantics meta-side so instantiated
     snapshot links match syntactically along the reduct path —
     registered as the heavy alternative; the generic-lemma route
     makes it likely unnecessary.
* Per-round cost reality: even post-R13, ~66 rounds at the measured
  chase costs (~minutes/round with warmed lemma/head caches) puts
  the full climb at hours-scale compute — fine for a landing run,
  but the iteration loop (edit → 15-40 min probe) is the binding
  resource during engine work. The lake job-output buffering (no
  live trace until process exit) doubles the pain — a streaming
  probe harness is a cheap quality-of-life register item.

## 5. Verbatim tallies (at `9f8080498`)

```
Build completed successfully (364 jobs).
Total: 7 passed, 0 failed
check_lem_sync: OK (src e51f885203ccdb8e83aa379e7e1ff3372598759c5b8e216ded6554f0d6181105, gen 50b87c916a110d01d86b05580aafda8f78761a614ac4305d963541758bf31029)
check_fork_drift: OK — layer 1: 58 oracle-surface files = manifest; layer 2: 20 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
check_proof_size: T5.lean — not present yet (registered, pending)
check_proof_size: OK
test_verify: 29 passed, 0 failed (5 fixtures, 18 harness points)
AppWalkTest: E1-E8+E10 kernel-checked, E9 preview-negative + E10-mismatch pinned
AppWalkTest: E11 doctored-link refusal, E12 checkpoint+prop-iota, E13 deep chase (engineRev 5)
AppWalkTest: ALL PASSED
```

T5Ladder flagship cones (all 32 pinned in-build, Audit.lean):
`[propext, runEffectful, Classical.choice, Quot.sound]` for the
envP family; `[propext, Classical.choice, Quot.sound]` for
extern_lookup_a543/funs_lookup_a543. The T1-T4 + entry5_walk +
T5Iter pins re-elaborated green under the rev-5 engine on every
build above.
