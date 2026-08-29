# Adversarial review — the proof-performance plan (2026-08-28)

REVIEWER: [AGENT] adversarial PL/proof-engineering review, commissioned
under the operator rulings quoted in the plan's header ("optimizations
which couple to the representation structure without insight are
absolutely totally and completely forbidden"; "making up your own terms
('seal engine') is also forbidden"). Read-only; no builds. Target:
`notes/2026-08-28_proof-performance-plan.md`. Evidence examined:
`lean_frontend/docs/2026-08-28_v2b-pause-record.md`,
`…_v2b-segment-stepper.md`, `2026-08-27_design-catechism.md`,
`notes/2026-08-27_infrastructure-plan.md`,
`…_whole-project-assessment-disposition.md`; branch `arc/segment-ladder`
files (`RelSem/P02Guard.lean`, `P02Rounds*.lean`, `SegRoundTac.lean`,
`SegStepper.lean`, `SegRun.lean`); `deps/refinedc`
(`theories/lithium/{syntax,interpreter,base,solvers}.v`,
`theories/caesium/{bitfield,int_type,lang}.v`) — every file:line cite in
the plan was opened and read.

## VERDICT: SOUND-WITH-AMENDMENTS

No mechanism in the plan is a forbidden hack in costume. The classical
names are real and the mechanisms as specified instantiate them; the
donor cites are all genuine and mean what the plan says; the cost-center
story matches the measurements with one attribution error; the seal-era
classification (§4) is accurate against the record. The amendments are
exact and listed at the end; the two that matter most are (A1) the
PERF-2 exit is gameable by relabeling per-round facts as "anchors" and
must be tightened before sign-off, and (A2) CC2's "composite arenas the
multiplier" contradicts the pause record's own chain-shape measurement.
Nothing found rises to UNSOUND; nothing found requires a mechanism to be
struck.

---

## 1. Cite verification (all checked against source)

Every RefinedC citation is real and load-bearing as claimed:

- `lithium/syntax.v:10-70` — the `li.` goal grammar
  (exhale/inhale/all/exist/case_if/find_in_context/subsume) exists as
  described. ✓
- `lithium/interpreter.v` — `lazymatch` committed dispatch throughout
  (52 occurrences); `liUnfoldLetGoal` at 18-38 with the verbatim
  "not too bad for performance since the goal is small at this point"
  comment; `tac_fast_apply` 1-2% note + coq-speed link at 182-184;
  the branch-pruning normalization comment at 1117-1119. ✓
- `lithium/base.v:40` `Global Opaque Z.shiftl Z.shiftr`; base.v:50-53
  the pruned zify cleanup after a measured ~200% slowdown
  ("kvm_set_valid_leaf_pte"). ✓
- `lithium/solvers.v:47` — backtracking-by-recursion inside
  `refined_solver`, a pure leaf solver. ✓
- `caesium/bitfield.v:290` (`Typeclasses Opaque normalize_bitfield`),
  bitfield.v:~449 (`Global Opaque bf_nil bf_cons …`),
  `int_type.v:41` (`Typeclasses Opaque int_elem_of_it`). ✓
- C1's structural claim: Caesium's opsem IS an inductive small-step
  relation — `lang.v:397/499/535` (`expr_step`/`stmt_step`/
  `runtime_step`, all `Inductive … Prop`). ✓

**One overstatement found (F4 below):** L1's "Backtracking exists only
in leaf side-condition solvers … the main walk never backtracks" is not
literally true. `liFindHyp` (interpreter.v:537-569) iterates context
candidates with `first [ … | go P Hs2 ]`, and `first [...]` appears at
interpreter.v:273, 372-390, 465, 540, 564, 572. What makes the donors'
candidate iteration survivable is that each attempt is CHEAP — they
unify "using the opaqueness hints of typeclass_instances" precisely
because "directly doing exact: eq_refl sometimes takes 30 seconds to
fail" (interpreter.v:543-549, verbatim). That comment is the donors' own
r127. The correction does not weaken the plan — it strengthens it: the
donors' real defense against speculative-unification cost is
opacity-bounded cheap failure (mechanism D) at least as much as
committed choice (mechanism A). The plan should say so, because it
changes A's effect claim (see F5).

## 2. Name-authenticity, mechanism by mechanism

**A — committed-choice dispatch: AUTHENTIC.** "Committed choice" is a
real term (don't-care nondeterminism in concurrent logic programming;
syntax-directed rule selection in every standard type-checker and in
Lithium's `lazymatch` walk). The mechanism as specified — select the
leaf by a syntactic discriminant read the same way the generator reads
the redex diff; no `first` over candidates where a key exists — is the
named thing. The premise that the discipline is unfinished is verified
on the branch: `SegRoundTac.lean` still carries multi-variant
`first`-dispatch at lines 195/212/229/250/284/331 (the cheap
`first | assumption | rfl` leaves are fine, Lithium-analogous).
Legitimacy story (changes which proof is attempted, never what is
proved) is exactly right.

**B — block fusion: AUTHENTIC MECHANISM, one decorative word.** The
mechanism is lemma fusion by a once-proved composition rule —
`SegStep.trans` is the Hoare sequence rule, and the branch already
carries the honest lineage (SegRun.lean: "Floyd 1967 cut points / Hoare
1969 composition"). Semantics-preservation is by the existing
composition theorem; the empirical warrant (p02add_evalR /
p02conv_chainR whole-loop lemmas checking in seconds vs 16M+ split) is
real, per the pause record. The word "staging" is the one stretch:
classically staging is multi-stage programming; "choosing the
obligation unit at generation time" is defensible as staging but the
load-bearing classical name here is derived-rule composition at
Floyd-style cut points, which the plan also gives. Drop or explicitly
justify "staging" (amendment A9). Not a costume — the real name is
present and the mechanism does what the real name says.

**C — the derived small-step presentation: AUTHENTIC. Full
adjudication in §3.**

**D — opacity with completeness: AUTHENTIC, enforcement gap.**
Abstraction barriers / sealed interfaces is a real classical concept
and the donors' standing practice (verified cites above). The
completeness rule is CHECKABLE, not aspirational: a proof that needs a
sealed unfolding fails loudly at elaboration, per-instance — the same
falsifiability regime as Rocq's `Global Opaque`. Two amendments: (i)
the loud failure invites the quiet local fix — a worker flipping
transparency back locally (`attribute [local …]`-class reversals) is
exactly the "transparency toggle" the plan itself forbids; make the
reversal mechanically detectable (greppable ban on re-transparency of
sealed names in proof files, registry of sealed names) rather than
discipline-enforced (A8). (ii) Lean's `irreducible` binds the
elaborator, NOT the kernel — kernel defeq ignores it. Loudness holds
where it matters (elaboration), but kernel-side normalization of sealed
symbols can still occur on terms reached by other routes; this is a
perf residue to measure in PERF-0/3, not a soundness issue — the plan
should note it so nobody mistakes D for a kernel-level barrier.

**E — module-DAG parallelism: TRIVIALLY AUTHENTIC** (build-level
parallelism, no proof content). The problem is operational, not
conceptual: see F7.

**F — timing lane: TRIVIALLY AUTHENTIC** (donor practice verified —
the coq-speed link is really in interpreter.v). No objection.

## 3. Mechanism C — the adjudication in full (the hardest look)

**The lineage claim is genuine.** "Functional big-step semantics" is a
real literature concept (Owens–Myreen–Kumar–Tan, ESOP 2016: clocked
functional interpreters as the semantics of record, with proved
equivalence to relational presentations; adjacent: Danvy's functional
correspondence between evaluators and abstract machines; Amin–Rompf's
definitional-interpreter soundness proofs, POPL 2017; Leroy–Grall on
big-step presentations). The move the plan proposes — for a semantics
given as a fuel/clocked FUNCTION, derive the RELATIONAL presentation as
theorems: one ∀-quantified characterization lemma per construct,
premised on the V1 fragments (`envIs x v` etc.), consumed by the WP
rules in place of per-program ground equations — is precisely the
function→relation direction of that correspondence, obtained as
theorems rather than by re-axiomatizing the semantics. The construction
matches the named concept. One precision note: what is derived is a
relational/rule presentation of the interpreter's ROUND (the round is
already the step), so "derived inversion/lifting lemmas for a
definitional interpreter" is the exact name and "small-step
presentation" is a fair gloss. The plan should also name the
Iris-native precedent it is converging on — HeapLang's
`PureExec`-class per-construct step characterization, proved once and
consumed by `wp_pure`-style tactics — which strengthens the canon-first
case and satisfies the reuse-discipline point 4 (noticing convergence
on existing Iris machinery). (Amendment A7.)

**Is it unfolding-order steering reborn? NO.** Applying the plan's own
test (anything explicable only by narrating evaluator behavior is
rejected): every artifact C produces is a quantified THEOREM about the
interpreter's value — "at an `Eif` whose discriminant reads cell x,
with `envIs x v`, the round steps thus." What is proved is independent
of when or in what order any evaluator unfolds anything; the lemmas
survive any change to elaborator or kernel evaluation strategy;
instance proofs apply them by ordinary unification against fragments.
Contrast the seal era's own tell (plan §4, accurately): proofs there
still DEPENDED on unfolding happening, merely in a controlled order.
Here the unfolding is paid once, inside the once-proved construct
lemma, and never again. C is also the unique mechanism that moves the
design TOWARD the catechism (§VI: more ∀, less ground; §IV.1 cost
tracks structure) and toward the [USER 2026-08-26] ruling that
rounds/walks are engine-room supply, never user-facing. It kills CC3
by making it unnecessary, not by hiding it.

**Honesty of the risk paragraph: good.** The plan names the exact
place it may fail (symbolic-fragment generality — where V1/V2 paid the
F-technique and instance-generic walls) and gates the package on a 2-3
construct probe with a measured go/no-go. That is the anti-seal
pattern: probe, measure, commit — not collide and iterate.

**Two amendments on C.** (i) Provenance: "it largely IS the
already-promoted V3a item #1" is not locatable in the committed record.
The infrastructure plan has V3a = Component D (scalar loops + variant
rule, `notes/2026-08-27_infrastructure-plan.md:271`); per-construct
symbolic rules are Component C, chartered at V2 ("the heart", line
108-116) and left incomplete by the V2/V2b interim round supply. The
"assessment-C completion" half of the claim is verified
(whole-project-assessment-disposition §B2 "per-construct symbolic
rules … the heart"); the "V3a item #1" half needs a record cite or
rewording (A6). (ii) Scope-fold exit ramp: folding PERF-2 into V3a
couples V3a's fate to the probe. State the fallback now: on probe
no-go, B-granularity fused supply remains the default and V3a proceeds
on it — so a no-go is a park with a price, not a blocked arc (A10).

## 4. Evidence honesty — findings

**F1 (attribution error, the one real evidence defect).** CC2 says
"composite arenas the multiplier." The pause record says the opposite
about its own control experiment: r28/r29 (composite-arena) time out at
2M while r128/r129 at the SAME arena size pass at 2M — "the cost driver
is the CHAIN SHAPE (extra refine-unifications), not arena size alone"
(pause record §3, verbatim). Chain-shape cost is CC1-adjacent
(unification volume), not ground-evaluation volume. This matters for
mechanism accounting: B plausibly fixes chain-shape cost by eliminating
per-round refine setup entirely, but the plan should own that
attribution explicitly rather than fold it into "arenas". Amend CC2
(A2).

**F2 (r127/CC1: correctly reported).** The plan's CC1 narrative matches
the pause record exactly, including the independently-confirmed root
cause (call-form arm lemma could NEVER unify against the primitive
`PEconv_int` form; the 64M/21-min run was grinding toward inevitable
failure; the correctly-shaped `p02add_evalR` checks in seconds). Marked
root-caused in the record, cross-checked here. No overclaim. "Dominant
pathology" is fair for worst-case severity; note that AGGREGATE wall
time is CC2's (52+ min of chunk builds are mostly green rounds at
~9 s/round) — one clause fixes it (fold into A2).

**F3 (PERF-1 not overclaimed).** The plan states plainly that A does
not fix CC2 and B does not fix CC3. The ≤5-min exit is optimistic
arithmetic (40-60 fused facts × seconds each) but it is stated as a
falsifiable exit, not a claim, and PERF-0 profiling precedes it. The
derived tallies (9 s/round from 88 rounds ≈ 13 min; "26 rounds" vs the
33 `maxHeartbeats 16000000` occurrences now in P02RoundsA-D, the extra
being the guard/arith rounds the record notes separately) are shown
with their derivations — acceptable under the derived-but-labeled rule.

**F4 (L1 overstatement).** As §1: Lithium does iterate candidates in
context search; correct the "only in leaf solvers" sentence and cite
interpreter.v:543-549 — which converts a small embarrassment into
donor evidence FOR mechanism D (A3).

**F5 (A's effect claim needs one precision).** "A kills CC1" holds for
the r12 class (backtracker → committed single variant, measured
~50 s). For the r127 class, committed choice only helps if the
dispatch key INVENTORY discriminates at the failing level — the
primitive-vs-call arm form is one level below the op/verdict keys the
generator currently reads from the redex diff. A wrong single
commitment still grinds slowly unless D makes wrong-shape failure
cheap. State it as A+D jointly kill CC1, and require A's spec to
enumerate the key inventory down to arm form (A4).

## 5. Gameable exits — tightening proposals (exact)

**PERF-2's "a NEW scalar program requires ZERO generated per-round
facts (anchors only — count them)" is gameable three ways:** (a)
relabel per-round facts as anchors ("anchor" is undefined — declaring
every round a cut point satisfies the letter); (b) choose a "new"
program exercising only the 2-3 probed constructs; (c) let anchor
count balloon while nominally zero per-round. Tightening (A1):

1. Define anchor: a generated fact is an anchor iff it cites a
   cut-point reason drawn from the program's SYNTAX (branch /
   loop-head / call / terminal), is stated over V1 fragments with
   quantified data values, and contains no ground successor state.
   Ground-state supply facts are per-round facts whatever they are
   named; the B0 concrete-input statement check is the mechanical
   backstop and should be cited as applying to supply files.
2. Bound the count structurally, in advance: #anchors ≤
   k·(#branches + #loops + #calls + 1) with k fixed (propose k = 2)
   before regeneration.
3. Pre-register the new program BEFORE the construct package lands
   (the t6 never-seen-program precedent, arc-17), chosen to include
   at least one construct outside the probe set.

**The ≤5-min chunk exit** is gameable by moving cost between modules
(chunks shrink, P02Guard or engine modules absorb) or by warm-cache
measurement. Tightening (A5): the metric is the COLD, serial, capped
(48G) rebuild wall time of the full P02 supply closure — Rounds base +
all chunks + P02Guard — measured in the F timing lane under pinned
conditions; and "SLOW register ≤ a handful" becomes a number (propose
≤ 5), each entry with a named remover.

**The ~200k tokens/hour exit** is a confounded proxy: the pause record
itself says throughput already recovered substantially when discovery
switched to per-file probes (builds demoted to background) —
independent of CC1-3 — so PERF-2 could "pass" this exit for reasons
unrelated to PERF-2; it also depends on task mix and worker verbosity.
Tightening (A5): demote tokens/hour to a Tier-C reported indicator in
the F lane (labeled derived, orchestrator-attributed) and replace the
exit with a build-latency criterion: no build on the proof-slice
critical path exceeds ~5 min; supply regeneration for a P02-class
program ≤ ~1 min (the plan's own number, kept).

## 6. Omissions — what the measurements demand that the plan skips

1. **r257 is undiagnosed** (case-at-cell timeout, "possibly
   conv-conditioned" — pause record §2/§4). It is the one measured
   failure outside the CC taxonomy. If it is a fourth pathology class,
   the plan's coverage claim is wrong. Demand: triage in PERF-0/1;
   until classified, it is a hole in "top three cost centers" (A2).
2. **Chain-shape cost inside GREEN rounds** — F1 above; the fourth
   cost center hiding in plain sight, probably absorbed by B, but
   currently attributed to the wrong thing.
3. **Caller-protocol boilerplate** (~150-175 lines/program, "the
   honest next fusion target" — slice record §2) is absent from the
   plan. It is proof-text mass, not build time, but it bears directly
   on the PERF-1 proof-size registration decision and on any
   throughput metric. One line scoping it in or out, with the record
   cite, suffices.
4. **The generator becomes more load-bearing under B/C** (fused
   statements, syntax walks) while living as an uncommitted
   container-level instrument (.v2b-logs/gen_p02.py). Its output is
   ordinary checked Lean (trust is fine), but supply regeneration
   should be deterministic and the instrument versioned/committed
   before it becomes the default supply path — otherwise the supply
   is unreproducible at audit time.
5. **Elaborator-vs-kernel attribution is still pre-profiling.** The
   plan is honest about this (PERF-0 is first), but CC2's "elaborator
   whnf" wording is asserted ahead of the measurement it schedules.
   Acceptable as written; PERF-0's exit covers it.

## 7. Forbidden-list completeness

The plan's rejected list (unfold-order steering, transparency toggles
without completeness, budget raises, ofReduce*/native, integrity-
violating caching, weakened statements) matches the operator rulings
and catechism §III items 3-6/8. The two §III items not on the list are
handled structurally rather than by listing: **enumeration** (§III.2)
— the per-round supply IS per-instance kernel volume, and the plan says
so itself (CC3) and retires it via C; B's interim block-granular ground
facts track program structure (blocks between cut points), which is
§IV.1-compliant as an end state, but B must not become a resting place
— the plan's ordering (C after B, supply regeneration at anchor
granularity) already prevents this, and amendment A1's anchor
definition makes it mechanical. **Concrete-input statements** (§III.1)
— supply facts are proof-layer engine equations serving ∀-statements
(the [USER 2026-08-26] engine-room ruling), not target theorems; A1
point 1 puts the B0 gate over them anyway. **No accepted mechanism
belongs on the forbidden list.** The §4 seal-era classification was
checked against the record and is accurate — including the honest
identification of the one legitimate insight (obligation granularity)
the seal era almost had, which B now does properly.

## 8. Where the plan is plainly right (stated as required)

- Every donor cite is real, at the stated line, meaning what the plan
  says. This is the best-cited design document in the project's record.
- The r127 root cause is reported exactly as measured and
  independently recorded; nothing conjectured is passed off as
  root-caused except as flagged in F1/omission 5.
- Mechanism C is the genuine article: real lineage, construction
  matching the named concept, passes the plan's own
  narrating-evaluator-behavior test, and moves the design toward the
  catechism rather than around it.
- The plan does not overclaim PERF-1, prices its own risk at the
  honest place (C's symbolic-fragment probe), and its §4
  classification of the seal era would survive a hostile re-read.

## AMENDMENTS (each exact; verdict is SOUND with these)

- **A1** Tighten PERF-2's exit: anchor definition (syntax-cited
  cut-point reason, fragment-quantified, no ground successor states;
  B0 gate applies to supply files), structural anchor bound
  (≤ k·(#branches+#loops+#calls+1), k pre-stated), pre-registered new
  program including a construct outside the probe set.
- **A2** Fix CC2's attribution: chain shape (extra
  refine-unifications), not arena size, per the record's r28/r29 vs
  r128/r129 control; assign chain-shape cost to B explicitly; add r257
  as unclassified with a PERF-0/1 triage obligation; split "dominant"
  into worst-case (CC1) vs aggregate (CC2).
- **A3** Correct L1: Lithium's `liFindHyp` iterates context candidates
  (interpreter.v:537-569); its defense is opacity-cheap failure
  (interpreter.v:543-549) — cite it as donor evidence for D.
- **A4** State A+D jointly kill CC1; A's spec enumerates the dispatch
  key inventory down to the arm-form level that r127 needed.
- **A5** Exits: ≤5-min = cold/serial/capped rebuild of the full P02
  supply closure incl. P02Guard, pinned in the F lane; SLOW "handful"
  → ≤ 5 named entries; tokens/hour demoted to Tier-C indicator,
  replaced as exit by the critical-path build-latency criterion.
- **A6** Cite or reword "already-promoted V3a item #1" (committed
  record has V3a = Component D; per-construct rules = Component C at
  V2); cite the operator authorization claimed for E's experiment.
- **A7** C's name, precisely: "derived relational presentation
  (introduction/inversion lemmas) of a clocked definitional
  interpreter — functional big-step lineage (Owens–Myreen–Kumar–Tan,
  ESOP 2016)"; name the Iris-native precedent (PureExec-class
  per-construct step characterization) per reuse-discipline point 4.
- **A8** D: greppable ban on local re-transparency of sealed names in
  proof files + a sealed-name registry; note that `irreducible` binds
  the elaborator not the kernel (perf residue to measure, not a
  soundness gap).
- **A9** B: drop "staging" or justify it in one sentence; the honest
  classical anchor (Floyd cut points + Hoare sequence rule applied at
  generation time) is already in SegRun.lean's lineage strings.
- **A10** State PERF-2's exit ramp: on probe no-go, B-granularity
  supply remains the default and V3a proceeds on it (the fold must not
  couple V3a's fate to C's probe).
- **A11** One line each: caller-protocol fusion scoped in/out with the
  record cite; the generator committed/versioned before fused supply
  becomes the default path; E's 2×48G reconciled with the capped-64G
  default and the [USER 2026-08-26] box-OOM rulings (explicit
  CERB_MEM_MAX plan + box total-memory check, supervised, staggered
  vs other lanes).
