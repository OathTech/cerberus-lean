# Cargo-cult spot audit — the segment/mint abstraction stack (arc/segment-ladder @ 3ab5a0ee9)

[AGENT 2026-08-29, adversarial PL professor role — operator-designated
judge for "Iris in form but not substance"]. READ-ONLY audit of the
COMMITTED state of worktree `cerberus-lean-coherence`, branch
`arc/segment-ladder`, through `3ab5a0ee9` (working tree clean at that
commit at audit time). No builds run. Rubric: the design catechism
(`lean_frontend/docs/2026-08-27_design-catechism.md` §III), the
operator's question verbatim: "are we still staying true to our design
discipline — real Iris rules, no cargo cult? Proofs look like they
should look? Rules doing real work in the Brick / RefinedC tradition?"

All paths below are relative to
`worktrees/cerberus-lean-coherence/lean_frontend/relsem/` unless noted.

## VERDICT UP FRONT

**SUBSTANCE-CONFIRMED, with four findings (no MAJOR, none
soundness-touching).** The Iris layer is real Iris — genuine lifting
lemmas off `wp_lift_step`, fractional points-to, frame-preserving
updates, heap_adequacy-template ghost allocation, HeapLang-shaped
memory rules. The segment layer is real Floyd/Hoare. Mechanism C as
LANDED matches what the plan review adjudicated on paper. The anchors
are content, not spellings. Where the stack falls short of the
BRiCk/RefinedC tradition it is in AUTOMATION COVERAGE at the proof
surface (findings 1–2), not in the substance of the rules — and both
gaps are already named in the project's own records; the findings
sharpen them to deliverables.

---

## Per-sign verdicts (operator's watch signs, tested against code)

### (a) Anchors: restatement vs constraint — **CLEAN**

Specific target: `m1g1T/F`, `m1g2T/F` (`RelSem/M1Guard.lean:1087,
1108, 1179, 1200`), `m1term` (`RelSem/M1Body.lean:53`).

The attack was run: could the anchor be false for some x, or is it
true-by-construction from the walk? **It can be false, and the binders
are load-bearing.** Each guard anchor is quantified over `x : Int` and
the whole `Pack` (env frame, four supplies, layout), carries the range
bounds AND a path condition (`hlt : x < 0` / `hge : ¬ x < 0` /
`hgt` / `hle`), and the two sides of each pair state DIFFERENT
successors (`loadedV 1` vs `loadedV 0`) at the SAME input state — so
each anchor is false on the complementary half of the domain. The
proofs cannot be `rfl`: they route through the conditioned eval chain
(`m1cmp_lt_T` etc., M1Guard.lean:983–1077) down to
`m1GuardLtT/F` (M1Guard.lean:825–870-region), where the interpreter's
compare at symbolic operands reduces to
`if decide (v1 < v2) then Vtrue else Vfalse` and the path condition
resolves the `decide` via `decide_eq_true/false`; the conv_int range
clamps consume the intRange bounds (`omega`-fed). That is symbolic
evaluation under a path condition — Hoare content, not readback.

What the walk contributes is only the anchor's ADDRESS: the control
image spelling (`m1arB1`/`m1arB2`, the counter 9/30, the trace
`[meLoad x]`). Those literals are provenance-pinned to the generated
projections by kernel-checked `seg_pin_eq` pins (M1Guard.lean:666–669)
— a wrong paste is a loud kernel error. Anchor = Floyd cut point at a
concrete program location with quantified data; that is what an anchor
is. The successor is non-ground (a function of x through the arena and
trace). `m1term` is quantified over the returned value k, the trace,
the counter, and the pack — one fact for all three arms; its `rfl`
core is legitimate because a `PEval` redex never cases on k.

The pre-registered anchor bound holds as claimed: 5 registered facts
(4 guards + 1 terminal) ≤ 6 = 2·(2+0+0+1), and `M1Body.lean` consumes
zero generated per-round facts (mint walk + `m1g_inv`/`m1gShape`,
which are famInv/shape supply, not round facts — a fair reading of the
pre-registration's terms).

### (b) Rules whose premises secretly demand ground data — **CLEAN**

Sampled: `cstep_tau`/`cstep_eval`/`cstep_rs_tau`
(`RelSem/CStep.lean:130, 150, 170`), the crossings
(`runEU_aux2_sym/_ctor2/_step_then`, CStep.lean:191–291), and seven
link rules (`link_ctl`, `link_ctl_env1/2`, `link_birth1`,
`link_load`, `link_store`, `link_create`, `seg_done` —
`RelSem/SegRun.lean:556, 602, 643, 691, 931, 1064, 1319`).

The construct lemmas are quantified over the full `driver_state` σ
(cstep_*) or over the pack through an arbitrary family builder
(links). Groundness enters at exactly two honest places, both labeled
in the `@[step_law]` trace metadata as `ground(...)`: the DISCOVERY
premise (which step the interpreter offers at this control point —
i.e. the program's syntax, legitimately concrete, the PureExec
analogue of "this expression is a pure redex") and context INDEXES
(`env[i]? = some (x, vx)` — positions, not data). Data — cell values,
byte contents, supplies, the layout — is symbolic throughout; the
`happ`/`hm` payloads are ∀-pack fed premises discharged by the
hypothesis-fed crossings. This is precisely the Caesium/HeapLang
situation (concrete program, symbolic state), obtained as theorems
rather than by fiat, as the plan promised.

### (c) Ceremonial framing — **CLEAN**

`wpk_seq_ctl` (`RelSem/CerbStateWP.lean:124–140`) mentions ONLY the
control token; every env cell, allocation, byte range, supply and
residual rides the ambient frame — and the rule's `Happ` premise is a
genuine ∀-σ determinism obligation, so the frame is not decorative.
Concrete load-bearing case: in `p02_body`
(`RelSem/P02Proof.lean:60–187`) the errno allocation and byte cells
enter the context at the protocol and are never focused by any body
link — they survive ~110 rounds purely by the frame (the recursive
`envCells/allocCells/byteCells` context terms pass through untouched;
links focus single cells via the once-proved `envCells_focus`
accessors, SegRun.lean:93–158) and are dropped affinely at `seg_done`.
The context is footprint-sized (the program's own locals/objects),
carried as big-op-shaped list predicates plus the `mrestIs` residual —
the S2 "footprint + big-ops, never flat ∗-chains over the world" rule
observed. Not everything is in the footprint; the footprint is the
program's.

### (d) Case-splits at symbolic discriminants — **CLEAN**

`by_cases hlt : x < 0` in `M1Body.lean:79` / `P01Proof.lean:71` /
`P02Proof.lean:76` splits at genuinely symbolic data. Both arms
discharge from the path condition, not evaluation: the walk after the
split consumes the side's anchor, whose path-condition premise is
sourced from the LOCAL CONTEXT by `solveHyp`
(`RelSem/SegStepper.lean:177–219` — telescope binders first, then
local hypotheses, then a defeq-checked-NOW rfl fallback). Kernel
evaluation at symbolic guards is not merely avoided but structurally
REFUSED: `peSafePayload` (SegStepper.lean:1061) classifies the redex
before any kernel call and unsafe entries are loud fallbacks (the
"16–48G OOM" measured lesson, now doctrine). The readouts use the
path condition arithmetically (`rw [if_pos hlt]`, `omega` on the
satAdd model) — the human argument's arithmetic in the human's place.

### (e) Ghost state: mirror vs abstraction — **CLEAN, with notes**

- `envIs` (`RelSem/CerbStateRA.lean` header, lines 41–61): NOT an
  exact-image shadow — the interpretation holds an existentially
  quantified tracked map tied to the physical env by LOOKUP-level
  coherence only, with a documented honest gap (mid-run
  tracking-birth). Fragments yield pure lookup facts; updates
  re-establish coherence pointwise. An interface, with the classical
  logical-view-of-physical-state lineage stated.
- The domain ledger `domIs`: the authoritative-domain half that makes
  birth freshness a frame-preserving update instead of an axiom —
  gen_heap's alloc-fresh pattern for an env that fragments alone
  cannot make complete. Consumed through exactly one interface
  (`hfresh : symNum x ∉ domOf env` at the birth links). Not a shadow;
  a domain upper bound.
- `ctlIs`/`supIs`/`mrestIs` ARE ghost mirrors of state projections
  (exclusive ghost_var halves agreeing with the interp's halves).
  This is the deliberate program-in-state design of the driver
  language instance — the machine's "current expression" lives in the
  state, so the control image plays the role HeapLang's syntactic
  expression plays in WP. Standard ghost_var-halves idiom, confined
  by the two-faces rule (interp side in adequacy/lifting only,
  CerbStateRA.lean:66–70). Acceptable; watch that new assertions keep
  consuming `ctlIs` via small named constants, not inline terms.
- The persisted `segCtl_*` names (`compactLink`,
  SegStepper.lean:2720–2736): kernel-checked auxiliary DEFINITIONS
  (flattened control images), i.e. the sanctioned derive_state
  discipline — program syntax as named data, not assertions, not
  ghost state. Flattening is defeq-preserving with work bounded by
  program size (stated and argued in-code).

### (f) Per-instance lemmas in rule costume — **CLEAN**

The boundary is labeled honestly and mechanically distinguishable:
once-proved rules carry `@[step_law (kind := …)]` with lineage
strings; program-indexed supply carries `@[seg_round]`/`@[seg_block]`
(pack-quantified, hypothesis-fed — e.g. `p02r0_…` in
`RelSem/P02RoundsA.lean`), registered as SUPPLY and consumed by the
stepper as such. The m1 record and file headers state plainly which
facts are anchors and count them against a pre-registered bound. The
minted rounds are not lemmas at all — they are per-instance proof
terms of the once-proved construct lemmas, which is the honest shape.
No quantified vocabulary is draped over concrete-input artifacts; the
concrete-input ban gate exists and is negative-tested (Audit.lean:
632–712-region).

### (g) Bridges that only discharge at closed programs — **CLEAN**

`cerbSt_adequacy` (`RelSem/CerbStateAdequacy.lean:136`) is general
over expression, initial state (any `MemInv`+`EnvWf` state), tracked
footprint and domain; it allocates the ghost bundle from the physical
state by the heap_adequacy template (genHeap_init + ghost_map_alloc +
ghost_var splits) and maintains coherence invariants existentially in
the state interpretation. The harness bridges
(`kCallHarnessAdequateThrSt_of_wp`, `…Cns…_of_wp2`) are quantified
over file/fname/args/spec and are applied UNDER the statement's ∀x
by `verify_fn` — the ∀-input statements (`P02Statement`,
`M1Statement`: ∀ inputs ∈ full intRange, Cns face) genuinely flow
through. The Cns bridge discharges the consistency face from an
unconditional ∀-seed WP (discarding the hypothesis — strictly
stronger), which is plumbing, honestly labeled as such.

---

## Mechanism-C re-verification against the LANDED code

The plan review adjudicated the functional-big-step characterization
authentic on paper; the landed code MATCHES:

1. **The lemmas are what was promised.** `cstep_*` are introduction
   lemmas of the round relation, quantified over the state, with the
   class's semantic payload as a fed premise — strictly more
   quantified than the per-program round facts they replace. Their
   statements are plain `app`-equations about the fuel interpreter;
   their proofs go through the named advance laws
   (`dnmsRoundM_adv`, `advance_*`). Nothing in statement or validity
   depends on unfolding strategy.
2. **The kernel-pin device (`seg_discover`, `seg_pin_eq`,
   `mkRflHint`) is ordinary kernel computation, not steering.**
   `Lean.Kernel.whnf` is used only to FIND the step term / normal
   form; the certifying artifact in every case is a type-hinted
   `Eq.refl` that the kernel re-checks at declaration add
   (`RelSem/SegRoundTac.lean:158–231`). A wrong pin is a loud kernel
   error; no `ofReduce*`, no transparency toggles, and the
   "Kernel.whnf is debugging-API" caveat is recorded with the
   untrusted-use argument (perf record §6). This is the ACL2Lean
   pattern (reflection at ground leaves) as ruled.
3. **The ground-redex prong passes the steering test — narrowly but
   genuinely.** `peSafePayload` couples to an operational property of
   the evaluator (which PE* constructs case on symbolic data), which
   is the kind of coupling the forbidden clause watches. But it
   passes the trick filter's one-sentence test — "these constructs'
   evaluation never cases on the data, so kernel evaluation at
   symbolic data terminates" — is stated in-code
   (SegStepper.lean:1053–1060), it governs only a go/no-go
   performance guard with a loud fail-closed fallback, and no proof's
   validity depends on it. Contrast with the seal era: there,
   unfold-order was load-bearing for the proofs; here it is
   load-bearing for nothing but cost.
4. **Committed choice is real, with one acknowledged exception
   class.** Mint classification, `seg_peels`, block keys, and the
   arena-keyed round filter are head-syntax-committed with thrown
   frontiers. The stepper's registered-supply path still runs a
   candidates × links trial loop (SegRunCore,
   SegStepper.lean:2897–2909) and `seg_round_tac` is a `first` over
   four class macros (SegRoundTac.lean:454) — this is the
   `liFindHyp`-class bounded iteration the plan's A3 acknowledged in
   the donors, defensible exactly while failures stay cheap
   (they are: seg_discover fails fast; the arena pre-filter kills
   cross-fixture candidates syntactically).

## The proof-reading test (M1Proof/M1Body and P02Proof, read cold)

**The skeletons pass.** `p02_body` reads as the C function's own
argument: split on `a > 0`, split on the overflow compare, `a < 0`
likewise, the `a = 0` residue by `subst`; between cut points one
`seg_run`; at each exit the pure model's arithmetic by `omega`. Same
for `m1_body`. A grumpy professor recognizes this as a Hoare proof of
sat_add/sgn; the walks are engine room as designed. The statements
(`P02Statement`, corpus-frozen; `M1Statement`) are boring, ∀-full-
range, fuel-opsem-only. Structural coincidence: yes.

**The boundaries do not yet pass at RefinedC standards, and the gap
is transcription, not reasoning:**

- Each `seg_done` exit is one rule application carrying ~14 explicit
  engine coordinates — fixture arena constants, trace lists, round
  counters, fuel literals (P02Proof.lean:82–97 ×5 paths;
  M1Body.lean:82–142 ×3 arms). Every one of those values was computed
  by the stepper, which then stops with "apply `Seg.seg_done`" and
  discards them, leaving the user to transcribe. That is interpreter
  coordinates in user proof text.
- The caller protocols (`m1_wp` ~200 lines, `p02_wp` ~220 lines) are
  the same Iris text template-stamped per program (already the
  registered "next fusion target" since PERF-1).

Under the operator's calibration ("working tactics in complex cases,
never literal step-count") this is acceptable interim state; under the
proof-grind third-species rule it is a named missing automation step —
see findings 1–2.

## Meta-code assessment (SegStepper.lean, 2,979 lines / 136K)

Reviewable in the small: near-every private def carries a design
comment naming the discipline it implements, the measured incident
that forced it, and the failure mode (e.g. the `withProbeBudget`
honest-no-op note :51–62, the p02r35 ambiguity-deferral rationale
:259–290, the compaction "already small" hole :2726–2730). Failures
throw with instructive messages (the branch cut-point message tells
the user to case-split). Mint-mode is not an internal monolith — it
is factored into per-class minters (`tryMintLoad/Create/Store/Kill/
Core`) over shared devices (`mintMemHapp`/`mintMemFinish`,
`crossToResult`/`crossExceptM`, `buildSeStep`).

But the FILE is a monolith of roughly eight concerns, and at 3,000
lines it strains the "meta-code stays reviewable" clause of the
proof-scaling philosophy. Concrete decomposition (mechanical, no
behavior change): `Stepper/KernelPin.lean` (mkRflHint, kwhnf?,
kpinEqPremise, kMatchAssign), `Stepper/Premise.lean` (solveHyp,
fillHapp, dispatchPremise), `Stepper/Link.lean` (buildLink,
BuiltLink, linkConsts), `Stepper/Block.lean` (tryBlock, ctlArenaKey?),
`Stepper/Mint.lean` (the crossings + buildSeStep/buildEumapChain),
`Stepper/MintMem.lean` (the four memory minters), `Stepper/Compact.
lean` (flattenCtl, compactLink, chase*), `Stepper/Run.lean`
(parseGoal, roundCandidates, segRunCore). The three >200-line
functions (`tryMintCore`, `crossToResult`, `tryMintLoad`) are each
single-purpose and tolerable once homed.

## Trust spot-check (2 theorems)

- `RelSem.P02.p02_proved`: cone pinned EXACTLY
  {propext, Classical.choice, Quot.sound} by in-build `#guard_msgs`
  (`RelSem/Audit.lean:351–352`); statement `P02Statement` is in the
  statement-TCB + concrete-input gate slate (Audit.lean:796) and its
  text matches the frozen corpus row (∀ a b ∈ full intRange,
  satAdd 3-case model, UB-freedom twin —
  `docs/2026-08-27_target-corpus.md:130–133`). PASS.
- `RelSem.M1.m1_proved`: cone pinned exactly the trio
  (Audit.lean:359–360); statement text (M1Proof.lean:58) is the house
  Cns shape by inspection — but see finding 3: it is NOT in the
  mechanical statement-gate slate.

---

## FINDINGS (ranked)

**F1 (M — amortization). The guard/branch class lacks the
once-proved treatment; per-program hand supply returns at every
branch.** `RelSem/M1Guard.lean` is 1,220 lines for four guard anchors:
~500 lines of pasted program-AST spellings (provenance-pinned — fine)
plus ~25 hand theorems of which twelve (`m1GuardGtT/GtF/LtT/LtF`,
`m1sC_{gt,lt}_{T,F}`, `m1cmp_{gt,lt}_{T,F}`) are near-identical
modulo op × side, re-instantiating the P02Guard template at m1File
(the header admits this at :6–13; sharing with P01/P02 is partial —
z-stage constants imported, step/loop lemmas re-proved because the
eval inlines `conv_int` from the FILE's stdlib map). The catechism's
value test — "does the NEXT program get it for free?" — currently
fails for branches: program #3 with two `if`s pays ~700 proof lines
again. The park record priced building m1's anchors (row 1, M-S) but
no reusable minter or generic characterization is registered. Fix
(either): (i) a guard-chain MINTER (op × side × verdict, the
tau/eval/load minters' sibling — the chains are mechanically
identical); or better (ii) a FILE-GENERIC conditioned compare
characterization — the file enters only through the stdlib
`conv_int`/`catch_exceptional` bodies, which are identical across
compiled files, so one lemma family keyed on "file whose extern map
resolves conv_int to the standard body" amortizes across all
programs. This is the audit's top item.

**F2 (S-M — proof-surface transcription). `seg_done` and the caller
protocol leak engine coordinates into user proofs.** The stepper
stops at the terminal KNOWING the full context and message-drops it;
the user re-types famI/famO/cO/trace/counter/fuel by hand
(P02Proof.lean:82–97 et al.). The deliverable is a `seg_done`
auto-fill (mint the application from the stepper's stop state) — a
small extension of machinery that already exists. The caller-protocol
fusion (~200 lines/program, template-stamped across T1/T2/P01/P02/M1)
is already the registered next tranche; this audit confirms it is now
the LARGEST per-program manual mass and should not slip another
slice. Neither item is grind today (the volume is bounded and the
records price it), but both fail §IV.1's amortization test if a third
program lands before they do.

**F3 (S — gate coverage). `M1Statement` is outside the statement-TCB
and concrete-input gates.** The slate list (Audit.lean:772–809)
carries the T-slate and corpus rows but not `RelSem.M1.M1Statement`,
although `m1_proved` is the PERF-2 tightened exit — the very claim
whose worth rests on its statement being a quantified, fuel-opsem-only
canonical property. The text passes by inspection, and "exit
instrument, not frozen-corpus row" explains the omission, but the
class of exit-instrument statements should ride the same mechanical
gates as the corpus (the gate exists precisely so inspection is not
the last line). Fix: one line — add `M1Statement` to the slate list.

**F4 (trivial — repo hygiene).** Commit `3ab5a0ee9` committed 15
`lean_frontend/relsem/.lean_probe.*.json` scratch files (probe
temp artifacts). Delete and gitignore the pattern.

Minor observations, no action demanded: (i) the 2M file-level
`maxHeartbeats` caps (M1*/P02* files) are a standing 10× raise whose
remover is unnamed — the perf records treat "the tree-standing 2M file
cap" as the sanctioned baseline, but under the heartbeat doctrine a
named remover (e.g. "falls to default when the guard minter lands")
would regularize it; (ii) `seg_round_tac`'s `first`-of-four and
segRunCore's candidates×links loop are acknowledged donor-class
bounded iteration — keep the failures cheap, as now; (iii)
`SegStep.iter` is uniform-k per iteration (data-dependent branch-in-
loop bodies need the ∃-round `Seg.iter` face — the records know this;
watch it at T5).

## Answer to the operator, plainly

Real Iris rules: **yes** — the lifting skeleton, the fractional
footprint discipline, the frame-preserving updates, and the adequacy
allocation are the genuine articles, doing the work Caesium/HeapLang
rules do, at honestly labeled ground/fed boundaries. Proofs look like
they should look **at the skeleton** — spec, cut points, path
conditions, `omega` at the exits — and the anchors are real
path-conditioned content that would be false if the binders were
decorative. The distance from the BRiCk/RefinedC tradition is
concentrated in two named automation gaps (guard-class supply,
terminal/protocol transcription) that the project's own records
already price; they are the difference between "the machine reasons
like the human" and "the machine reasons like the human, then makes
the human copy out its notebook." Close F1/F2 before the third
branching program and the parity trajectory holds.
