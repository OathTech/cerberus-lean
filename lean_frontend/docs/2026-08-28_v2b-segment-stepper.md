# V2b — THE SEGMENT/STEPPER SLICE: block-fused segment rules + the cut-point stepper (slice record)

Date: 2026-08-28. Worker: V2b (orchestrated slice, arc-18 segment-ladder
infrastructure plan, component H first tranche). Worktree
`cerberus-lean-coherence`, branch `arc/segment-ladder`. The mover for
the V2 grind-shape finding (V2 record §3): per-round proof mass was
O(rounds × paths) generated text — P01's proof file was 1,387 lines
for a 5-line C program; P02 was PARKED at "63–117 rounds × 4 paths".

Commits: `73c8379c6` (the fused segment rules), `6a27fcf3d` (T1
retrofit), `4d25f9761` (the stepper), `62056e7cb` (P01 through the
stepper), `2f9d50efe` + `b918ea2bb` (the round-proving tactics),
`PENDING-P02` (P02 proved).

## 1. What landed (the fusion design)

Three layers, all in `relsem/`:

**RelSem/SegRun.lean — the block-fused segment rules.**
* `SegStep tagDefs tid n Γ Δ` — the SEGMENT SEQUENT: "n scheduler
  rounds of the peeled dnms loop transform context Γ into Δ", stated
  as a WP transformer (`Γ.interp ∗ (Δ.interp -∗ WP (dnmsK f …)) ⊢
  WP (dnmsK (f+n) …)`) so a per-block fact discharges the goal in ONE
  application (`SegStep.consume`). Fuel is split `F = f + n` by the
  caller — Nat-literal goals unify without add-inversion.
* `SegStep.trans` IS the Hoare sequence rule (round counts add);
  `SegStep.refl` the empty segment. Lineage: Floyd 1967 cut points /
  Hoare 1969 composition.
* THE CANONICAL CONTEXT (Lithium normal-form lineage): endpoints are
  first-order `Ctx` RECORDS (ctl image, supplies, env-cell list, mem
  residual, alloc/byte fragment lists) — composition unifies
  constructor-against-constructor, never through the assertion; the
  domain ledger is DERIVED from the env list (births cons both in
  lockstep). Cell access inside the once-proved link rules is by
  `envCells_focus`/`allocCells_focus`/`byteCells_focus` accessors
  (bigSepL_lookup_acc shape).
* SEVEN LINK RULES (tau / env-read / two-cell read / birth /
  birth+read / double-birth / load), each a `SegStep … 1` intro
  DELEGATING to the registered V1/V2 `wpk_*` state rules — the
  escalation ladder's floor is unchanged; every stride a chain takes
  is a named rule a hand proof can apply. The four BIRTH LEGS
  (new/preserve/reverse/wf + the `clsNone` ledger reasoning) are
  fused ONCE into the link rules: a birth that cost ~40 lines per
  instance in V2 is one premise (round equation + a freshness fact).
* `seg_done` — the fused TERMINAL rule: done offer + dnms residual +
  scheduler pick + `prepare_exit` + readout in ONE application (was
  a 5-block coda in every V2 proof).
* All 8 registered `@[step_law]` kind `segLink` with lineage strings.

**RelSem/SegStepper.lean — the cut-point stepper (`seg_run`).**
At a goal `Ctx.interp Γ ⊢ WP (dnmsK td F acc tid xs' k) …`:
repeatedly (1) query THE ONE REGISTRY for round equations (kind
`roundEq`, DiscrTree on the equation LHS; `@[seg_round]`/`@[seg_inv]`
supply attributes in RelSem/SegReg.lean) and filter by control-image
agreement; (2) trial-apply the seven link rules with pure-Meta
premise discharge — famI/famO PRE-PINNED first-order from the
equation's own entry/successor states (higher-order unification is
not trusted for the family slots); the control pin masks the pack
slot; family shapes and transports by hinted `rfl`; env/footprint
INDEXES computed against the canonical context, the index premise's
value-side UNIFICATION disambiguating same-key branch candidates;
ledger freshness by literal reduction + `Int`-decide membership
refutation; path conditions and range facts from the local context;
(3) emit ONE `SegStep.trans` chain consumed by ONE `SegStep.consume`.
STOPS at: branches (per-candidate failure report naming the missing
path conditions — the user case-splits), the terminal (`Sum.inr`
offer — `seg_done`'s job), or any undispatchable state (loud
fail-closed frontier). No `Elab.runTactic` recovery anywhere (the V1
hazard); per-ROUND heartbeat isolation (fresh count per round — walk
cost scales with round count; no global maxHeartbeats raise).
Lineage: brick-wp `wp_auto` / Lithium goal-directed rule application
one level up; the R4 registry-dispatch discipline.

**RelSem/SegRoundTac.lean — the round-proving tactics** (the supply
side of the same fix): `seg_round_tau` / `seg_round_eval` /
`seg_round_load` / `seg_round_term` + the dispatcher `seg_round_tac`
discharge the easy-class ROUND-EQUATION statements — the per-round
proof text V2's production line template-stamped is replaced by four
once-written tactic macros driving the same Kit laws (dnmsRoundM_adv,
advance_*, the stub/aux2 eval chains, the perform/load blocks).
Promoted generics: `intLoad_facts` (T1's loadX_eq_facts for any
4-byte int cell, autoParam side facts), `runEU_aux2_sym` and
`runEU_aux2_ctor2` (refine-friendly faces of the one-hit sym read
and the two-cell Ctuple scrutinee — P01's `p01ctor2_eval` promoted).
Key mechanism: the eval chains carry their data implicits AS GOALS
rotated behind the premises — `refine` rejects unassigned data
implicits, which is exactly why V2's hand proofs had to spell every
intermediate `z`; the premise proofs pin them by unification.
MEASURED COVERAGE: 35/41 of P01's registered rounds prove by
`seg_round_tac` alone; the residuals are the genuinely hard chains
(compare-verdict evals, Erun jumps) — hand-written on the same laws.

**The P02 hard-round layer** (added at the P02 build-out; the round
classes the P01-era tactics could not reach):
* `runEU_aux2_step_then` (SegRoundTac) — THE ONE-STEP-THEN-REST
  SKELETON: one aux2 iteration (the pull by the computable
  `pullSpine`, which assigns the pulled redex REDUCED — the
  `pull_constrained_spine` law turns the pull side condition into a
  computation; the step by a per-shape `se_*` law where the cell
  reads enter), then the REST of the eval loop as one `rfl` — closed
  once the read values are plugged. This made the case-pair verdict
  rounds (`PEcase` over two cells → compare arm), the
  conv-at-a-cell rounds and the Erun-jump rounds STATEMENTS-ONLY:
  the r15-class/r43-class/r60-class chunk failures all collapse into
  `seg_round_eval`.
* `seg_se_scrut`/`seg_se_step`/`seg_eumapM` — the per-shape
  single-step solvers (case-select with cell-fed scrutinee, call
  with cell-fed args, sym hits), all data implicits goal-ified and
  rotated behind premises (the z-spelling fix applied one level
  down).
* `RelSem/P02Guard.lean` — the CONDITIONED chains, proved ONCE
  value-generically (the P01 R10 fixture chain generalized over BOTH
  operand values and the compare op): the conv ladder
  (`p02sLe/p02sAnd/p02sIf`), guard verdicts `p02cmp_{gt,lt}_{T,F}`
  (`(v₁, v₂)`-generic whole-loop faces), and the checked-arith arm
  `p02arm_{sub,add}` (the T2 `sT2catch` template at the call-form
  conv, consumed as the skeleton's `hrest` after the case-select
  step). Class tactics `seg_round_guard`/`seg_round_arith` are
  DETERMINISTIC three-peel structures — the backtracking
  `first`-storm over arena-sized goals was measured pathological
  (12M-heartbeat non-termination where the deterministic proof runs
  in seconds; see §5).
* Generator conditioning: guard/checked-arith rounds are detected
  from the round's redex diff and emitted WITH their path conditions
  (`0 < a`, `2147483647 - a < b`, …, intersected across the paths
  sharing the round) and operand-range hypotheses; the round
  statements stay true theorems, `omega` discharges the lemma side
  conditions from them.

## 2. The retrofits (before/after engine mass)

| Artifact | V2 (per-round idiom) | V2b (fused) | Note |
|---|---|---|---|
| T1Proof.lean | 734 lines (+ maxHeartbeats 4M bump) | 451 lines, NO bump | body = `seg_run; exact seg_done …` (2 steps between cut points) |
| P01Proof.lean | 1,387 lines (+ maxHeartbeats 8M bump) | 331 lines, NO bump | body = `seg_run; by_cases hlt; (seg_run; seg_done) ×2` + two omega readouts |
| P02 | PARKED (priced ≈ 4× P01's post-split volume ≈ 15k lines at the old idiom) | TBD-P02 | see §3 |

The T1/P01 proof-file residual is dominated by the ~150–175-line
caller-protocol boilerplate (identical shape per arity class across
programs) — the honest next fusion target; without it both files are
under the 250-line registration bar. Cones unchanged throughout:
exactly {propext, Classical.choice, Quot.sound}, pinned in-build.

TWO PRE-EXISTING HEARTBEAT BUMPS REMOVED (T1Proof 4M, P01Proof 8M) —
the fused idiom needs neither. (P02Rounds carries the T2Rounds-class
2M supply-file option — a supply-side residual, registered below.)

## 3. P02 (TBD-P02 — filled at close)

## 4. The tactic's contract (summary)

* `seg_run` consumes rounds only through REGISTERED equations and the
  REGISTERED link rules; everything it emits is an ordinary kernel
  term (ACL2Lean discipline); nothing is certified meta-side.
* It stops (does not fail) at cut points: branch/terminal/frontier.
  A stop after ≥1 round consumes what it has (the goal is at the cut
  point); a stop at zero rounds is a loud error with per-candidate
  diagnoses.
* Soundness backstops observed working during bring-up: two unsound
  meta shortcuts (a vacuous hinted-refl type check; a data hole
  filled from the local context) were caught by the KERNEL rejecting
  the emitted term / by value-checked index premises — fixed at the
  meta level, with the kernel as designed backstop.

## 5. Walls and findings

* **refine vs data implicits** (the z-spelling tax): Lean's `refine`
  rejects unassigned data implicits, which is why every V2 hand proof
  spelled every intermediate eval value. Goal-ifying them
  (`(z := ?_)`) and rotating them behind the premises lets unification
  pin them — the single trick that turned the eval chains tactic-able.
* **HO unification is not for family slots**: famI/famO must be
  pre-pinned first-order from the equation's own states; otherwise
  the unifier invents constant functions capturing telescope
  variables (kernel-rejected) or stuffs pack updates into the family.
* **Supply normal form**: round successors must be spelled
  fam-applied (`fam a tr n {p with …}`); two V2 load rounds were
  respelled (defeq — proofs unchanged). Phantom ∀-binders in supply
  statements are now a loud stepper error.
* **The a = 0 fifth path** (P02): the V2 park priced 4 paths; the
  probe at a = 0 walks a FIFTH round-distinct sequence (both guards'
  first operands false, second operands unevaluated). Statement-level
  ∀-coverage forced its discovery — the case analysis closes it by
  `omega`/subst. (Measured: 63/111/117/112/90 rounds per path,
  shared 24-round prefix; 349 distinct round instances after dedup.)
* **The deterministic-peel finding** (P02 guard rounds): the class
  tactics' `first`-backtracking is quadratic-to-divergent on
  arena-sized goals — every failing alternative pays a whnf of the
  giant term, and failing branches recurse into deeper failing
  branches. The r12 guard round DID NOT TERMINATE at a 12M-heartbeat
  diagnostic budget under the backtracking tactic and proves in
  ~seconds as a deterministic three-peel refine chain. Consequence:
  `seg_round_guard`/`seg_round_arith` are deterministic; the
  remaining backtracking class tactics carry the cost as the
  SLOW-round register (below). The general fix — structure-dispatch
  instead of try-fail — is the registered remover.
* **The SLOW register** (P02RoundsA): two rounds
  (`p02r28_hi_mA`/`p02r29_hi_mA`, the post-first-load
  composite-arena eval/tau) exceed the 2M supply-file heartbeat cap
  under the backtracking class tactics and carry a per-round
  registered `set_option maxHeartbeats 16000000 in` (doctrine
  register entry; remover = the deterministic-dispatch tactic
  redesign above). No global bump anywhere.
* **Generator defect found by the machinery** (the plant-test dynamic
  in reverse): the second-load rounds' byte hypotheses were emitted
  from the OLDEST trace entry (`xBytes a` at the b-cell) — the trace
  conses new events at the FRONT. The false hypothesis made the
  round UNPROVABLE (not silently wrong): the fused load proof
  refused. Fixed in the generator; same class of fix for the midC
  `0 + b`-vs-`b` value-spelling ambiguity (prefer the plain
  variable; `0 + b` is not defeq to `b` at symbolic `b`).
* **Registered residuals**: (1) caller-protocol fusion (per arity
  class, ~150 lines/program — the next tranche); (2) hard-round
  classes still hand-written (compare-verdict chains, Erun jumps) —
  candidate generic lemmas exist (the conv/compare arm shape is
  program-independent); (3) P02Rounds' 2M supply-file heartbeat
  option (T2Rounds-class); (4) the supply generator lives at the
  container (.v2b-logs/gen_p02.py) — an instrument, not repo code;
  its output is ordinary checked Lean.

## 6. Gates at close (TBD — verbatim lines at close)
